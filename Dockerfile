ARG CUDAVER=12.3.2
ARG PYTHONVER=3.11
FROM nvidia/cuda:${CUDAVER}-base-ubuntu22.04
ENV DEBIAN_FRONTEND noninteractive
ENV CMDARGS --listen

RUN echo "deb https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy main" >> /etc/apt/sources.list && \
	echo "deb-src https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy main" >> /etc/apt/sources.list &&\
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F23C5A6CF475977595C89F51BA6932366A755776 

# we are stuck with python 3.11 due to torch 2.1.0
RUN apt-get update -y && \
	apt-get install -y curl libgl1 libglib2.0-0 git python${PYTHONVER} python${PYTHONVER}-dev python${PYTHONVER}-distutils && \
	apt-get upgrade -y && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*
#symlink to run in the correct version
RUN ln -s /usr/bin/python${PYTHONVER} /usr/bin/python 
# install pip
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
	python get-pip.py && \
	rm get-pip.py
#add user
RUN adduser --disabled-password --uid 1000 --gecos '' user && \
	mkdir -p /content/app /content/data
# Everything below here is pretty much the same as standard, 
WORKDIR /content


RUN git clone https://github.com/lllyasviel/Fooocus /content/app
RUN mv /content/app/models /content/app/models.org

RUN cp /content/app/requirements_docker.txt /content/app/requirements_versions.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements_docker.txt -r /tmp/requirements_versions.txt && \
	rm -f /tmp/requirements_docker.txt /tmp/requirements_versions.txt
RUN pip install --no-cache-dir xformers==0.0.23 --no-dependencies 
RUN curl -fsL -o /usr/local/lib/python${PYTHONVER}/dist-packages/gradio/frpc_linux_amd64_v0.2 https://cdn-media.huggingface.co/frpc-gradio-0.2/frpc_linux_amd64 && \
	chmod +x /usr/local/lib/python${PYTHONVER}/dist-packages/gradio/frpc_linux_amd64_v0.2
	
ENV DATADIR=/content/data  
ENV config_path=/content/data/config.txt
ENV config_example_path=/content/data/config_modification_tutorial.txt
ENV path_checkpoints=/content/data/models/checkpoints/
ENV path_loras=/content/data/models/loras/
ENV path_embeddings=/content/data/models/embeddings/
ENV path_vae_approx=/content/data/models/vae_approx/
ENV path_upscale_models=/content/data/models/upscale_models/
ENV path_inpaint=/content/data/models/inpaint/
ENV path_controlnet=/content/data/models/controlnet/
ENV path_clip_vision=/content/data/models/clip_vision/
ENV path_fooocus_expansion=/content/data/models/prompt_expansion/fooocus_expansion/
ENV path_outputs=/content/app/outputs/

RUN chown -R user:user /content
USER user

RUN cp /content/app/entrypoint.sh /content/
CMD [ "sh", "-c", "/content/entrypoint.sh ${CMDARGS}" ]
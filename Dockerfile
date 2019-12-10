FROM datamachines/cuda_tensorflow_opencv:10.0_1.13.1_4.1.0-20190605

# Install OpenMP
RUN apt-get update \
  && apt-get install -y libomp-dev \
  && apt-get autoremove -y \
  && apt-get autoclean -y

# OPTIONAL: Install CUDNN
# Download your own CUDNN Library here:
# https://developer.nvidia.com/rdp/cudnn-download
# Installation guide here:
# https://docs.nvidia.com/deeplearning/sdk/cudnn-install/index.html
ADD ./libcudnn.deb /
ADD ./libcudnn-dev.deb /

RUN dpkg -i /libcudnn.deb && dpkg -i /libcudnn-dev.deb && rm /libcudnn.deb /libcudnn-dev.deb

# Check the libavcodec installation: it has to be from ffmpeg
#RUN grep "This file is part of" `pkg-config --variable=includedir libavcodec`/libavcodec/avcodec.h
#RUN ffmpeg -version


## Darknet installation

# Optional: download its pre-trained yolo v3 dnn
RUN mkdir -p /darknet && cd /darknet && wget https://pjreddie.com/media/files/yolov3.weights

# Copy the darknet directory
ADD ./darknet /darknet

# (TODO: check this) Link the cuda lib
# RUN cd /darknet && ln -s /usr/lib/x86_64-linux-gnu/libcuda.so.* /usr/local/cuda-9.2/lib64/libcuda.so

# Compile darknet:
# Change the first lines in the ./darknet/Makefile to enable GPU
# and/or other hardware acceleration support
RUN cd /darknet && make
# This link is to enable the python bindings
RUN ln -s /darknet ~/.darknet

# Copy over the bash entrypoints
ADD docker-environment.sh /docker-environment.sh
ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 755 /docker-environment.sh
RUN chmod 755 /docker-entrypoint.sh

# Copy and install the darknet-python module and its dependencies
ADD ./darknet-python /darknet-python
RUN python3 -m pip install setuptools numpy opencv-contrib-python
RUN . /docker-environment.sh && cd /darknet-python && python3 -m pip install .

# Optional: Install moviepy to write images on rtmp (see python example) 
RUN python3 -m pip install moviepy

WORKDIR /darknet
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD [""]

# Labels -- kept at the end to maximize layer reuse when possible
LABEL description="Preconfigured Ubuntu 16.04 with Nvidia CUDA enabled version of TensorFlow and OpenCV3, with darknet and a yolo DNN on the top of it. Also contains python bindings to opencv and darknet"

FROM nvidia/cuda:9.2-devel-ubuntu16.04
# tensorflow-gpu requires nvidia-docker v2 to run
# and is based of nvidia's CUDA 9.0 Docker image running on Ubuntu 16.04
#
# Build using: docker build --tag="cuda_tensorflow_opencv:9.0_1.12.0_4.1.0-0.4" .

ENV OPENCV_VERSION 3.4.6

ENV DEBIAN_FRONTEND noninteractive
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

RUN apt-get update && apt-get install software-properties-common -y\
    && add-apt-repository ppa:jonathonf/ffmpeg-4 -y \
    && apt-get update -y \
    && apt-get install ffmpeg libav-tools x264 x265 -y

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    build-essential \
    clang \
    cmake \
    cuda-cublas-dev-9.0 \
    cuda-cufft-dev-9.0 \
    cuda-npp-dev-9.0 \
    gfortran \
    git \
    imagemagick \
    libatk-adaptor \
    libatlas-base-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavformat-dev \
    libavresample-dev \
    libavutil-dev \
    libboost-all-dev \
    libc6-dev-i386 \
    libcanberra-gtk-module \
    libdc1394-22-dev \
    libfreetype6-dev \
    libgphoto2-dev \
    libgstreamer-plugins-base1.0-dev \
    libgtk-3-dev \
    libgtk2.0-dev \
    libhdf5-serial-dev \
    libjasper-dev \
    libjpeg-dev \
    libjpeg8-dev \
    libpng-dev \
    libpng12-dev \
    libswscale-dev \
    libtbb-dev \
    libtbb2 \
    libtiff-dev \
    libtiff5-dev \
    libv4l-dev \
    libx264-dev \
    libx32gcc-4.8-dev \
    libxvidcore-dev \
    libzmq3-dev \
    pkg-config \
    python-lxml \
    python-numpy \
    python-pil \
    python-pip \
    python-tk \
    python3-dev \
    python3-pip \
    qt4-default \
    software-properties-common \
    unzip \
    vim \
    wget \
    x11-apps

RUN pip3 install --upgrade pip

# Download & build OpenCV
RUN apt-get -qq update \
  && mkdir -p /usr/local/src \
  && cd /usr/local/src \
  && git clone https://github.com/opencv/opencv.git \
  && cd opencv \
  && git checkout $OPENCV_VERSION \
  && cd .. \
  && git clone https://github.com/opencv/opencv_contrib \
  && cd opencv_contrib \
  && git checkout $OPENCV_VERSION \
  && mkdir -p /usr/local/src/opencv/build \
  && cd /usr/local/src/opencv/build \
  && cmake -D CMAKE_INSTALL_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/usr/local/ \
    -D INSTALL_C_EXAMPLES=OFF \
    -D INSTALL_PYTHON_EXAMPLES=OFF \
    -D BUILD_EXAMPLES=OFF \
    -D OPENCV_EXTRA_MODULES_PATH=/usr/local/src/opencv_contrib/modules \
    -D BUILD_DOCS=OFF \
    -D BUILD_TESTS=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D WITH_TBB=ON \
    -D WITH_OPENMP=ON \
    -D WITH_IPP=ON \
    -D WITH_CSTRIPES=ON \
    -D WITH_OPENCL=ON \
    -D WITH_V4L=ON \
    -D WITH_CUDA=ON \
    -D ENABLE_FAST_MATH=1 \
    -D CUDA_FAST_MATH=1 \
    -D WITH_CUBLAS=1 \
    -D FORCE_VTK=ON \
    -D WITH_GDAL=ON \
    -D WITH_XINE=ON \
    -D CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-9.0 \
    -D CUDA_cublas_LIBRARY=cublas \
    -D CUDA_cufft_LIBRARY=cufft \
    -D CUDA_nppim_LIBRARY=nppim \
    -D CUDA_nppidei_LIBRARY=nppidei \
    -D CUDA_nppif_LIBRARY=nppif \
    -D CUDA_nppig_LIBRARY=nppig \
    -D CUDA_nppim_LIBRARY=nppim \
    -D CUDA_nppist_LIBRARY=nppist \
    -D CUDA_nppisu_LIBRARY=nppisu \
    -D CUDA_nppitc_LIBRARY=nppitc \
    -D CUDA_npps_LIBRARY=npps \
    -D CUDA_nppc_LIBRARY=nppc \
    -D CUDA_nppial_LIBRARY=nppial \
    -D CUDA_nppicc_LIBRARY=nppicc \
    -D CUDA_nppicom_LIBRARY=nppicom \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D WITH_WEBP=OFF \
    -D WITH_OPENMP=ON \
    .. \
  && export NUMPROC=$(nproc --all) \
  && make -j$NUMPROC VERBOSE=1 install \
  && rm -rf /usr/local/src/opencv


# Minimize image size 
RUN (apt-get autoremove -y; apt-get autoclean -y)

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
RUN cd /darknet && ln -s /usr/lib/x86_64-linux-gnu/libcuda.so.* /usr/local/cuda-9.2/lib64/libcuda.so

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

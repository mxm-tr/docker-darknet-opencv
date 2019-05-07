FROM datamachines/cuda_tensorflow_opencv:9.0_1.12.0_4.1.0-0.3
# tensorflow-gpu requires nvidia-docker v2 to run
# and is based of nvidia's CUDA 9.0 Docker image running on Ubuntu 16.04
#
# Build using: docker build --tag="cuda_tensorflow_opencv:9.0_1.12.0_4.1.0-0.4" .

ENV OPENCV_VERSION 3.4.6

# Download & build OpenCV
RUN rm -rf /usr/local/src/opencv* \
  && apt-get -qq update \
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

## Darknet installation
# Option 1: Clone it directly
#RUN git clone https://github.com/pjreddie/darknet

# Option 2: Copy the darknet directory
ADD ./darknet /darknet

# OPTIONAL: Compile darknet with GPU support
RUN cd /darknet && sed -i "s/GPU=0/GPU=1/" Makefile

# OPTIONAL: Compile darknet with OpenCV
RUN cd /darknet && sed -i "s/OPENCV=0/OPENCV=1/" Makefile

# Compile darknet
RUN cd /darknet && make

# Optional: download its pre-trained yolo v3 dnn
RUN cd /darknet && wget https://pjreddie.com/media/files/yolov3.weights

ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 755 /docker-entrypoint.sh

WORKDIR /darknet
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD [""]

# Labels -- kept at the end to maximize layer reuse when possible
LABEL description="Preconfigured Ubuntu 16.04 with Nvidia CUDA enabled version of TensorFlow and OpenCV3, with darknet and a yolo DNN on the top of it"

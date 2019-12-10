# Accelerated objects detection on streams and files, using a Docker darknet YOLO container

This repository contains a python script that demonstrates the use of darknet using python bindings, as well as docker configuration files to build and deploy a darknet container with minimal effort.

__Requirements:__

- At least one Nvidia GPU, sorry for the others,
- [Install docker](https://hub.docker.com/search/?type=edition&offering=community)
- [Install Nvdia docker](https://github.com/NVIDIA/nvidia-docker)
- [Install docker-compose](https://github.com/docker/compose)

## Installation

Clone this repository, and the docker image can be built as is.

However it is highly recommended to perform the following steps, as the performance gain of Darknet will be huuuge!

### Use CUDA

This example uses CUDA version 10, make sure you have at least CUDA version 10 installed on your computer or [Install CUDA](https://developer.nvidia.com/cuda-downloads).

Check your CUDA installation and version running:

```shell
nvidia-smi
```

### Use CUDNN

CUDNN cannot be distributed in a docker image, that's why you'd have to get your own. Create a developer account on [developer.nvidia.com](https://developer.nvidia.com), and [download the Debian CUDNN files](https://developer.nvidia.com/rdp/cudnn-download).

Get both the `libcudnn******.deb` and the `libcudnn*-devel******.deb` packages for Debian. Rename them respectively to `libcudnn.deb` and `libcudnn-dev.deb` and place them in the repository's clone directory.

### Configure the darknet's Makefile

Modify the `darknet/Makefile` that will be used to build darknet:

```diff
-GPU=0
-CUDNN=0
-OPENCV=0
-OPENMP=0
+GPU=1
+CUDNN=1
+OPENCV=1
+OPENMP=1
```

- `GPU`: To run the CUDA accelerated version of darknet,
- `CUDNN`: Accelerate using CUDNN, only set to 1 if you have the `libcudnn.deb` and the `libcudnn-dev.deb` files in the clone directory,
- `OPENCV`: The parent docker image contains a version of OpenCV by default,
- `OPENMP`: During the new docker image build, [OpenMP](https://www.openmp.org/) will be installed.

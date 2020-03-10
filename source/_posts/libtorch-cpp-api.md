---
title: libtorch c++ api上手指南
mathjax: true
date: 2020-03-10 06:49:33
categories: 深度学习
tags: pytorch
plink: libtorch_cpp
---

前段时间为了测试，了解过libtorch，里面有些坑，这里简要记一下。

## libtorch包的选择

下载libtorch的地方会有两种包。。看名字完全不知道要怎么选，测了一把，应该是按照下面逻辑去选。后面再来补充原因。

libtorch-cxx11-abi-shared-with-deps-1.3.1.zip -> gcc >= 5.4
libtorch-shared-with-deps-1.3.1.zip  gcc < 5.4

## libtorch的编译方法

pytorch已经给出了对应的教程[https://pytorch.org/cppdocs/installing.html](https://pytorch.org/cppdocs/installing.html)。这脚本很适合写到dockerfile里啊。。

按照教程很顺利的完成了项目搭建和编译，但如果你没有配置过cudnn环境的话大概率会出错。提示什么cudnn没有找到，然后你就搜到这篇文章了。
```
-- Could NOT find CUDNN (missing: CUDNN_LIBRARY_PATH CUDNN_INCLUDE_PATH) 
CMake Warning at /opt/libtorch/share/cmake/Caffe2/public/cuda.cmake:109 (message):
  Caffe2: Cannot find cuDNN library.  Turning the option off
```

解决办法：配置一下cudnn的路径，libtorch不同版本用的名字不一样，索性两个都给他配置一下把。

```
export CUDNN_ROOT=/usr/local/cuda-10.1/cudnn_v7.5
export CUDNN_ROOT_DIR=$CUDNN_ROOT
```

CUDNN_ROOT的路径换成是自己的就可以了。

另外CUDA的环境也要配置好哈，跟nvidia标准的cuda配置方法就行，配置下PATH和LD_LIBRARY_PATH。

```
export PATH=/usr/local/cuda-10.1/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-10.1/lib64:$LD_LIBRARY_PATH
```

删掉build文件夹，再按照官方教程试一下吧。

## libtorch的常用api

to be continue...
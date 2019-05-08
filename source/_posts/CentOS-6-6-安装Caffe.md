title: CentOS 6.6 安装Caffe
date: 2015-10-09 13:02:29
categories: 机器学习
tags: [caffe, Deep learning]
plink: cic
mathjax: true
---
为了能够测试和使用caffe，需要将caffe环境配置到服务器上，之前在自己的ubuntu上安装过caffe，但中间有一些步骤没法通过，最终虽然勉强安装上了，但总感觉有点问题，这次在服务器上安装，又找了一些资料加上上次的经验，最终成功安装上了，特此记录一下，方便其他人安装调试。

服务器上安装有Intel的parallel studio 2015，因此在安装的时候可以不用为mkl担心，不过安装这个也不麻烦，下载一个包自己安装就是了。

主要参考了官方网站的[指南](http://caffe.berkeleyvision.org/install_yum.html).

## 安装依赖

```bash
sudo yum install protobuf-devel leveldb-devel snappy-devel opencv-devel boost-devel hdf5-devel
sudo yum install gflags-devel glog-devel lmdb-devel
```

我在安装的时候，提醒glog没找到，因此手动安装glog

```bash
# glog
wget https://github.com/google/glog/archive/v0.3.3.tar.gz
tar zxvf glog-0.3.3.tar.gz
cd glog-0.3.3
./configure
make && make install
```

由于caffe会依赖opencv，所以还需要安装opencv的库，先安装opencv的依赖：
```
sudo yum install cmake git pkgconfig gtk2 gtk2-devel
```

### opencv的安装
Caffe作者默认你已经配置好了OpenCV环境，文档里没有说这一步。好在有人已经写好了配置OpenCV的[脚本](https://github.com/jayrambhia/Install-OpenCV) ，直接拿来用。或者可以按照官方[教程](http://docs.opencv.org/doc/tutorials/introduction/linux_install/linux_install.html)来进行安装

```
git clone https://github.com/jayrambhia/Install-OpenCV
cd Install-OpenCV/RedHat
sudo ./opencv_latest.sh
```

安装的时候，由于我装的cuda 7.0已经不支持计算能力1.X的版本了，为此opencv中编译时可能会报各种各样的错误，解决办法就是cmake下OpenCVDetectCUDA.cmake 文件，找到set(CUDA_NVCC_FLAGS \${CUDA_NVCC_FLAGS} \${NVCC_FLAGS_EXTRA})，手动改成:

```
set(CUDA_NVCC_FLAGS -gencode;arch=compute_20,code=sm_20;-gencode;arch=compute_20,code=sm_21;-gencode;arch=compute_30,code=sm_30;-gencode;arch=compute_35,code=sm_35;-gencode;arch=compute_30,code=compute_30)
```

至少这样可以编译过了。编译完了make install就可以了。

### cudnn的安装

到cuda[官网](https://developer.nvidia.com/cuDNN)下载cudnn。

解压后将cudnn.h复制到/usr/local/cuda/include/下,将libcudnn.so libcudnn_static.a 复制到/usr/local/cuda/lib64/下

```
ln -s libcudnn.so.6.5.48 libcudnn.so.6.5
ln -s libcudnn.so.6.5 libcudnn.so
```

### protobuf的安装

protobuf是google公司的一个开源项目，主要功能是把某种数据结构的信息以某种格式保存及传递，类似微软的XML，但效率较高。目前提供C++,java和python的API。caffe需要在python中调用protobuf，因此我们需要安装protobuf的python版

```
wget https://github.com/google/protobuf/releases/download/v3.0.0-alpha-2/protobuf-python-3.0.0-alpha-2.tar.gz
./configure
make
make check
sudo make install
```

安装速度比较慢，我下了好久才下下来。完成安装后，还需要去python文件夹内安装python所需要的模块

```
cd python
python setup.py build
python setup.py test
sudo python setup.py install
# 安装完成，验证一下
protoc -version
# 验证python模块是否被正确安装
python
>>>import google.protobuf
```

没有报错说明安装正常。

## caffe安装

在caffe文件夹里，先复制一份Makefile.config  cp Makefile.config.example Makefile.config 修改Makefile.config

> 1 cudnn 注释掉USE_CUDNN:=1
> 2 使用intel 的mkl 来计算blas  修改为：   BLAS：=mkl

接下来就开始进行编译并测试

```
cp Makefile.config.example Makefile.config
# Adjust Makefile.config (for example, if using Anaconda Python)
make all
make test
make runtest
```

但在进行编译时，总是提示boost_thread有问题，因此重新安装boost库,先从[官网](http://www.boost.org/users/history/version_1_57_0.html)下载下来

```
tar zxvf boost_1_57_0.tar.gz
cd boost_1_57_0
./bootstrap.sh
./b2
./b2 install
echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig
```

看到成功提示:

>The Boost C++ Libraries were successfully built!

在caffe目录下make clean后重新编译，即可。

参考：http://blog.csdn.net/lynnandwei/article/details/43232447

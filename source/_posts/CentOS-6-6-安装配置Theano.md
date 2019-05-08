title: CentOS 6.6 安装配置Theano
date: 2015-10-09 13:35:06
categories: 机器学习
tags: [theano, Deep learning]
plink: cit
mathjax: true
---

Theano 安装相对简单，根据[官网](http://deeplearning.net/software/theano/install_centos6.html#install-centos6)的提示，可以先安装上一个简单安装版的theano

## 安装依赖

这个依赖相对比较少，按照提示输入下面的命令：

```
sudo yum install -y python-devel python-nose python-setuptools gcc gcc-gfortran gcc-c++ blas blas-devel lapack lapack-devel atlas atlas-devel
sudo easy_install pip
sudo pip install numpy==1.6.1
sudo pip install scipy==0.10.1
```

但我卡在安装scipy这里过不去，所以就去scipy官网检查如何安装，发现可以直接这样安装：

```
sudo yum install numpy scipy python-matplotlib ipython python-pandas sympy python-nose
```

检查一下numpy和scipy是不是正确安装了：
```
# NumPy (~30s):
python -c "import numpy; numpy.test()"
# SciPy (~1m):
python -c "import scipy; scipy.test()"
```
验证numpy是否真的成功依赖BLAS编译，用以下代码试验：

```
python
>>> import numpy
>>> id(numpy.dot) == id(numpy.core.multiarray.dot)
False
```

结果为False表示成功依赖了BLAS加速，如果是Ture则表示用的是python自己的实现并没有加速。

## 安装Theano
根据官网的教程，可以通过pip来进行简单安装，也可以以developer的身份安装Theano开发代码简单安装使用的pip进行安装，如果具有root权限，可以使用下面的命令来安装：
```
pip install Theano
```
如果没有root权限，也可以将Theano安装在用户目录下(~/.local)
```
pip install Theano --user
```
测试一下新安装的Theano
```
# Theano (~30m):
python -c "import theano; theano.test()"
```
## 更新Theano

只是更新Theano自己的话，使用下面一句命令：

```
sudo pip install --upgrade --no-deps theano
```

如果想更新numpy和scipy的话，使用下面一句命令（如果你是使用yum install安装的Numpy/SciPy的话，使用下面一句后很有可能会导致Theano运行时崩溃,[官网](http://deeplearning.net/software/theano/install.html#bleeding-edge-install-instructions)有详细解释）：

```
sudo pip install --upgrade theano
```

## 安装Theano开发版本
Theano 安装版本需要先把源码下下来,然后运行setup.py进行安装

```
git clone git://github.com/Theano/Theano.git
cd Theano
python setup.py develop
# without root use below
# python setup.py develop --prefix=~/.local
```
## Theano 配置

详细的配置内容参见[官网](http://deeplearning.net/software/theano/library/config.html#envvar-THEANO_FLAGS)。配置文件的位置，默认是在~/.theanorc 可以修改该文件来配置THEANO_FLAGS
一个示例文件内容如下：
```
[global]
floatX = float32
device = gpu0

[nvcc]
fastmath = True
```

执行下面一句命令来查看当前的配置信息:
```
python -c 'import theano; print theano.config' | less
```
至此Theano配置完成。

相对来说，caffe的速度和效率还是要比theano高的，毕竟theano用的是python，而caffe主要是c++写的，所以如果追求速度和效率还是用caffe比较实际。但python处理数据很方便，而且theano很好安装，如果只是验证或者简单使用，也可以使用theano。

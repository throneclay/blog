title: Fedora23手动安装使用cuda7.5
date: 2015-12-15 14:05:38
categories: 学习笔记
tags: [Linux, CUDA]
plink: fedora-cuda-install
mathjax: true
---

重装完系统，要搭起工作环境，这里记录下搭建CUDA的方法，免得每次还要再去找需要什么依赖，或者配的一些文件。Fedora安装cuda的方法很多，easy的方法直接dnf安装，但我还是比较喜欢用run安装的方法，这样知道自己都做了什么，这里就说一下使用run文件安装cuda的方法。我使用的fedora23安装的cuda7.5 目前使用正常，还没有发现大的问题。

## 安装Nvidia驱动，下载cuda
安装驱动可以参考这篇文章，写的太好，完全不需要再补充什么了，根据自己的情况进行安装：
http://www.if-not-true-then-false.com/2015/fedora-nvidia-guide/

下载cuda的地址，目前最新版就是7.5：
https://developer.nvidia.com/cuda-downloads

## 安装依赖
如果仅仅为了安装cuda，那么其实只要有gcc和g++就没什么问题了。

```
sudo dnf install gcc gcc-c++
```

但fedora23上使用的时gcc 5.1版本，而cuda一般使用的gcc版本都比较低，我也一直很不理解，为什么非要使用那么低的gcc版本。不过使用高版本的gcc我们也是可以安装成功的。

如果为了能够编译cuda sdk，你还需要这么几个依赖
```
sudo dnf install glut-devel libGLU-devel libX11-devel libXi-devel libXmu-devel mpich2
```
安装完这些依赖后，后面就好编译cuda的sdk了。

## 安装cuda
由于我们使用的是高版本gcc，这里直接运行cuda的run文件是有问题的。但Nvidia的run文件功能很完善，可以使用传参数的方式安装cuda。通过这种方式，我们可以使用override方法让他不检查gcc版本。这里我把下下来的run文件改名为cuda.run
```
sudo chmod a+x cuda.run
sudo ./cuda.run --silent --override --toolkit --samples
```
这里由于我们已经安装过driver，就不再安装cuda自带的driver，一般他带的driver是通用driver，版本也比较老，性能不如自己直接装的驱动，silent参数指的安装过程能不提醒用户的就不提醒，默认各种需要yes或者agree的都帮你填了，override就是忽视gcc版本，toolkit是必须要装的，samples是我们提到的Nvidia cuda sdk，提供了各种各样的cuda使用官方例子，基本涵盖了cuda的重要功能和特性，也方便我们测试cuda是否成功安装。其实cuda.run的参数有很多，感兴趣的可以传入help查看一下他的参数列表。
## 配置环境变量
安装完成后，需要配置一下环境变量，针对单个用户来说，可以编辑个人home下的.bashrc文件来配置，如果想配置成所有用户都能够使用的方式，就配置/etc/profile文件，这里我们选择第一种方式。编辑home下的.bashrc文件，在最后添加下面两句话
```
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```
重新打开一个终端，输入nvcc，这时候可以看到已经能使用nvcc了
## 编译cuda sdk
测试一下我们的cuda是否真的安装完成了，我们把/usr/local/samples文件夹复制一份到自己的home下，不要用sudo复制，直接复制出来就可以。这个文件夹内的内容就是sdk了。这个文件夹内有makefile文件，所以可以直接make。
但这时候如果直接make是会有错误的，提示你gcc版本过高（又是这个问题）。。。我们可以看到他报错的文件，那我们就修改一下这个文件让他不要报错了。打开/usr/local/cuda/include/host_config.h文件，找到4.9的限制这一行（应该时113行）把所有的4改成5,就变成了最高限制gcc版本为5.9了
这样我们再次make发现过了一段时间，报一个找不到-lGl的错误。这个错误应该时目前Fedora23发现的稍有的bug了。问题就是/usr/lib64下的libGL.so文件链接错了文件，导致找不到对应版本的库，解决方法：
```
cd /usr/lib64
sudo rm libGL.so
sudo ln -s libGL.so.1 libGL.so
```
这样重新试试，是不是全都make过了呢？nvcc的编译速度很慢，我们可以使用make -j4来加快make的速度， -j4表示最多有4个进程在make，我的电脑是4核的，所以使用-j4,如果你有8核的，那完全可以使用-j8，当然如果你直接make -j也是可以的，这个时候他会能开多少个进程就给你开多少个进程，CPU确实全占满了，但速度并不一定是最快的。

运行一下sdk下的1_Utilities/deviceQuery示例，这个示例能够输出当前GPU的一些基本信息，看看CUDA是否已经成功安装完成了？

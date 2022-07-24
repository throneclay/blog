title: vagrant搭建自己的虚拟开发环境
date: 2016-03-19 21:18:50
categories: 学习笔记
tags: vagrant
plink: vag
mathjax: true
---
vagrant其实是一个虚拟环境，他是我们平时使用的Virtualbox等虚拟机的一层封装，最为方便的地方是可以通过配置文件快速搭建一致的虚拟开发环境，非常利于开发人员进行测试和同步开发，避免了环境不同带来的问题。这里我使用的Fedora的cloud版进行的测试开发，使用其他的其实就是换一下box文件，过程是一样的。

## 安装Virtualbox
由于[这篇博客](http://www.if-not-true-then-false.com/2010/install-virtualbox-with-yum-on-fedora-centos-red-hat-rhel/)写的太好了，这里就不再复述了。

## 搭建vagrant

安装最新版的vagrant要到[官网](https://www.vagrantup.com/downloads.html)上去下载：
我这里是用的fedora，所以就下载centos 64位的版本了，其他的可以根据自己的系统进行选择。
安装完直接使用rpm进行安装,假设下下来的安装包是vagrant.rpm
```
sudo rpm -ivh vagrant.rpm
```
安装完成后，可以输入vagrant测试一下看看安装成功了没有。

## 下载box文件
由于我这里使用的是本地的box文件，因此需要先下载box文件，这里的box文件其实就是虚拟机的镜像，vagrant支持本地的box和网络的box，也就是说你其实可以设置box文件的网络地址，让vagrant自己去找镜像。我下的fedora 23 cloud版的vagrant镜像，用的virtualbox，用了ustc的源，这里给个链接[fedora23Cloud](http://mirrors.ustc.edu.cn/fedora/linux/releases/23/Cloud/x86_64/Images/Fedora-Cloud-Base-Vagrant-23-20151030.x86_64.vagrant-virtualbox.box)。

## vagrant工作环境
vagrant的命令其实挺简单的，平时常用的就是几条。
初始化，启动虚拟机，ssh登录虚拟机，关闭虚拟机。
### 初始化
初始化做的事情是生成配置文件，配置文件对于vagrant非常重要，里面记录了vagrant的绝大部分配置，详细介绍在下一节，这里只提会用到的。假如我们已经下载了fedora的box文件(/path/fedora.box)进入工作文件夹后初始化：
```
cd ~/workspace/vagrant_workspace/
vagrant init /path/fedora.box
```
这时候会生成**Vagrantfile**文件，这就是我们的配置文件了。
### 启动虚拟机
启动的命令如下：
```
vagrant up
```
此时会按照你的Vagrantfile文件的记录进行配置和启动，第一次启动的时候会进行安装，并在virtualbox里面登记虚拟机。

默认的网络配置只有内网连接，如果你想让你的虚拟机能够被其他的电脑访问到，你需要配置一下配置文件的网络配置，去掉下面一句话的#注释。
```
# config.vm.network "public_network"
```
下面的命令能够让你的虚拟机重新加载配置文件，作用就相当于虚拟机重启，每次启动的时候配置文件都会被读入并进行配置。
```
vagrant reload
```
### ssh登录
vagrant 自己配置了密钥等信息，可以直接通过下面的命令登录
```
vagrant ssh
```
登录后你会发现你的项目目录和虚拟机里的/vagrant文件目录是同步的，可以比较方便的传输数据。
### 关闭和销毁虚拟机
```
vagrant halt
```
上面的这句命令就是关机了。
如果你想销毁虚拟机使用下面这句话
```
vagrant destroy
```

## 配置文件详解
其实最详细的介绍在官网，这里只是就几个比较常用的设置介绍一下。
### box 设置
```
config.vm.box = "base"
```
这里是指的我们指定的box名，vagrant init box时指定的box，如果没有，默认就是base。这里也可以是url给出的box，当vagrant up时就会按照地址去下载对应的box
### 网络设置
```
config.vm.network "public_network"
```

### sync-folder
这个选项默认要求你安装vagrant-vbguest。设置前首先安装插件：

```
vagrant plugin install vagrant-vbguest
```
然后设置sync-folder变量到你想共享的文件夹。

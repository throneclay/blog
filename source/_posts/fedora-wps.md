title: Fedora23上安装wps
date: 2016-06-07 17:07:14
categories: 学习笔记
tags: Linux
plink: fedorawps
mathjax: true
---

最近在fedora 23上装了wps，在这里记录以下过程。

wps官网上2016年6月2日把所有旧的wps linux版本撤掉了，所以下载成了第一个问题，在网上找到了下面的安装包，fedora 23亲测可用。在命令行下直接输入下面命令就可以下载了。
```
wget ftp://rpmfind.net/linux/sourceforge/l/li/linkstoos/Offices/KingsoftOfficeFree/kingsoft-office-9.1.0.4096-0.1.a11p1.i686.rpm
```

当然安装前有一些依赖需要安装，用dnf下载下面的依赖。
```
sudo dnf install libICE.so.6 libSM.so.6 libX11.so.6 libXrender.so.1 libc.so.6 libdl.so.2 libfontconfig.so.1 libfreetype.so.6  libXext.so.6 libgcc_s.so.1 libglib-2.0.so.0 libgobject-2.0.so.0 libstdc++.so.6 libz.so.1 libcups.so.2 libpng12.so.0 libGLU.so.1
```

由于fedora23预安装了libmng2，libmng1没有fedora23的对应版本，所以我从网上找了一个安装包，测试安装发现fedora23可用，目前还没有什么bug，下面的命令下载安装包。
```
wget ftp://195.220.108.108/linux/centos/5.11/os/x86_64/CentOS/libmng-1.0.9-5.1.i386.rpm
```

这时候用dnf下载libmng1的依赖包，不下载依赖包直接安装会报错误。

```
sudo dnf install libjpeg.so.62 liblcms.so.1
```

这时候就可以安装了，输入下面的命令使用rpm进行安装。

```
sudo rpm -ivh libmng-1.0.9-5.1.i386.rpm
```

如果你也是用fedora23，很可能会报出下面的错误，原因就是已经预装libmng2了。
```
package libmng-2.0.3-2.fc23.x86_64 (which is newer than libmng-1.0.9-5.1.i386) is already installed
```

我们不需要卸载libmng2.0。直接加一个选项--force强制安装即可。
```
sudo rpm -ivh libmng-1.0.9-5.1.i386.rpm --force
```

接下来安装我们下下来的wps安装包，是不是就直接安装成功了。
```
 sudo rpm -ivh kingsoft-office-9.1.0.4096-0.1.a11p1.i686.rpm
```

安装完就可以使用了，但会报字体警告，可以从下面的地址下载所需要的字体。
```
http://download.csdn.net/download/wl1524520/6333049
```

下载完后把压缩包里的文件解压缩，fedora23可以按照下面的命令完成字体的安装。
```
sudo mkdir /usr/share/fonts/wps
sudo cp *ttf /usr/share/fonts/wps/
fc-cache
```

reference:
```
http://www.cnblogs.com/itmaple/p/4456348.html
```

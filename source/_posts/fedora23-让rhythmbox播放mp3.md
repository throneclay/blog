title: fedora23 让rhythmbox播放mp3
date: 2016-01-05 22:09:16
categories: 学习笔记
tags: Linux
plink: rhythmbox
mathjax: true
---

fedora 23安装完后默认的thythmbox并不能直接播放我们熟悉的mp3格式的音频文件。需要安装额外的依赖，但我们官方库里这些依赖并不全，所以我们需要安装额外的rpm第三方软件源RPMFusion，我由于是教育网，就使用了中科大的源，中科大的源就算不是教育网应该也是很快的吧。。我想是的。

首先安装RPMFusion的软件源，使用方法，对于fedora23来说，直接执行下面一句命令：
```
su -c 'yum localinstall --nogpgcheck http://mirrors.ustc.edu.cn/fedora/rpmfusion/free/fedora/rpmfusion-free-release-stable.noarch.rpm http://mirrors.ustc.edu.cn/fedora/rpmfusion/nonfree/fedora/rpmfusion-nonfree-release-stable.noarch.rpm'
```
其他的fedora版本安装方法参见中科大源的[使用帮助](https://lug.ustc.edu.cn/wiki/mirrors/help/fedora)

安装完成后运行makecache就可以了
```
sudo dnf makecache
```

安装完成后就开始安装需要的依赖

**如果你是GNOME用户** 执行下面一句来安装gstreamer。
```
sudo dnf install gstreamer1-libav gstreamer1-plugins-good gstreamer1-plugins-ugly gstreamer1-plugins-bad-free gstreamer-ffmpeg gstreamer-plugins-good gstreamer-plugins-ugly gstreamer-plugins-bad gstreamer-plugins-bad-free gstreamer-plugins-bad-nonfree
```

**对于KDE用户** 建议使用xin代替gstreamer
```
sudo dnf install xine-lib* k3b-extras-freeworld
```

**如果想使用rhythmbox来通过网络收听radio，继续安装这些包**
```
sudo dnf install gstreamer1-plugins-good gstreamer1-plugins-ugly gstreamer1-plugins-bad-free gstreamer1-plugins-bad-free-extras gstreamer1-plugins-bad-freeworld gstreamer-plugin-crystalhd gstreamer-ffmpeg gstreamer-plugins-good gstreamer-plugins-ugly gstreamer-plugins-bad gstreamer-plugins-bad-extras gstreamer-plugins-bad-free gstreamer-plugins-bad-free-extras gstreamer-plugins-bad-nonfree gstreamer-plugins-bad-extras libmpg123 lame-libs
```

看到这里你应该已经安装完了吧。。额，其实如果你不想安装这么多依赖，这里再推荐两个非常好用的音频视频播放器。很类似potplayer这类全能播放器，第一个就是我经常用的smplayer，第二个是网上推荐的比较多的vlc，想要安装他们也必须先把RPMFusion配置上，配置完后执行下面代码。
```
# 如果你想安装smplayer，执行下面这句
sudo dnf install smplayer

# 如果你想安装vlc，执行下面这句
sudo dnf install vlc
```
smplayer的界面我个人感觉比较好看，使用的是一个强大的解码器mplayer。对于vlc，由于我用vlc有那么一段时间各种崩溃，所以让我对vlc有些失望，但国外推荐vlc的比较多，所以看个人情况了，或者干脆把他们都装上，谁解的好用谁。

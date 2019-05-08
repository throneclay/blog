title: 树莓派的娱乐中心retropie+kodi
date: 2016-11-01 22:11:40
categories: 嵌入式
tags: raspberryPi
plink: rpitime
mathjax: true
---
发现了树莓派上新的好玩的东西，retropie！手头也有树莓派3，试了试真的很不错！PSP的某些游戏都可以玩。Retropie是个游戏模拟器的大集合，带有好多游戏模拟器，同时支持各种扩展，包括minecraft服务器，KODI等等，可以直接使用手柄玩，安装也很简单。下面就记录下安装过程。

Retropie的官网在这里：[https://retropie.org.uk/](https://retropie.org.uk/)

##  安装Retropie

官网上其实提供了两种安装模式，这里使用的是下载镜像然后直接安装，如果已经在树莓派上装了Respbian系统，也可以直接clone他的git repo进行安装，这里不再介绍这种方法。

首先，下载Retropie镜像，根据自己树莓派的型号下载对应镜像。[https://retropie.org.uk/download/](https://retropie.org.uk/download/) 下载完就可以烧tf卡了。

由于换了Macbook，使用的是dd烧的系统，这里说一个小的技巧，这个能在Mac上对dd提速10倍以上：
在mac系统上插上卡会出现在/dev/diskN,(N是一个数字，很可能是1)，树莓派的官网建议我们用下面的命令烧:
```
sudo dd bs=4m if=respbian.img of=/dev/disk1
```
但你会发现写入的特别特别慢，速度大概在400KB左右。。但你换下面一句话，速度瞬间提升:
```
sudo dd bs=4m if=respbian.img of=/dev/rdisk1
```
原因是对rdisk来说，mac对烧写的内容没有任何处理（本来就应该这样吧）恢复正常速度！！
其他系统这里就不多说了，玩树莓派的对烧系统应该是非常熟悉了。

烧好系统后，接上显示器开机。这里有没有手柄都是可以的，如果有最好，没有的话用键盘也可以，只是映射按键需要自己好好记一下。一开机就是让你配置手柄的按键，配好A,B,X,Y还有方向键，start和select后就可以了，剩下的可以以后再配置，跳过配置按你设置的A键。如果你有wifi就脸上，在retropie的设置界面里有。注意，刚开机你是没有任何游戏的（因为随便给你ROMs可能涉及侵权等）联网的好处就是可以装一些插件，传roms比较方便，没有wifi用有线也是可以的。只要你能ssh上，roms照样可以传上去。熟悉下界面差不多可以了，下面就开始最重要的roms的安装！

参考：
[https://github.com/RetroPie/RetroPie-Setup/wiki/First-Installation](https://github.com/RetroPie/RetroPie-Setup/wiki/First-Installation)

## Roms

Roms的文件目录在/home/pi／retropie/roms下，可以看到各种个样的模拟器都有，只要你的roms放在正确的模拟器下，重启后你的界面就会加上你安装的游戏，问题是roms去哪找？
这里给个google的网站，其他的我也正在找：
[https://sites.google.com/site/classicgameroms/](https://sites.google.com/site/classicgameroms/)
这个网站的优点是很全，缺点是需要翻墙。。

## KDMI及其插件

其实Retropie吸引我的不光是他的游戏模拟器，还有他能安装KDMI，

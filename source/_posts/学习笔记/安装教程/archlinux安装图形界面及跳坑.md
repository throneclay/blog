title: archlinux安装图形界面及跳坑
mathjax: true
date: 2017-01-28 21:20:10
categories: 学习笔记
tags: archlinux
plink: archgui
---

前面装完archlinux后只是一个非常基础的命令行界面，没有图形界面，对于现自己用的个人电脑，当然还是要有个漂亮的图形界面的了。其实archlinux的官方wiki写的非常清楚，而且文档等等也很完善，这里就是简单的记录下自己的安装过程，方便自己以后回顾。文章按照几种常用的linux图形界面分类，可以根据自己喜好安装，完全不用全都安装上。

## 安装图形界面前

我特别喜欢的是Linux的自动补全，但用上archlinux后总觉得自动补全变得功能特别弱，直到我安装了bash-completion后，自动补全功能又回来了，强烈建议你开始安装前，先把自动补全装上
```
sudo pacman -S bash-completion
```

### 添加用户
首先还是添加用户，添加用户前先该一下权限控制文件，root下使用visudo命令找到# %wheel ALL=(ALL) ALL这句话并去掉前面的注释，保存即可，这样在wheel用户组下的用户就拥有了sudo的权限。接着添加用户，使用-m添加用户目录，并加入wheel组，改下密码就可以了。
```
# useradd -m [UserName] -Gwheel
# passwd [UserName]
```
### 网络

这里说的是在命令行下，实际上当你安装好图形界面后，就会使用NetworkManager来管理网络，所以这里只是介绍下临时方案。

1. 有线的动态IP：直接使用dhcpcd命令
```
# dhcpcd
```
2. 有线的固定IP：使用iproute2包里的ip命令
```
# ip link set [interface] up
# ip addr add [IP_address/subnet_mask] broadcast [broadcast_address] dev [interface]
# ip route add default via [router_ip]
```
3. 无线连接：可以使用iproute2包里的iw命令，主要的命令这里列一下，详细查看[wiki](https://wiki.archlinux.org/index.php/Wireless_network_configuration_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))
```
# iw dev [wlan0] link //查看状态
# iw dev [wlan0] scan //扫描网络
# iw dev [wlan0] connect [essid] //连接网络
```

### 区域和语言

这个地方我一开始一直觉得没什么用，后来发现影响实在太大了。最后出现的各种问题全都是因为这里没有设置好。所以还是建议这里好好配置，省得以后出现问题。

先编辑/etc/locale.gen文件，把下面的几项解开注释
```
en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
```
完成后用root权限运行下面一句
```
# locale-gen
```
接着创建本地化文件选项
```
# echo LANG='en_US.UTF-8' > /etc/locale.conf
```
下次重启就可以了，可以的标准是运行locale后输出不是C而是en_US.UTF-8就像下面一样。
```
$ locale
LANG=en_US.UTF-8
LC_CTYPE="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
LC_ALL=

```
### 字体

针对中文，这里装下这些字体就可以了

```
sudo pacman -S wqy-microhei wqy-zenhei ttf-arphic-ukai ttf-arphic-uming adobe-source-han-sans-cn-fonts adobe-source-code-pro-fonts
```

### 图形环境

装一下图形环境，gnome会自动装，但kde不会自动装，所以这里还是手动装好比较好。

先装显卡驱动，这里我是intel的核显，直接装xf86-video-intel，如果你是amd的显卡，可以装开源项目xf86-video-ati，如果是nvidia的话，不想多说什么，你可以选择装闭源驱动，或者开源xf86-video-nouveau(这里装了bash-completion的有福了,直接输入xf86-video加tab,你就可以看到所有支持的各个驱动版本)

装完驱动后装上图形xorg包组
```
# pacman -S xf86-video-intel
# pacman -S xorg-server xorg-xinit xorg-utils xorg-server-utils
```
### archlinuxcn和AUR

装archlinux的绝大部分是冲着AUR来的吧,这里说一下国内比较好的AUR配置方法.

添加下archlinuxcn源,还是只推荐中科大源,编辑/etc/pacman.conf文件,在最后加上下面的几句话
```
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
```
保存后更新下,顺便把archlinuxcn-keyring装上
```
# pacman -Syu
# pacman -S archlinuxcn-keyring
```
做完后装上yaourt,测试下archlinuxcn是否装好了.yaourt是对pacman的封装,能够自动从AUR上下载脚本,完成全部的编译等等操作,自动安装依赖,非常好用的AUR脚本.
```
# pacman -S yaourt
```
好了,想想你想装什么吧.举个例子:google-chrome
```
$ yaoaurt -S google-chrome
```

## KDE 5
要装肯定装最新的,KDE5的安装同之前的不太一样,这里可以直接装plasma来代替KDE的安装,最小化安装看这里:
```
sudo pacman -S plasma-desktop
```
或者装plasma-meta,相对来说东西多一点.接下来要装sddm,因为plasma只是个桌面,sddm能够很好的托管包括kde在内的多种dm.
```
sudo pacman -S sddm
sudo systemctl enable sddm
sudo systemctl start sddm
```

没意外的话,图形界面就有了,这里说几个常用软件
```
sudo pcamn -S konsole // 终端
sudo pacman -S ark    //  打包软件
sudo pacman -S dolphin // 资源管理器
sudo pacman -S okular //pdf 阅读器
```
### 安装fcitx输入法

如果前面都做好了的话,还是很容易的,需要装的东西有fcitx,fcitx-libpinyin(这是拼音库,不装不行),fcitx-configtool(配置工具),fcitx-googlepinyin(好多,以google拼音为例),fcitx-im(多软件包,包含qt5,qt4,gtk2,gtk3)

```
sudo pacman -S fcitx fcitx-libpinyin fcitx-configtool fcitx-googlepinyin fcitx-im
```
装完输入fcitx启动,配置下输入法,然后注销就可以了.

### 蓝牙耳机

我的蓝牙耳机是索尼MDR-1000X,这里是他完整的配置过程,首先安装依赖,安装完后使能蓝牙服务
```
# pacman -S pulseaudio-alsa pulseaudio-bluetooth bluez bluez-libs bluez-utils bluez-firmware
# systemctl enable bluetooth
# systemctl start bluetooth
```
如果直接开始扫描,你是添加不上MDR-1000X的,这里需要修改下pulseaudio的配置文件,编辑/etc/pulse/default.pa文件,找到下面一句话,注释掉上下两句,变成这样
```
#.ifexists module-bluetooth-discover.so
load-module module-bluetooth-discover
#.endif
```
最后再加上这样一句,让他在connect后能够自动切换
```
load-module module-switch-on-connect
```
好了,现在开始配对,使用bluetoothctl工具
```
# bluetoothctl
# power on
# agent on
# default-agent
# scan on
```
扫描到你的耳机后,先pair,再connect
```
[NEW] Device 10:4F:A8:E1:BE:2E MDR-1000X
# pair 10:4F:A8:E1:BE:2E
# conncet 10:4F:A8:E1:BE:2E
```
没意外的话,你已经连接上蓝牙耳机了,接下来比较恶心,连上后没有声音,问题出在Profile上,MDR-1000X的Profile如果选错,要么声音巨难听,感觉像变成20块钱的地摊货,要么就完全没有声音.

解决方法是右键点右下角的小喇叭,点Audio Volume->Configuration,我这里是选的Built-in-Audio为Analog Stereo Output,MDR-1000X为A2DP Sink.如果还没有声,把前面的选项卡找找,什么地方的输出没走MDR-1000X就给他改过来.


### KDE 5 跳坑
1. **中文显示都是问号,框框?**

问号出现的原因是你的区域和语言没设置好,在终端下输入命令locale,看看是不是都是en_US.UTF-8,不是的话查看上面的 **区域和语言** 一节. 框框出现的原因是没有中文字体,没有的话查看上面 **字体** 一节.

2. **装完plasma后怎么联网**

要么你没装NetworkManager,要么没启动NetworkManager,安装:
```
# pacman -S networkmanager
```
启动:
```
# systemctl enable NetworkManager
# systemctl start NetworkManager
```

## GNOME

GNOME用的少点,但也用过,优点就是安装简单
```
# pacman -S gnome
```
如果你之前装了sddm,那注销就能看到gnome的入口,否则需要启动gdm
```
# systemctl enable gdm
# systemctl start gdm
```
### GNOME跳坑

1. **Gnome下Terminal不工作?**

GNOME最大的坑,原因还是你没有配置好区域和语言,你可以参照上面的 **区域和语言** 一节

2. **装完gnome后怎么联网**

gnome默认自动安装NetworkManager,这里应该是没启动NetworkManager,以防万一,安装:
```
# pacman -S networkmanager
```
启动:
```
# systemctl enable NetworkManager
# systemctl start NetworkManager
```

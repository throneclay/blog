title: 树莓派搭建自己的数据中心NAS
date: 2015-10-28 16:01:47
categories: 嵌入式
tags: raspberryPi
plink: rpinas
mathjax: true
---

入手了二代树莓派，速度确实比一代好了很多，尤其是在CPU上性能大幅提升，一代树莓派的硬盘IO性能很不好，主要原因是CPU比较弱了，而第二代树莓派CPU性能终于提上来了，但USB还保持在2.0，所以IO还是不是很好，不过考虑到二代树莓派的网口还是100M的，就算换了USB3.0，通过网络传数据还是10MB/s，意义也不是很大了，就先这样用这吧。一代产品由于性能较弱，所以有点像一个玩具服务器，二代产品开始能当作小服务器来用了，这点还是挺不错的。

## 树莓派安全篇

很少看到有介绍树莓派安全问题的文章，但这个对于我来说确是不得不做的事情，我所在的学校很大方的提供给我们免费的固定外网IP，在这个ipv4地址匮乏的时代，能如此大方的人手一个外网固定ip，真是不容易啊。但随之而来的是很恐怖的安全问题。外网IP真的很危险诶。。曾经看到，如果你的root密码是6位数字，并且打开了ssh server，端口是默认的22
号，在公网ip几分钟内就会变成别人的肉鸡。我们跟我同ip段的有很多还是学校各部门或者各实验室服务器，时不时的就会出现主页被修改，还发生过国家安全部门直接过来查服务器（服务器上挂了危害国家安全的程序）。。。作为树莓派，肯定会长期开机，而且一定会开ssh服务，这么危险的网络，就算密码再安全，直接暴露出来也是非常危险的。所以这里做了一些安全工作，如果你的树莓派挂在自己的路由器内，大可不必这么麻烦，注意不要设太简单的密码应该就可以了。

### tmpfs

由于树莓派读写的是tf卡，速度慢不说，反复读写还会对tf卡造成损伤，因此我们使用tmpfs文件系统来挂载一些需要反复读写，但又没太多重要作用的位置。通过使用fstab文件来实现开机自动挂载。我们把/tmp, /var/tmp, /var/run文件夹挂载到tmpfs上，fstab里面添加如下内容：
```
tmpfs /tmp tmpfs defaults,noatime,nosuid,size=100m 0 0
tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=30m 0 0
tmpfs /var/run tmpfs defaults,noatime,nosuid,mode=0755,size=2m 0 0
```
重启后看一下df信息，确认以及挂载成功。

### denyhosts

我最开始的策略是使用ssh防扫描软件，denyhosts就是这样一个针对ssh服务器的基于日志的入侵预防安全工具，使用Python编写。其实linux本身就可以记录一些ssh的日志信息，包括登陆者的ip，登陆成功或者失败的信息，denyhosts就是利用linux生成的日志信息，屏蔽一些貌似在试密码的登陆者的IP。缺点就是对ipv6的地址不能很好的起效。

安装很简单，使用apt-get就可以直接安装
```
sudo apt-get install denyhosts -y
```
安装完成后可以对他进行配置，配置文件是/etc/denyhosts.conf其实我们用他的默认配置也是可以的，里面的配置主要是ssh登陆失败多少次后将这个ip屏蔽，denyhosts有他的黑名单和白名单，分别在/etc/hosts.deny和/etc/hosts.allow，可以将自己的一些设备加到/etc/hosts.allow里面，书写的格式在文件里面有解释，这里就不多说了。

使用denyhosts一段时间，就可以看到hosts.deny里面的记录迅速在增长，我的记录中，有时候一天就会多添加几十条记录。。这就又带来了一个新的问题，树莓派本身CPU资源就很紧张，整天被人这么扫，感觉还是很不爽的。其实还有另一种更简单更有效的方法来避免被人扫，修改ssh端口。ssh端口的记录在/etc/ssh/sshd_config文件中，直接修改就可以了。虽然很简单，但确实很有效，修改端口后，denyhosts的记录就停止增长了，说明那些漫无目的扫描器不会检查其他的端口。但这种方式对付那种就是想搞你这个ip的黑客是无效的，他们会扫描你所有的端口。。但至少这种方法配合denyhosts亲测还是很管用的local。

接下来就是正式的NAS服务器搭建了。

## 挂载硬盘
为了能使树莓派挂载硬盘，我买了那种sata3转usb的转接盒，同时为了解决树莓派usb供电不足的问题，我又购置了有源usb集线器。。诶，总之硬件确实需要这些东西的辅助才行。都连接好了后，看一下/dev下是不是有sdX设备了，我这里是sda。这里推荐将硬盘重新格式化为ext4格式的文件系统。

**格式化硬盘为ext4**
```
# 查看硬盘内核名称，/dev/sda一般是你的硬盘
sudo fdisk -l
# 按照提示对硬盘进行分区
sudo fdisk /dev/sda
# 将硬盘分区格式化为ext4格式，格式化前必须先卸载硬盘，使用umount命令
sudo mkfs.ext4 /dev/sda1
```

**挂载硬盘**

ext4格式的硬盘的权限指定很方便，可以直接修改挂载的文件夹就可以了，举个例子
```
mkdir /home/pi/media
sudo mount /dev/sda1 /home/pi/media
sudo chown pi:pi /home/pi/media
```
这样下次挂载的时候也是同样的权限设置

**开机自启动**

开机自启动也是修改/etc/fstab文件,编辑/etc/fstab文件，加入如下内容
```
/dev/sda1 /home/pi/media	ext4	defaults	0	0
```
这里也可以使用硬盘的uuid来进行挂载,万一他不再是sda了也可以同样识别到,查看方法如下
```
sudo blkid
/dev/sda1: UUID="d5a3d30a-d2e7-4b12-bb31-b4439c5db200" TYPE="ext4"
```
这样添加fstab的时候可以这样添加
```
UUID=d5a3d30a-d2e7-4b12-bb31-b4439c5db200       /home/pi/nas-data   ext4    defaults    0       2
```

**补充一下fstab文件**

这里为了能够每次开机自动挂载，使用了/etc/fstab这个文件，文件的内容示例和说明如下：

```
/dev/sda1 /media/disk (format:auto, ntfs-3g, vfat, ext4,...) defaults,noexec,umask=0000 0 0
# sda1是取决于你的实际情况，a表示第一个硬盘，1表示第一个分区。
# /media/disk是挂载的位置
# format 是挂载文件的格式,格式有很多，可以看一下手册。
# 前面四个0就是对所有人,可读可写可执行,后面两个0,第一个代表dump,0是不备份，第二个代表fsck检查的顺序,0表示不检查
```

fstab这个文件确实功能非常强大，不仅能挂载本地分区，还可以挂载远程的文件系统。详情看[我的博客](http://blog.throneshuai.info/2016/01/08/fstab/)，这里就不再细说了。

**其他的文件系统格式**

并不推荐其他的文件系统，因为linux需要模拟实现对他们的读取，性能会受到影响，而且可能某些使用上也会受到影响，但为了完整性，这里还是一并说一下如何使用。

* **NTFS格式:**:默认挂载NTFS格式的硬盘只有只读权限，需要借助其他工具实现。
```
# 安装所需软件包
sudo apt-get install fuse-utils ntfs-3g
# 加载内核模块
modprobe fuse
# 编辑fstab让硬盘开机自动挂载
sudo nano /etc/fstab
# 在最后一行添加如下内容 挂载到/media/disk文件夹
/dev/sda1 /media/disk ntfs-3g defaults,noexec,umask=0000 0 2
# 保存重启，即可生效
```
* **FAT32格式**:FAT32格式可以直接挂载。
```
sudo nano /etc/fstab
# 在最后一行添加如下内容
/dev/sda1 /mnt/myusbdrive auto defaults,noexec,umask=0000 0 0
# 保存重启，即可生效
```
* **exFAT格式**:exFAT格式需要安装exfat-fuse做驱动，安装后就可以挂载了。
```
sudo apt-get install exfat-fuse
# 编辑fstab让硬盘自动挂载
sudo nano /etc/fstab
# 在最后一样添加如下内容
/dev/sda1 /mnt/usbdisk vfat rw,defaults 0 0
```
## sftp-server

这是最简单的服务器了，其实就是我们的ssh带的功能，在Linux上我们使用的scp命令以及我们在windows下使用的winscp软件都是利用了这个服务器。他是如此简单，以至于你把ssh功能打开后就可以直接使用了。那为什么这里还要提这个简单的功能呢？因为这其实是我用的最多的文件服务器了。这里就来说一下如何使用吧。

在Linux上除了scp命令可以使用sftp服务器外，还有个更强大的命令叫sshfs，这个命令能够将远程的文件夹直接挂载到你本地的文件夹下，非常自然的成为你系统的一部分。你在本地使用完全感觉不出来这是在操作远程文件系统，因为他已经完整的挂载过来了，至于如何完成远程文件系统实际的读写，这都是sshfs做的工作，你根本察觉不出来。

下面就说一下如何使用
在ubuntu上和fedora上的操作其实都是一样的，就是安装命令不同，ubuntu用户自行把dnf命令替换会apt-get命令
```
# 首先安装sshfs命令
sudo dnf install sshfs
# 新建一个文件夹作为挂载点,~是指的你的home文件夹
mkdir ~/remote
# 基本的挂载，PORT修改成你ssh的端口，rpi修改成你的树莓派的ip地址，/home/pi 是你想挂载过来的远程的文件夹，后面的~/remote是本地的挂载点。
sshfs -P PORT pi@rpi:/home/pi ~/remote
```
打开看一下刚刚建好的remote文件夹看看树莓派的home是不是挂载过来了，你对这个文件夹的操作都会实时的传回树莓派，传输速度同你的网速。

实际上我们并不直接挂载home回本地，因为没有意义，树莓派本身就是用的一个sd卡，速度慢空间小。我们这里挂载的是你挂载树莓派上的硬盘。如果前面你成功挂载了你的硬盘到你的树莓派，那么把树莓派上的这个挂载点挂回你的本地，这样就可以任意操作了。我的所有的数据和文档全都放在这个硬盘上，本地的硬盘从来不存重要的东西，这样随便安装系统也不怕数据没了，而且像我这种既要用笔记本又要用台式机的人，经常要在多个电脑间上换来换去的。经常出现一个文档我在这个笔记本上写完了，切回台式机还要用u盘再传一份，改几个字，出差了，又要再传一份给笔记本。。费劲不说，万一忘了会出大叉子。通过这种方式，所有的数据只留一份给树莓派，完美的解决了多设备同步的问题，因为数据只有一份。笔记本用个小的ssd也不用担心硬盘不够用了。。说多了，其实用法很多，看你要怎么用了。回到正题。

这么好的东西，用windows的怎么办？其实windows也有sshfs命令，直接去下一个就可以了，下载地址：https://code.google.com/p/win-sshfs/downloads/list 有两个依赖，分别是[.NET Framework4](http://www.microsoft.com/download/en/details.aspx?id=17718) 和[Dokan Library](http://dokan-dev.net/wp-content/uploads/DokanInstall_0.6.0.exe) 自己下载安装吧，安装完了图形界面配置，按照要求填完，就可以挂载了，挂载完成后，会出现在我的电脑里面，多出对应的盘符。接下来就可以任意使用了。

## samba服务器

samba服务器是针对windows用户的服务器，但很多linux的文件浏览器也支持，这里也对他进行搭建的过程进行记录。
安装命令如下：
```
sudo apt-get install samba samba-common-bin
```
安装完成后编辑/etc/samba/smb.conf文件
```
sudo vim /etc/samba/smb.conf
```
在文件的最后添加如下内容：
```
[NAME]                         # 这里修改成你想要显示的名字
    comment = some comment     # 注释，你也可以不加
    path = /path/of/folder     # 这是你要共享的文件夹
    browseable = yes           # 允许浏览
    writable = yes             # 是否可写
    create mask = 0664         # 新建文件的权限
    directory mask = 0775      # 文件夹的权限
```
如果你有多个要分享的文件夹，就多写几个这个豆腐块。
添加一下用户，注意这个用户必须是要在你的系统中真实存在的,例如我们pi用户。
```
smbpasswd -a pi
```
完成后重启samba服务
```
sudo service samba restart
```
windows用户这时就可以打开我的电脑，映射网络驱动器-> 文件夹输入"\\\\ip to your rpi\\NAME"。中间部分是你的ip，NAME就是前面你在中括号里面填的内容。成功连接后就可以访问了，linux用户自行查找连接方法。

## ftp服务器
ftp这种老牌的文件服务器自然也是少不了的，这里使用vsftpd服务器就可以满足我们的基本需要。vsftpd是一个比较轻量级的ftp服务器，一般需求完全可以满足，在linux下很常用。
在树莓派下安装vsftpd可以使用apt-get来进行安装
```
sudo apt-get install vsftpd -y
```

配置文件是/etc/vsftpd.conf 这个文件的内容很多，一般使用的话可以按照下面的配置做一下

```
# 一些配置需要去掉配置文件前的 ’#‘ 才能生效
write_enable=YES # 可以上传文件
local_umask=022
anonymous_enable=NO # 不能匿名访问
local_enable=YES  # 本地用户可以访问

# local_root选项可能没有在配置文件中显示，
# 他的作用是设置ftp登陆进去看到的目录，根据自己的情况进行设置
local_root=/path/of/ftp/root
```

退出后重启vsftpd服务，测试一下ftp连接是否成功

```
sudo service vsftpd restart
```

## 种子下载功能

一个合格的数据中心也要具备从网上下载数据的能力，由于目前还在学校，享受着免费的不限网速的ipv6,下载能力强悍而且有众多种子站，我使用的是transmission-daemon来替我完成种子下载功能。如果需要迅雷下载功能，需要使用aria2来帮你实现，但这个软件的配置略麻烦，而且我也没用过，就不写了。

**安装transmission-daemon**
```
sudo apt-get install transmission-daemon
```
安装完成后第一件事情就是停止transmission-daemon服务，否则你后面做的修改保存不下来的。
```
sudo service transmission-daemon stop
```

**配置transmission-daemon**

```
sudo vim /etc/transmission-daemon/settings.json
```
一般使用，只需要修改一下下面的内容就好了，需要查看完整的参数说明，请[参考官网](https://trac.transmissionbt.com/wiki/ConfigurationParameters)

```
# 下面这个参数指定下载地址
"download-dir": "/home/pi/media/bt/downloads",
# 下面这个参数指定同时下载的任务数量
"download-queue-size": 2,
# 下面这个参数表示未完成的任务放在另一个地方，我们就不用了。
"incomplete-dir-enabled": false,
# 下面的参数开启远程web管理界面
"rpc-enabled": true,
# 下面这个参数表示web管理界面是否需要密码，我们选是
"rpc-authentication-required": true,
# 下面的参数就是web管理界面的管理信息，大家看着改成自己的内容就好了
"rpc-username": "登录名",
"rpc-password": "明文密码（保存后自动变成密文）",
"rpc-port": 9091,
```
需要改的就这么多，其他的使用默认的就好了。为了能避免出现读写权限问题，我们直接把你要下载的下载目录改成777权限，如下：
```
sudo chmod 777 -R bt
```

**重启服务**
```
sudo service transmission-daemon reload
sudo service transmission-daemon start
```

没有错误的话，打开浏览器，在地址栏输入 树莓派的ip:9091 看一下是不是成功启动了？以后直接上传自己的种子文件，他就会自动下载了。

## wakeonlan 远程唤醒我的电脑

说一个不是NAS的功能的小工具，wakeonlan是一个perl写的小工具，作用很简单，发送魔术包，唤醒同一网段的主机。这个功能对我来说很方便也很实用。目前绝大部分主机的bios里面都可以设置远程唤醒，其实就是监听有没有给自己发过来的魔术包，魔术包就是magic packet，是包含特定内容的一个socket包，使用的是udp协议。有了这个工具，哪怕在外地想连上自己的主机，通过这个工具就可以直接开机了。需要注意的是使用这个工具最好是将树莓派和主机放到同一个路由器下面。使用方法很简单，先确认自己的主机有远程唤醒功能，并在bios里启动，然后安装
```
sudo apt-get install wakeonlan
```
安装完成后，在树莓派上继续输入下面的命令，查看一下自己电脑的mac地址是多少
```
arp -a
```
该命令会把所有同网段的ip都列出来，其mac地址也会列出来，可以看看树莓派能不能到你的电脑，找到自己电脑的ip，记录一下你的mac地址，以后你就直接输入下面的命令启动你的电脑好了。
```
wakeonlan [你的mac地址]
```

我的NAS的功能就是这么多，未来工作就有三点，一是可以试试组一个软raid，第二个是上webdav服务，最后就是试着搭一个自己的git服务器。

title: win10和archlinux双系统安装记录
mathjax: true
date: 2017-01-13 17:03:07
categories: 学习笔记
tags: archlinux
plink: wadual
---
近期买了个骷髅峡谷，其实目的就是想体验下最强核显的效果，这个NUC做的很小巧，性能又很不错，支持type-c输出，用作个人电脑感觉很是不错。随着用的时间越久，感觉越喜欢这个小东西。这里记录下安装win10和archlinux的经历，使用的是UEFI启动加GPT分区，windows和archlinux的系统盘都放在同一个固态硬盘上。UEFI+GPT以后应该是主流配置，所以这里跳下坑还是很有必要的。

## Windows 10

先装Windows 10，我在同一个SSD上放两个系统的系统盘。

## archlinux

[中科大源](http://mirrors.ustc.edu.cn/)下载archlinux最新系统。windows上把系统盘写到u盘上，[rufus](https://rufus.akeo.ie/)就可以完成。

### 文件系统

这里假设你的windows已经装好了，在固态硬盘上有你的c盘，进入archlinux后直接用fdisk看一下你的分区情况，这里我给出我的盘的情况，仅供参考

```
# fdisk /dev/sda
p

Device         Start       End   Sectors  Size Type
/dev/sda1       2048    923647    921600  450M Windows recovery environ
/dev/sda2     923648   1128447    204800  100M EFI System
/dev/sda3    1128448   1161215     32768   16M Microsoft reserved
/dev/sda4    1161216 116508671 115347456   55G Microsoft basic data
```
进入fdisk后输入m看帮助。用fdisk分区，把固态硬盘剩下的空间都分到新的盘符内，这里就是/dev/sda5了，分完后保存退出。这里我还用了我另一个硬盘的一部分空间作为我的home分区，也是使用fdisk来分区。

分完区后，用mkfs来格式化，这里用的ext4文件格式，只需要格出root和home来就可以。完成格式化后挂载到现在的文件系统内，也要把EFI文件系统挂载上。
```
# mkfs.ext4 /dev/sda5
# mkfs.ext4 /dev/sdb2

# mount /dev/sda5 /mnt

# mkdir -p /mnt/boot/EFI
# mount /dev/sda2 /mnt/boot/EFI

# mkdir -p /mnt/home
# mount /dev/sdb2 /mnt/home
```

### 安装系统

网络是必须要有的，这里简单说一下，以后可能会单独出个教程讲下这个配置，简单说有线连接用dhcpcd命令，无线连接用wifi-menu命令。
```
有线连接：
# dhcpcd

无线连接：
# wifi-menu  
```
能够联网后最好配置下archlinux的软件源，可以添加中科大的源，文件的地一个Server是中科大的源就好了，不需要删除他自带的源:
```
# vim /etc/pacman.d/mirrorlist
Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch
```

接着安装系统并写入fstab
```
# pacstrap -i /mnt base base-devel
# genfstab -U -p /mnt >> /mnt/etc/fstab
```

### 系统简单配置

完成上面的安装，接下来需要chroot到新系统做一些设置，这里使用的arch自己的chroot

```
# arch-chroot /mnt /bin/bash
```
执行后，你就来到了新的系统环境下，先装下vim，新的系统居然没有vim（也没有wifi-menu），现在的新系统沿用你之前的网络设置，并使用之前你设置的mirrorlist
```
sudo pacman -S vim
```
装完后，先设置hostname和hosts，否则以后sudo可能会报错
```
# echo [YourHostname] > /etc/hostname
```
编辑/etc/hosts，在127.0.0.1和：：1这两条记录的hostname后加上你的hostname。完成后执行下面一句
```
mkinitcpio -p linux
```
当然别忘了设置下root密码
```
passwd
```

更多的配置见我另一篇blog，这里不用的话也已经可以了。

### grub安装
这里使用grub来进行引导，使用efibootmgr来管理efi的启动项。由于新装的系统不带grub，需要我们进行安装。
```
# pacman -S grub efibootmgr
# grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=arch_grub --recheck
# grub-mkconfig -o /boot/grub/grub.cfg
```

完成后退出，umount掉/mnt就可以重启了
```
# exit
# umount -R /mnt
# reboot
```

## 双系统引导
这里我出现过两种情况，这里都说一下。
### 安装完只能进入archlinux，不能进入windows
这是正常情况，因为我们没有写windows的menu，grub只能引导进入archlinux。解决的方法就是进入archlinux后编辑/boot/grub/grub.cfg。编辑前，先保存两个字符串，一会编辑有用。
```
# grub-probe --target=fs_uuid /boot/EFI/EFI/Microsoft/Boot/bootmgfw.efi >> /root/fs_uuid

# grub-probe --target=hints_string /boot/EFI/EFI/Microsoft/Boot/bbootmgfw.efi >> /root/hints_string
```
执行后，会在/root下生成两个文件，一个就是你的fs\_uuid一个是hints\_string，这时候编辑/boot/grub/grub.cfg，找到
```
### BEGIN /etc/grub.d/10_linux ###
...
### END /etc/grub.d/10_linux ###
```
在他们之间加上下面一段
```
menuentry "Microsoft Windows 10 x86_64 UEFI-GPT" {  
    insmod part_gpt  
    insmod fat  
    insmod search_fs_uuid  
    insmod chain  
    search --fs-uuid --set=root \$hints_string \$fs_uuid
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi  
}
```
这里注意替换下\$hints\_string为你之前生成的hints\_string，\$fs\_uuid为你之前生成的fs\_uuid。如果想加，还可以加入shutdown和restart项
```
menuentry "System shutdown" {  
    echo "System shutting down..."  
    halt  
}
menuentry "System restart" {  
    echo "System rebooting..."  
    reboot  
}
```
重启就可以了。
### 安装完只能进入windows，不能进入archlinux
这种就是异常情况了，[官方wiki](https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface#Windows_changes_boot_order)里有解释和如何修改。这里记录一下：
1. 检查下有没有关闭win10的Fast Startup
2. 检查下有没有关闭Bios的Secure boot
3. 在就是很可能你的主板修改或者有默认的efi启动路径，windows下管理员启动cmd运行下面一句
```
bcdedit /set "{bootmgr}" path "\EFI\path\to\app.efi"
```
举个例子，如果按照我的教程写的，不出意外你的efi的路径就在"\\EFI\\arch_grub\\grubx64.efi"
所以这里只需要输入
```
bcdedit /set "{bootmgr}" path "\EFI\arch_grub\grubx64.efi"
```
就可以了，这时候重启，就会发现能进入archlinux了，如果archlinux现在不能启动windows，接着看上一小节的内容。

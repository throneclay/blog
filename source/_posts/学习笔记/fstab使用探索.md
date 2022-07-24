title: fstab使用探索
date: 2016-01-08 08:59:40
categories: 学习笔记
tags: Linux
plink: fstab
mathjax: true
---

最近折腾了一下fstab这个文件，学习了一下fuse，目的是为了能够自动挂载远程的硬盘，这里就来记录一下。

fstab文件是Linux中重要的系统文件，位置是/etc/fstab。该文件在开机的时候被mount命令读入，按照文件的配置，mount会挂载对应的文件系统。无论是对系统的运营维护还是挂载服务器上的文件系统，我们都需要对fstab文件进行必要的配置。
## fstab文件的格式

在fstab文件中定义了mount的相关配置，还有一些系统操作的配置。fstab的每一行都是一条记录，记录了这个文件系统的挂载方式，每条记录又分成了6列，如下所示。
```
# device-spec   mount-point     fs-type     options     dump      pass
```
1. device-spec: 设备标识，可以使device name, label, UUID等，这里是文件系统的入口
2. mount-point: 挂载位置，挂载后可以通过这里来进入挂载的文件系统，对于swap文件系统这里填none
3. fs-type: 文件系统，告诉mount我要挂载的文件系统是什么类型，常见的有ext4, proc, swap, tmpfs(临时文件系统), vfat, ntfs等等
4. options: 这里是mount的参数部分，定义了具体的挂载行为
5. dump: 这里定义了这个文件系统转储的频率，0表示从不转储
6. pass: 表示这个文件系统在启动时候的使用fsck检查顺序,1表示root 文件系统，2表示root文件系统之后接着检测，0表示从不检查（适合其他的设备）

## fstab同mount的关系

由于fstab文件在系统启动的时候才会被使用，因此知道fstab同mount的关系，用mount来检查fstab文件是否起作用是非常重要的。
为了简单描述，这里使用\$fstab_row的方式来表示fstab文件中对应的列的内容。例如\$device-spec就表示在fstab文件中，device-spec那个地方填的内容。
这样我们就有了下面这个命令，fstab的文件内容翻译成mount如下：

```
sudo mount -t $fs-type $device-spec $mount-point -o $options
```
options这个位置具体怎么填写，查mount的man手册，看options部分。
## FUSE(Filesystem in Userspace)用户空间文件系统

FUSE这个功能真是非常强大，他允许你通过实现一组接口来自定义任意的文件系统。按照其标准实现后，可以使用mount直接挂载，挂载后对文件系统的读写操作会被转成你实现的读写操作来完成对文件系统的访问。比较知名的fuse文件系统有很多啦，像sshfs，ntfs-3g等。

如果你想自定义自己的文件系统，那么网上有很多资料，IBM有篇文章写的就很好，很适合上手( https://www.ibm.com/developerworks/cn/linux/l-fuse/ )。当然我们这里就不再多介绍了，这里是假设我已经完成了这个功能，我们如何通过mount来进行挂载。

fstab文件中的\$device-spec字段，或者说mount的device参数（两者其实是一回事），可以通过添加一点前缀来调用你实现的fuse接口代码。假设我实现了这组接口，编译出来的代码是Myfs,这样$device-spec就变成了Myfs#\$device-spec了(在原\$device-spec前加上Myfs#)。这么说还是不太好描述，看下面这个例子吧。

## Example: 使用fstab通过sshfs挂载远程硬盘

sshfs是FUSE的作者Miklos Szeredi写的非常实用的fuse接口的一个实现，他使用的是SSH File Transfer Protocol(SFTP)协议，一般的ssh服务器默认都开了此协议，因此对于ssh这种登录方式的都可以直接使用。由于sshfs能独立运行，直接使用也可以挂载，这里说的是使用mount通过fuse来进行挂载。
这里的sshfs就是我们上面说到的fuse接口的一个实现。mount的时候需要指明我们的device需要使用sshfs来进行操作。这里的一个挂载的实例如下：
```
mount -t fuse sshfs#username@ip/path/of/server /media/remote -o IdentityFile=/home/user/.ssh/id_rsa
```
这里sshfs#就是指明了sshfs是实现fuse的程序，使用的时候，fuse在底层就通过sshfs实现的接口操作远程的文件系统了。

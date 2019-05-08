title: bandwagonhost搬瓦工搭建ipv6+shadowsocks
date: 2015-07-05 15:46:36
categories: 学习笔记
tags:
plink: bwg
mathjax: true
---
前段时间写论文的时候突然发现谷歌学术上不去了，由于时间紧任务重，下了个vpngate临时上谷歌。后来谷歌学术又能上了，就没再怎么研究。其实用vpn速度一点都不好，而且经常断，安全性也没有保障（都不知道连的谁的服务器。。），后来就找到了shadowsocks。不仅速度快，而且安全可靠，最重要的是支持ipv6，这对我等学生党实在是天大的福利啊。不过shadowsocks需要境外主机来搭，这里就先对比下一些主机，境外主机都支持paypal，有储蓄卡就可以支付，所以还是能玩的转的。不过现在shadowsocks没有人维护了，所以也不知道这种方法能用多长时间，不过现在是可以用的。

Digitalocean，他的San Francisco主机对大陆速度飞起，而且支持ipv6，github上有student pack可以送100刀，他最便宜的VPS每月5美刀，这样可以用两年左右，使用https://www.digitalocean.com/?refcode=935e7e684f9d 注册可以再送10美刀。

[Bandwagonhost](https://bandwagonhost.com/aff.php?aff=3889)是后来发现的一个主机，也是我现在用的主机，特点就是价格低，一年$9.99，之前还有更便宜的$3.99一年的，可惜我并没有抢到，搬瓦工在Phoenix，AZ上的主机对大陆速度最快最稳定，本文章重点就介绍如何在banwagon上搭建shadowsocks并让他支持ipv6.

## 配置ShadowSocks

对于配置shadowsocks基本流程都是一样的，跟着github上的shadowsocks教程走也能走的通，这里简单带过

```
yum update -y
yum install -y epel-release python-setuptools m2crypto supervisor
easy_install pip
pip install shadowsocks
```

**由于老版本的shadowsocks并不支持后台运行，但2.6版本以后的都可以直接后台运行了:  [(参考)](https://github.com/shadowsocks/shadowsocks/wiki/%E7%94%A8-Supervisor-%E8%BF%90%E8%A1%8C-Shadowsocks)**。所以对于新版本来说，后台启动的使用方式：
```
ssserver -c /etc/shadowsocks.json -d start # 启动并后台运行
ssserver -c /etc/shadowsocks.json -d stop  # 停止后台运行
{% endcodeblock %}
如果想启动自动后台运行，可以直接在/etc/rc.local 文件中添加下面一句话
{% codeblock lang:bash %}
ssserver -c /etc/shadowsocks.json -d start
```

对于老版本来说，为了能够后台运行shadowsocks服务器，只能装supervisord。在/etc/下新建shadowsocks.json文件，输入下面内容：

```
{
    "server":"my_server_ip",
    "server_port":8388,
    "local_address": "127.0.0.1",
    "local_port":1080,
    "password":"mypassword",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open": false
}
```

这里内容自己填好就好，method是加密的方法，注意一点，这里server地址我们填”::”这样可以同时支持ipv4和ipv6，编辑好后保存退出。接下来修改supervisord.conf文件,vim /etc/supervisord.conf,在文件最后添加下面内容：

```
[program:shadowsocks]
command=ssserver -c /etc/shadowsocks.json
autostart=true
autorestart=true
user=root
log_stderr=true
logfile=/var/log/shadowsocks.log
```

保存后退出，启动supervisord服务：service supervisord start 这时候shadowsocks服务就启动起来了，这时候试试看ipv4是不是已经可以代理了。也可以把service supervisord start加到 /etc/rc.local文件中，这样每次启动的时候supervisord都会起来帮我们运行ss服务器。

windows下的client可以在[shadowsocks-gui](http://sourceforge.net/projects/shadowsocksgui/files/dist/)中下载到，配置就把服务器的配置添加上就可以了，启动系统代理就可以访问了。

## IPV6服务启动

**现在bandwagonhost已经原生支持ipv6了**，只需要在控制面板里面启动ipv6我的bandwagonhost支持3个ipv6地址，直接随机生成一个ipv6地址，重启一下就可以用了。之前由于banwagonhost不支持ipv6,所以使用的是tunnelbroker的ipv6中转功能，这里对使用方法做一个记录，万一以后有用的话还可以用上。支持ipv6的主机就不用看这里了。

Bandwagon 采用Openvz架构，不能直接使用tunnel来进行ipv6的转发，这里使用了tb-tun工具进行转发，详情可见tb-tun的github,安装过程如下：

1.在[tunnelbroker](https://tunnelbroker.net/)上注册一个用户名，这个网站专门用来做ipv6的中转，速度不错，而且是免费的。找到Create Regular Tunnel选项，输入你的主机ip，选择最近的server,由于我是用的Phoenix，AZ的主机，所以就直接选上了。

2.安装tb-tun：

```
yum install -y iproute gcc
cd /root
wget http://tb-tun.googlecode.com/files/tb-tun_r18.tar.gz
tar -xf tb-tun_r18.tar.gz
gcc tb_userspace.c -l pthread -o tb_userspace
```

3.新建一个脚本

```
vim /etc/init.d/ipv6tb
```

输入以下内容：

```
#! /bin/sh

### BEGIN INIT INFO
# Provides:          ipv6
# Required-Start:    $local_fs $all
# Required-Stop:     $local_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the ipv6 tunnel
# Description:       ipv6 tunnel start-stop-daemon
### END INIT INFO

# /etc/init.d/ipv6tb

touch /var/lock/ipv6tb

case "$1" in
  start)
    echo "Starting ipv6tb "
      setsid /root/tb_userspace tb [Server IPv4 Address] [Client IPv4 Address] sit > /dev/null 2>&1 &
      sleep 3s #ugly, but doesn't seem to work at startup otherwise
      ifconfig tb up
      ifconfig tb inet6 add [Client IPv6 Address]/64
      ifconfig tb inet6 add [Routed /64]::1/64 #Add as many of these as you need from your routed /64 allocation
      ifconfig tb mtu 1480
      route -A inet6 add ::/0 dev tb
      route -A inet6 del ::/0 dev venet0
    ;;
  stop)
    echo "Stopping ipv6tb"
      ifconfig tb down
      route -A inet6 del ::/0 dev tb
      killall tb_userspace
    ;;
  *)
    echo "Usage: /etc/init.d/ipv6tb {start|stop}"
    exit 1
    ;;
esac

exit 0
```

保存后退出，并使其可执行：

```
chmod 0755 /etc/init.d/ipv6tb
```

4.执行！
```
/etc/init.d/ipv6tb start
```

5.测试一下，可以ping6 google.com看能不能ping通，如果能ping通，那么说明ipv6中转已经完成。以后使用ss服务器，可以输入tunnelbroker.net给你的ipv6 client地址来进行访问了。如果你有域名，可以将域名AAAA添加一条指向该ipv6地址的记录，以后可以直接用这个域名来访问了。

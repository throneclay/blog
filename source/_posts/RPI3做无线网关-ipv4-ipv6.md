title: 树莓派3开无线热点变身为智能无线网关（IPv4+IPv6）
date: 2016-11-12 15:46:19
categories: 嵌入式
tags: raspberryPi
plink: rpi3net
mathjax: true
---

无线上六维不是梦，折腾了两天终于终于弄好了～撒花～

这个暑假一直在外实习，回到学校发现实验室已经没有了我的位置。。悲催的被赶到另一个实验楼，这个实验楼主要放的是各种服务器，因此IP比较紧张，以前我自带一个交换机，IP地址随便用，而且都是有线，IPv6默认都可以用，但这边我只分得一根网线，只有一个固定的IPv4的IP，倒是IPv6没有限制（不过后来测试发现还是有些限制）。对于我这么多设备根本不够用嘛。正好看到树莓派3上市了，自带wifi，CPU升级到A53，是服务器级的U了，立刻买了一个回来，当作我的网关。

**这里我用树莓派搭的其实是一个NAT的路由器，把WAN的ipv4和ipv6都共享给内网LAN**,由于是在学校，我的IPv4的地址是固定的，而IPv6的地址动态分配（前缀是固定的），所以不要盲目跟着教程做。这里使用的树莓派是3代树莓派，系统是2016-09-23的raspbian jessie，板载wifi，不需要考虑驱动的问题，如果不是，那么先自行解决驱动问题，这里WAN外网是eth0，LAN内网是无线wlan0，如果接口不一致请自行替换，后面不再做解释。

## 准备工作

整个过程分为两步，先开IPv4的热点access point，再共享IPv6的热点access point，热点都不是采用bridge方式进行的连接。

### 固定IP(IPv4)

后面的树莓派默认使用dhcpcd进行ip的配置，因此网上好多关于配置树莓派固定IP的方法都是有点问题（很早的时候是配置/etc/network/interfaces），**我们现在配置dhcpcd的配置文件进行固定IP的配置**,打开配置文件/etc/dhcpcd.conf
```
sudo vim /etc/dhcpcd.conf
```

里面内容不少，感兴趣可以查一下，这里直接拖到最下，根据自己的情况加入下面的内容

```
interface eth0
static ip_address=211.187.224.79/24
static routers=211.187.224.16
static domain_name_servers=114.114.114.114
```
其中ip_address后面接的是CIDR格式的ip地址，/24是指的netmask是255.255.255.0，地址根据自己的情况填一下即可。
重启就可以上网了。ping一下外网看一下是不是已经通了，IPv6是用ping6。

## 配置IPv4热点access point
这里使用的是NAT转发
先装依赖
```
sudo apt-get install dnsmasq hostapd
```
之所以使用dnsmasq是因为配置简单，而hostapd是必不可少的虚拟热点的程序，hostapd对ipv4和ipv6都支持。
配置的时候要给我们的wlan0一个固定的内网IP，再次编辑我们的dhcpcd.conf,在最后接上下面的内容
```
interface wlan0
static ip_address=10.0.0.1/24
```
继续配置dnsmasq，在/etc/dnsmasq.conf的最后加上下面一段（此文件内容很多，但都被注释掉了）
```
interface=wlan0
dhcp-range=10.0.0.2,10.0.0.5,255.255.255.0,12h
```
编辑/etc/hostapd/hostapd.conf文件（新文件），加上下面的内容
```
interface=wlan0
hw_mode=g
channel=10
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
rsn_pairwise=CCMP
wpa_passphrase=密码
ssid=名称
```
把密码和名称替换成自己想设置的就可以了。接着修改/etc/sysctl.conf文件，找到下面一行去掉#
```
net.ipv4.ip_forward=1
```

继续，更新下iptables的规则：
```
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
```
最后一句的目的是将我们执行的三句iptable设置保存下来，以后能直接使用，我们保存到了/etc/iptables.ipv4.nat位置。编辑/etc/network/interfaces，最后加上下面这句话，每次开机都会配置好iptables的内容了
```
up iptables-restore < /etc/iptables.ipv4.nat
```
既然打开这个文件了，可以把上面的几句wlan的interface注释一下，反正这些话也没用了，即变成这样：
```
allow-hotplug wlan0
iface wlan0 inet manual
#    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

#allow-hotplug wlan1
#iface wlan1 inet manual
#    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
```
为了能够每次开机自动运行hostapd，我们还要修改/etc/rc.local文件，在exit 0 前加上下面这句话
```
hostapd -B /etc/hostapd/hostapd.conf & > /dev/null 2>&1
```
重启，就可以看到热点了。至此IPv4部分完成。

参考资料：
1. 树莓派3内置WIFI无线路由器AP热点:  https://item.congci.com/-/content/shu-mei-pai-3-neizhi-wifi-wuxian-luyouqi-ap-redian
2. 这个文章还提到了桥接方式进行连接的方法: http://wangye.org/blog/archives/845/

## 配置IPv6热点access point

前面的配置方法网上一搜一大把，这里其实就是记录一下，真正花了我两天时间的是配置IPv6的无线热点。。类似IPv4的配置方法，这里主流配置有两种，一种是使用桥接把无线的IPv6流量转到有线的IPv6上，这种方法配置简单，但我用上后只能坚持几十秒，整个树莓派就再也不能上网，只能重启（非常怀疑学校里在配置了交换机，不让使用桥接），另一种就是我最后成功的使用radvd＋npd6+DHCPv6＋hostapd的这种NDP连接。
这里也写一下第一种方法，毕竟曾让我高兴了几十秒，本着记录为目的的话还是要记一下。**两种方法只能选一种，强烈建议使用第二种方法**

### IPv6 桥接
编辑配置文件/etc/sysctl.conf，把下面一行的注释去掉
```
net.ipv6.conf.all.forwarding=1
```
用ifconfig看一下自己的ipv6的地址，注意Scope:Global的那个地址是你的IPv6外网地址，Scope:Link的那个地址应该是你的上级地址。我们这里只关注Global那一项，安装radvd
```
sudo apt-get install radvd
vim /etc/radvd.conf
interface wlan0
{
   AdvSendAdvert on;
   prefix 2001:da8:7001:251::/64
   {
        AdvOnLink on;
        AdvAutonomous on;
        AdvRouterAddr on;
   };
};
```
这里的2001:的地址就是我的Global那一项的地址
装bridge－utils和ebtables
```
sudo apt-get install bridge-utils ebtables
```
在home下写个脚本ipv6_bridge.sh，内容如下
```
#!/bin/sh
iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -o ppp0 -j MASQUERADE
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
service radvd start
brctl addbr br0
ifconfig br0 up #启动网桥
brctl addif br0 eth0
brctl addif br0 wlan0 #桥接两块网卡
ebtables -t broute -A BROUTING -p ! ipv6 -j DROP #只允许ipv6包通过网桥
```
给他加上执行权限，重启后sudo执行就可以了
```
chmod a+x ipv6_bridge.sh
sudo reboot
sudo ./ipv6_bridge.sh
```
这时候如果没有问题，那你就完成了IPv4 NAT转发，IPv6桥接的双栈无线热点。
参考资料：
1. 树莓派扩展 IPv6无线路由配置(二)  http://blog.csdn.net/lingjun_love_tech/article/details/41382625
2. Linux 用作 IPv6 网关  https://bigeagle.me/2011/11/linux-as-ipv6-gateway/index.html
3. 讨论这个的还是OpenWRT比较多，可以参考一下 http://www.openwrt.org.cn/bbs/thread-7116-1-1.html

### IPv6 NDP IPv6
IPv6是没有NAT的，NAT对于我们是很熟悉，IPv6由于地址足够多，没有使用NAT技术，他用的是NDP( Neighbour Discovery Protocol 邻居发现协议), NDP有点类似NAT，在NDP协议中，内网的IPv6地址也是外网地址，可以向外发送请求，但不可再路由，这时就需要让具有外网地址的Router帮忙告诉它的上层Router，这些外网地址在这个Router的内网中。radvd就支持NDP，
**先安装依赖**
```
sudo apt-get install radvd wide-dhcpv6-server
```
如果wide-dhcpv6-server提示转发interface，就写wlan0
编译安装npd6
```
git clone https://github.com/npd6/npd6
cd npd6
make
sudo make install
```
首先我们先配置/etc/sysctl.conf，找到合适的地方加上下面两句
```
net.ipv6.conf.all.proxy_ndp=1
net.ipv6.conf.all.forwarding=1
```
用ifconfig看一下自己的ipv6的地址，注意Scope:Global的那个地址是你的IPv6外网地址，Scope:Link的那个地址应该是你的上级地址。

写一个脚本ndp_ipv6.sh 内容如下：
```
#!/bin/sh
ip -6 addr del 2001:da8:7001:251:fe54:7ee0:6994:5fb7/64 dev eth0
ip -6 addr add 2001:da8:7001:251:fe54:7ee0:6994:5fb7/126 dev eth0
ip -6 addr add 2001:da8:7001:251:1::/80 dev wlan0
ip -6 route add default via fe80::f7ce:a905:9347:7144 dev eth0 metric 256
ip -6 route add 2001:da8:7001:251:1::/80 dev wlan0

service radvd restart
service npd6 restart
```
先解释下这个脚本，2001:da8:7001:251:fe54:7ee0:6994:5fb7是我的Global的IPv6地址，这个原样根据自己的地址修改，后面的/64和/126不要动（64可能要改成你查到的perfix长度，126是不能动的，防止错乱），2001:da8:7001:251:1::/80是内网分配的地址前缀，前四段跟Global的地址一样，后面随便加个数就可以，这里直接写1，接下来那个fe80开头的地址换成你的Link的那个地址，加上执行权限，脚本先放在这里。

**配置radvd**
编辑/etc/radvd.conf（可能是新文件），写入下面的内容：
```
interface wlan0
{
AdvSendAdvert on;
AdvManagedFlag on;
AdvOtherConfigFlag on;
prefix 2001:da8:7001:251:1::/80 {
AdvRouterAddr off;
AdvOnLink on;
AdvAutonomous on;
};
};
```
注意上面的2001开头地址要换成你刚才设定好的内网地址。

**配置npd6**

npd6是邻居发现代理，编辑/etc/npd6.conf，写入下面的内容：
```
prefix=2001:da8:7001:251:1:
interface = eth0
ralogging = off
listtype = none
listlogging = off
collectTargets = 100
linkOption = false
ignoreLocal = true
routerNA = true
maxHops = 255
pollErrorLimit = 20
```
注意2001开头那个地址还是要填你自己的内网地址。

**配置DHCPv6**

编辑文件/etc/wide-dhcpv6/dhcp6s.conf，写入下面的内容，
```
interface wlan0{
address-pool pool1 86400;
};
pool pool1 {
range 2001:da8:7001:251:1::200 to 2001:da8:7001:251:1::300;
};
```
这是圈定了你的内网范围。好了，重启后sudo执行脚本ndp_ipv6.sh
```
chmod a+x ndp_ipv6.sh
sudo ./ndp_ipv6.sh
```
当然完全可以让他开机自启动，编辑/etc/rc.local，在exit 0前加上
```
/home/pi/ndp_ipv6.sh
```
参考资料：
1. 从零开始,把Raspberry Pi打造成双栈11n无线路由器,支持教育网原生IPv6（原网址打不开了） https://hahaschool.net/tag/linux/
2. Openwrt的一篇资料http://blog.martianz.cn/article/2013-05-27-openwrt-ipv6
3. http://talk.withme.me/?p=51

至此ipv4+ipv6无线热点配置完成！经过一段时间测试，比较稳定，信号还是可以的，撒花～

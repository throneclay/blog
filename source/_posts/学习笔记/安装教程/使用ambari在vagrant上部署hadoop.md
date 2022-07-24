title: 使用ambari在vagrant上部署hadoop
date: 2016-03-22 12:21:15
categories: 学习笔记
tags: vagrant
plink: vag_ambari
mathjax: true
---

由于最近看了一些vagrant的使用，尤其看到vagrant能够快速搭建虚拟集群环境，让我想到能不能快速搭建一个hadoop的虚拟测试环境，查了一下果然有ambari神器，这里就记录一下使用ambari在vagrant上部署hadoop的过程。

vagrant的搭建和使用参考我之前的[博客](http://blog.throneclay.com/2016/03/19/vag/)

## ambari介绍
Apache ambari是一种基于web的，快速批量部署hadoop或者spark平台的管理软件，他支持hadoop集群的供应，管理和监控。目前已经支持hadoop的大部分组件。Ambari能够安装安全的（基于Kerberos）Hadoop集群，以此实现了对Hadoop 安全的支持，提供了基于角色的用户认证、授权和审计功能，并为用户管理集成了LDAP和Active Directory。

官方给了一个使用vagrant建立的集群来测试ambari的例子，个人感觉很不错，[官方教程](https://cwiki.apache.org/confluence/display/AMBARI/Quick+Start+Guide)。其实不用他的这个例子自己搭vagrant集群应该也是可以的，但既然官方把Vagrantfile都写好了，ambari也都安装上了，还是替我们节省了很多时间。

## ambari vagrant搭建

这里的介绍主要是按照官方教程来的，首先是从git上clone下repo
```
git clone https://github.com/u39kun/ambari-vagrant.git
```
ambari在后面的测试时有的地方是不能输入ip而是要一个类似域名的名字，为了达到这个目的，需要在本地的/etc/hosts中手动加一下ip和域名的对应关系，他的repo中已经按照特定规则写好了这部分hosts。直接追加到我们的etc上是没有问题的。
```
sudo -s 'cat ambari-vagrant/append-to-etc-hosts.txt >> /etc/hosts'
```
他的repo中提供了用于测试的各种型号的系统，因此他的hosts对应的规则也很简单，打开看一下这个hosts就明白，这里就不说了。

官方教程是用的centos6.4进行的测试，这里也以centos6.4为例了，其他的系统应该大同小异，有兴趣可以测试一下。进入对应的文件目录，启动脚本要用他给的up.sh脚本，不要用自己的vagrant up命令，up.sh脚本可以控制开启多少个节点，而直接vagrant up是直接开10个节点。这里假设开3个节点：
```
cd centos6.4
cp ~/.vagrant.d/insecure_private_key .
./up.sh 3
```
开启的节点的ip也是有规律的，这里用的centos6.4，ip就是192.168.64.[101,102,103]，他们的名字分别是: c640[1,2,3]。如果你是用的centos58，ip就是192.168.58.[101,102,103]，他们的名字分别是c580[1,2,3]。第四段有多少个机器就看你开了多少个节点了。

一旦你up.sh 脚本完成，就可以登录了。因为这是集群环境，需要指定登录的节点名字,如我要登录第一个节点就直接
```
vagrant ssh c6401
```
登录后就是**vagrant**用户，默认的密码也是**vagrant**
接下来就是安装ambari-server，先成为root执行下面的命令:
```
# CentOS 6 (for CentOS 7, replace centos6 with centos7 in the repo URL)
# 
# to test public release 2.2.2
wget -O /etc/yum.repos.d/ambari.repo http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.2.2.0/ambari.repo
yum install ambari-server -y
OR
# to test the branch-2.4 build - updated on every commit to branch-2.4 (under development)
wget -O /etc/yum.repos.d/ambari.repo http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos6/2.x/latest/2.4.0.0/ambaribn.repo
yum install ambari-server -y
OR
# to test the trunk build - updated on every commit to trunk
wget -O /etc/yum.repos.d/ambari.repo http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos6/2.x/latest/trunk/ambaribn.repo
yum install ambari-server -y
 
# Ubuntu 12 (for Ubuntu 14, replace ubuntu12 with ubuntu14 in the repo URL)
# to test public release 2.2.2
wget -O /etc/apt/sources.list.d/ambari.list http://public-repo-1.hortonworks.com/ambari/ubuntu12/2.x/updates/2.2.2.0/ambari.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com B9733A7A07513CAD
apt-get update
apt-get install ambari-server -y
OR
# to test the branch-2.4 build - updated on every commit to branch-2.4 (under development)
wget -O /etc/yum.repos.d/ambari.repo http://dev.hortonworks.com.s3.amazonaws.com/ambari/ubuntu12/2.x/latest/2.4.0.0/ambaribn.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com B9733A7A07513CAD
apt-get update
apt-get install ambari-server -y
OR
# to test the trunk build - updated on every commit to trunk
wget -O /etc/apt/sources.list.d/ambari.list http://s3.amazonaws.com/dev.hortonworks.com/ambari/ubuntu12/2.x/latest/trunk/ambaribn.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com B9733A7A07513CAD
apt-get update
apt-get install ambari-server -y
```

使用default设置，这里接着启动ambari-server
```
ambari-server setup -s
ambari-server start
```

如果启动成功，在你本机的浏览器访问下面的地址 [http://c6401.ambari.apache.org:8080/](http://c6401.ambari.apache.org:8080/)
这时候就能看到ambari server的页面了，用户名和密码默认都是**admin**。
这里说一下这个域名的意思，如果你开的是三个节点，那么他们的域名分别是
```
c6401.ambari.apache.org
c6402.ambari.apache.org
c6403.ambari.apache.org
```
命名规则是一样的，只不过加了后面的一串域名，其实你可以任意修改后面的部分，只是他给的当时追加的hosts文件使用的这个域名。

对于vagrant用户，需要把**insecure_private_key**文件作为自己的private key。

接着就是按照网页的提示进行集群的配置了。

## 搭建本地hadoop源

由于学校的网很差，以至于hadoop源不是下不下来就是下的超慢，因此这里我特地看了下如何搭建本地源，即在这里能加速一下hadoop的安装，又学习一下rpm源怎么搭建。

### 1.安装必要的软件
```
yum install yum-utils createrepo yum-plugin-priorities

yum install httpd
```
编辑/etc/yum/pluginconf.d/priorities.conf文件内容如下：
```
[main]
enabled=1
gpgcheck=0
```
如果安装了PackageKit，还需修改/etc/yum/pluginconf.d/refresh-packagekit.conf为如下：
```
enabled=0
```

启动httpd:
```
chkconfig httpd on
service httpd start

```

### 2.下载资源

资源下载主要有两种方法，1.直接下载，2reposync源同步

#### 2.1 直接下载
使用下载工具下载，速度比较快，首先要下载Centos镜像：
http://isoredirect.centos.org/centos/6/isos/x86_64/

下载后挂载，并拷贝所有内容到/var/www/html/centos64
```
mount -o loop /tmp/CentOS-6.4-x86_64-bin-DVD1.iso  /media
cp  -r /media /var/www/html/centos64
umount /media
```
下载拷贝HDP-2.1和HDP-UTILS-1.1.0.17并解压到/var/www/html/hdp
http://public-repo-1.hortonworks.com/HDP/centos6/2.x/GA/2.1-latest/HDP-2.1-latest-centos6-rpm.tar.gz
http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.17/repos/centos6/HDP-UTILS-1.1.0.17-centos6.tar.gz

```
tar -zxvf HDP-2.1-latest-centos6-rpm.tar.gz –C /var/www/html/hdp
tar -zxvf HDP-UTILS-1.1.0.17-centos6.tar.gz –C /var/www/html/hdp
```
拷贝Ambari-1.5.1并解压到/var/www/ambari
http://public-repo-1.hortonworks.com/ambari/centos6/ambari-1.5.1-centos6.tar.gz
```
tar -zxvf ambari-1.5.1-centos6.tar.gz –C /var/www/html/ambari
```

#### 2.2 reposync源同步
对于CentOS的Repo源，建议采用国内源，如ustc或163，速度最快，如下：
```
wget http://mirrors.163.com/.help/CentOS-Base-163.repo -O  /etc/yum.repos.d/CentOS-Base-163.repo

wget http://public-repo-1.hortonworks.com/ambari/centos6/1.x/updates/1.5.1/ambari.repo -O /etc/yum.repos.d/ambari.repo

wget http://public-repo-1.hortonworks.com/HDP/centos6/2.x/GA/2.1-latest/hdp.repo -O /etc/yum.repos.d/hdp.repo
```
查看当前源中有的repo列表：
```
yum repolist
```
同步Ambari：
```
cd /var/www/html
mkdir -p ambari/centos6
cd ambari/centos6
reposync -r Updates-ambari-1.5.1
```

同步HDP：
```
mkdir -p hdp/centos6
cd hdp/centos6
reposync -r HDP-2.1.2.0
reposync -r HDP-UTILS-1.1.0.17
```
创建repo：
```
createrepo /var/www/html/ambari/centos6/Updates-ambari-1.5.1

createrepo /var/www/html/hdp/centos6/HDP-2.1.2.0

createrepo /var/www/html/hdp/centos6/HDP-UTILS-1.1.0.17
```
创建完成后，就可以通过web路径访问测试了(假设ip是192.168.64.104)
http://192.168.64.104/ambari/centos6/1.x/updates/1.5.1/

### 3 repo文件
下面是我的repo文件内容，文件名是myrepo.repo
```
[CentOS6-Media]
name=CentOS6-Media
baseurl=http://192.168.64.104/centos64
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

[Ambari-1.5.1]
name=Ambari-1.5.1
baseurl=http://192.168.64.104/ambari/centos6/1.x/updates/1.5.1
gpgcheck=0
enabled=1

[HDP-2.1.2.0]
name=HDP-2.1.2.0
baseurl=http://192.168.64.104/hdp/HDP/centos6/2.x/updates/2.1.2.0
gpgcheck=0
enabled=1

[HDP-UTILS-1.1.0.17]
name=HDP-UTILS-1.1.0.17
baseurl=http://192.168.64.104/hdp/HDP-UTILS-1.1.0.17/repos/centos6
gpgcheck=0
enabled=1
```
如果没有使用base，只需要后面三项。这个repo放到/etc/yum.repo.d/文件夹下就可以了。

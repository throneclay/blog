---
title: 使用docker部署支持备份，全docker环境的postgres+confluence环境
mathjax: true
date: 2022-08-08 07:49:21
categories: 学习笔记
tags: nas
plink: confluence_synology
---

本来我已经不想再写什么装个什么软件，配个什么环境的东西了，网上一搜一大堆，跟着搞搞也没什么了，再差就去看看官方的文档，也很容易解决遇到的问题。但这次装confluence既没有了官方的支持（官方文章仅作为一个参考吧），网上找的教程虽然一大堆，但基本也都是复制粘贴的，而且还不太能用，折腾了一个周末才好不容易达到一个比较满意的效果。如果你也遇到这种问题，那算是找对地方了。

废话不多说，先介绍下环境：

硬件还是我的那个群晖nas了，但实际上就是个linux，而且我只是用了他的docker，所以原理都是一样的。 

confluence使用```cptactionhank/atlassian-confluence:latest```的docker（貌似也就2020年更新过一次，后面看上去都没变化了，已经够用了），confluence的版本是7.9.3。数据库使用postgresql，数据库也是使用docker部署，postgresql和confluence使用link的方式共享，**无需多占用host的端口**！ 

使用```cptactionhank/atlassian-confluence:latest```搭建的confluence中我遇到了两个问题，1. 为什么按照教程起不起来，或者报错？（他这个docker有一些限制）2. confluence 的宏乱码，confluence的宏主要在编辑状态下乱码。

## 安装
安装我基本是参照这个url写的：[https://blog.51cto.com/u_15269008/4846190](https://blog.51cto.com/u_15269008/4846190)，只是没用docker-compose，并且改了下使用docker link可以少占用个端口，毕竟nas上起的服务太多了。

注意：他这个docker启动的时候，注意下，尽量ip直接连接到8090的端口上，不要走https，设置完成后进去还能再修改什么的，要不会在他的setup阶段莫名其妙的挂掉。

首先我们创建几个目录：
```
mkdir -p /volume1/docker/confluence/confluence # confluence 的home_data
mkdir -p /volume1/docker/confluence/logs       # confluence 的logs
mkdir -p /volume1/docker/confluence/postgresql # postgresql 的数据库

chown -R 2:2 /volume1/docker/confluence/confluence
chown -R 2:2 /volume1/docker/confluence/logs
```

接着，按照下面的命令启动两个docker

```
docker run --name confluence_postgresql -d \
    --env "POSTGRES_DB=confluence" \
    --env "POSTGRES_USER=confluence_user" \
    --env "POSTGRES_PASSWORD=confluence_pass" \
    --volume /volume1/docker/confluence/postgresql:/var/lib/postgresql/data \
    postgres:latest

docker run --name confluence -d \
    --link confluence_postgresql:postgresql \
    --publish 8090:8090 --publish 8091:8091 \
    --volume /volume1/docker/confluence/logs:/opt/atlassian/confluence/logs \
    --volume /volume1/docker/confluence/confluence:/var/atlassian/confluence \
    cptactionhank/atlassian-confluence:latest
```

启动起来后，按照那个博客写的进行production的激活，但这里需要说一下，jar的包对文件权限非常敏感，**必须是644的权限**！别问我是怎么知道的。

使用命令来考出考入就是这样：

```
# 从docker中拷出
docker cp confluence:/opt/atlassian/confluence/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.4.1.jar ./atlassian-extras-2.4.jar

# 把jar包拷回docker，别看麻烦，建议就按照这几句命令严格执行
sudo chmod 644 ./atlassian-extras-2.4.jar
sudo chown root: ./atlassian-extras-2.4.jar
docker exec -u root confluence bash -c "rm -f /opt/atlassian/confluence/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.4.1.jar"
docker cp ./atlassian-extras-2.4.jar confluence:/opt/atlassian/confluence/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.4.1.jar
```

完成后连接数据库:

host就是上面link的地方填的postgresql，DB_name是confluence，用户是confluence_user，密码是confluence_pass，测试下应该没问题就继续吧。

剩下的我这边没遇到什么问题，应该也不会有问题了。接下来就可以折腾下，然后发现宏的标题在编辑状态下居然都是方框。。。那就继续往下看吧。

## 解决confluence宏乱码的问题

confluence的乱码问题一搜一大堆，各种乱码，这里说的是宏在编辑状态下会出现的乱码问题，使用postgresql的数据库，基本把很多已知的问题都解决了，别的应该也没什么太大问题。乱码实在是太恶心的问题了，这里遇到的乱码问题很诡异，只有编辑状态显示方框乱码，编辑这个宏的时候名字正常，感觉就是什么地方有点小小的问题。网上的方法看上去能搜出一堆，但其实一共就三种，我都列在这里了。我这里使用的方式是三者结合了一下，但我觉得可能其中某一种方法就可以起作用，欢迎大家试一下看最小修改集合是什么

[https://blog.csdn.net/gogobat0/article/details/104202475](https://blog.csdn.net/gogobat0/article/details/104202475)

[https://blog.csdn.net/Smiled0388/article/details/90377254](https://blog.csdn.net/Smiled0388/article/details/90377254)

[https://www.cnblogs.com/caibao666/p/14992184.html](https://www.cnblogs.com/caibao666/p/14992184.html)


首先，得到SimHei.ttf, SimSun.ttf msyh.ttf 三个字体文件，这几个文件其实都能下到不需要找windows去找字体再转一把，太麻烦
```
msyh.ttf https://raw.githubusercontent.com/chenqing/ng-mini/master/font/msyh.ttf
SimHei.ttf https://raw.githubusercontent.com/StellarCN/scp_zh/master/fonts/SimHei.ttf
SimSun.ttf https://raw.githubusercontent.com/micmro/Stylify-Me/main/.fonts/SimSun.ttf
```
有这几个文件安装步骤大大简化，那些转字体什么的就都不要了，安装这三个字体，只需要把他们放到```/usr/local/share/fonts/ttf-dejavu/``` 下，修改下文件权限为664，执行

```bash
chmod 644 SimHei.ttf SimSun.ttf msyh.ttf
fc-cache -fv
```

完成后看一下是不是已经装上了，执行应该会列出刚装的三个字体：

```
fc-list :lang=zh
```

然后，更新/opt/atlassian/confluence/bin/setenv.sh文件，在81行后加上下面两句话

```
CATALINA_OPTS="-Dfile.encoding=UTF-8 ${CATALINA_OPTS}"
CATALINA_OPTS="-Dconfluence.document.conversion.fontpath=/usr/share/fonts/ttf-dejavu/ ${CATALINA_OPTS}"
```

最后，修改这个文件（感觉跟这个没关系啊）```/var/atlassian/confluence/confluence.cfg.xml``` 在你的jdbc后面加上```?characterEncoding=utf8```，加完后是这个样子的：

```
<property name="hibernate.connection.url">jdbc:postgresql://postgresql:5432/confluence?characterEncoding=utf8</property>
```

至于上面是哪个步骤真正起作用了，感兴趣的可以去试一下

重启就可以了。。。

重启后，把chrome的历史记录都删掉，或者你什么浏览器，把历史记录都删掉再去查看就可以了。

## 附运行脚本

---
title: 在Synology DSM7.0上，找回我们熟悉的gitlab
mathjax: true
date: 2022-05-21 07:20:53
categories: 学习笔记
tags: nas
plink: dsm7_gitlab
---

很早的时候手上买了群晖的918作为家里的nas，平时放一些文档，深度学习的数据，最重要的还充当我个人的开发环境及服务器。在DSM6.X的时代，Synology上有gitlab组件，可以方便的搭建gitlab托管自己代码。虽然网上有很多吐槽他不稳定的，但在6.x上我用的还是一直很稳定，包括备份等做的都很不错。性能反正个人用是足够的。但升级DSM7.0后，gitlab组件就没有了。无奈我又想办法降级回6.x使用，但升级这种大趋势我们是没办法阻挡的，作为个人玩家，还是要想办法找到替代方案，于是我就研究了下DSM6.x的gitlab是怎么做的，发现还是很简单的，只要有docker，我们也可以在DSM7上装回熟悉的gitlab。这个方法可以让你继续使用DSM6.x的gitlab数据库，我们就可以放心大胆的升级到DSM7了。

synology的gitlab组件实际上是在这个repo上二次开发的一个封装：[https://github.com/sameersbn/docker-gitlab](https://github.com/sameersbn/docker-gitlab)，之前用gitlab的肯定也发现了，他那个gitlab实际上就是在docker上托管的。这个repo里的readme已经讲的非常详细了，如果希望高阶定制自己的gitlab的可以再研读下他的readme。接下来在nas上搭建gitlab需要1. 记录DSM6上的几个环境变量，作为备份；2. 检查自己gitlab的版本，按照升级路线选择版本；3.在docker上开始搭建。

## 记录DSM6上的环境变量

如果你也是像我一样，之前在DSM6上使用自带的gitlab，想升级到DSM7上还使用原来的repo，那么打开docker，找到gitlab的docker双击，找到这几个环境变量把他们保存出来，后面我们需要他们作为启动docker的参数。

```
GITLAB_SECRETS_DB_KEY_BASE=
GITLAB_SECRETS_OTP_KEY_BASE=
GITLAB_SECRETS_SECRET_KEY_BASE=
```

![](/images/posts/synology_gitlab_bk.png)

## gitlab升级路线

为了能够无缝升级兼容我们的数据和repo，需要遵守gitlab的升级路径：[https://docs.gitlab.com/ee/update/#upgrade-paths](https://docs.gitlab.com/ee/update/#upgrade-paths) 我们升级的时候，需要知道自己的数据是那个gitlab版本留下的，然后小心的选择自己下一个版本，经过几跳后可以到达自己目标的版本。之前是synology版本处理了这个事情，现在就需要自己去看了。这个没啥好说的，看路径节点，**注意备份数据**。

## 在synology7上搭建gitlab

先说nas上的配置，跟dsm6上一样，我们开一个文件夹名字叫docker，docker下建一个目录叫gitlab，这个目录如果你有之前备份，那直接使用，没有的自己建一个，作为我们gitlab的数据库了。![](/images/posts/synology_docker_dir.png)

接下来在套件里面找到docker，自己装上。装完在控制面板->终端机和SNMP->启动SSH功能，找个终端进入nas（过程不再赘述，估计要开gitlab的大部分都是程序员了。。）

完成上面操作的，我写了个脚本如下，把这个脚本复制下来放到docker目录下/volume1/docker（其实什么目录都可以，这个脚本也不管workspace）。**使用root运行脚本**

```bash
#!/bin/bash
set -x
set -e

# 基本配置，使用的是gitlab 13.12.2版本，需要修改版本的这里改下
## 1. docker images
GITLAB_DOCKER=sameersbn/gitlab:13.12.2
GITLAB_POSTGRESQL_DOCKER=sameersbn/postgresql:12-20200524
GITLAB_REDIS_DOCKER=sameersbn/redis:4.0.9-1

## 2. 查找目录，我们默认文件系统是/volueme1，如果不是，自己改下路径

### 2.0 find volume
if [ ! -d /volume1 ]; then
  echo "need at least volume"
  exit 1
fi
VOLUME=/volume1

### 2.1 docker_paths
DOCKER_POSTGRESQL_PATH=/var/lib/postgresql
DOCKER_GITLAB_PATH=/home/git/data

### 2.2 host_paths
if [ ! -d $VOLUME/docker/gitlab ]; then
  mkdir -p $VOLUME/docker/gitlab
fi

## 3. 几个docker的名字
synology_gitlab_name=synology_gitlab
synology_gitlab_postgresql_name=synology_gitlab_postgresql
synology_gitlab_redis_name=synology_gitlab_redis

## 3.1 这里使用跟synology之前的配置一样的配置，无需修改
HOST_POSTGRESQL_PATH=$VOLUME/docker/gitlab/postgresql
HOST_GITLAB_PATH=$VOLUME/docker/gitlab/gitlab

POST_DB_NAME=gitlab
POST_DB_USER=gitlab_user
POST_DB_PASS=gitlab_pass

## 3.2 这里是HTTP的端口和SSH的端口，自己改成需要的端口，URL改成自己的URL
HTTP_PORT=8000
SSH_PORT=30000
GITLAB_URL=localhost

## 3.3 这里是之前几个KEY_BASE，复制成前面备份下的KEY_BASE
GITLAB_SECRETS_DB_KEY_BASE=PLqOLXjGFKMXe2odwv8PstDN4dob5GBnDOJnEzlrShO7wE7gcNTy4traV_dqY+X7
GITLAB_SECRETS_OTP_KEY_BASE=VkewEafCFYUh6fvfDme_OdWXPPsJJcNBAbHwq2I3ujMVPlvs066TaPVob00eR14r
GITLAB_SECRETS_SECRET_KEY_BASE=feXZoHf9em0+EgBEbetpGEFWLX7oR5IKUWAqWYWhPLWB300kWkac9uKBzsdhI4U8

# docker pull

docker pull $GITLAB_DOCKER
docker pull $GITLAB_POSTGRESQL_DOCKER
docker pull $GITLAB_REDIS_DOCKER

# 如果没有创建这两个路径的，这里也会帮你创建下
mkdir -p $HOST_GITLAB_PATH
mkdir -p $HOST_POSTGRESQL_PATH

# 如果创建的权限不对，这里需要改下权限
# chown 1000:1000 -R $HOST_GITLAB_PATH
# chown 101:103 -R $HOST_POSTGRESQL_PATH

# start docker 

## 1. start postgresql container

docker run --name $synology_gitlab_postgresql_name -d \
    --env "DB_NAME=$POST_DB_NAME" \
    --env "DB_USER=$POST_DB_USER" \
    --env "DB_PASS=$POST_DB_PASS" \
    --env "DB_EXTENSION=pg_trgm,btree_gist" \
    --volume $HOST_POSTGRESQL_PATH:$DOCKER_POSTGRESQL_PATH \
    $GITLAB_POSTGRESQL_DOCKER

## 2. start redis container
docker run --name $synology_gitlab_redis_name -d \
    $GITLAB_REDIS_DOCKER

## 3. start gitlab container
docker run --name $synology_gitlab_name -d \
    --link $synology_gitlab_postgresql_name:postgresql --link $synology_gitlab_redis_name:redisio \
    --publish $SSH_PORT:22 --publish $HTTP_PORT:80 \
    --env "GITLAB_HOST=$GITLAB_URL" \
    --env "GITLAB_PORT=$HTTP_PORT" --env "GITLAB_SSH_PORT=$SSH_PORT" \
    --env "GITLAB_SECRETS_DB_KEY_BASE=$GITLAB_SECRETS_DB_KEY_BASE" \
    --env "GITLAB_SECRETS_SECRET_KEY_BASE=$GITLAB_SECRETS_SECRET_KEY_BASE" \
    --env "GITLAB_SECRETS_OTP_KEY_BASE=$GITLAB_SECRETS_OTP_KEY_BASE" \
    --volume $HOST_GITLAB_PATH:$DOCKER_GITLAB_PATH \
    $GITLAB_DOCKER
```



运行完脚本后，没有意外的话，gitlab就已经回来了，快去docker的container里看一下他们，访问下自己的URL熟悉的界面。

## 如果有问题的话。。

按说是没有问题的，但这个脚本是个人使用，大家都可以在这上面进行修改，也是阅读之前DSM6上面docker的配置自己改的脚本，如果有问题大家可以讨论啊
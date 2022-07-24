---
title: 你好小助手，帮我买瓶酱油--gitlab-runner搭建小记
mathjax: true
date: 2019-12-12 16:05:10
categories: 学习笔记
tags: gitlab
plink: gitlab_runner
---

人手还是不够啊，好多活都有积攒，随着开发的不断进行，越来越感觉要加上CI的流程了，至少稍微规范一下自己的开发，在这个人比机器贵的时代，能让机器干的事就还是让机器去干吧。

目的很简单，其实就是想稍微控制下代码质量，一旦出问题，能方便查找问题，而且对版本也做一下控制和管理。然后我还懒，只想自动化完成。这里给出最简单的例子，能够迅速让你从0到1。

## 用gitlab-runner自动完成项目的测试和发布

gitlab的CI需要gitlab-runner来完成，

完整的搭建gitlab-runner总共分三步。

### 1. runner的安装

服务器用的linux，其他系统需要参照官方文档，linux上安装有两种方法，一个就是直接下binary文件就可以执行了。另一个种方法就是用系统的包管理工具，先添加源

```
# For Debian/Ubuntu/Mint
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash

# For RHEL/CentOS/Fedora
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | sudo bash
```

接下来安装就好了

```
# For Debian/Ubuntu/Mint
sudo apt-get install gitlab-runner

# For RHEL/CentOS/Fedora
sudo yum install gitlab-runner
```

安装好后，需要对用户名和工作路径进行配置，先说一下推荐配置方法，即常规配置：

```
sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
sudo gitlab-runner start
```

这样整个gitlab-runner就算配置好了，剩下的就是到gitlab上去注册刚安装的gitlab-runner。

这里加一个插曲，如果不想用特定用户去运行gitlab,你也可以直接用root用户执行，其实就是把user换成root，可以免掉很多root带来的权限问题，尤其在你用docker的情况下。不过这样比较危险，很容易被人利用，执行些危险代码。

```
gitlab-runner install --working-directory /home/gitlab-runner --user root
sudo gitlab-runner start
```

### 2. runner的注册

runner有两种，一种是shared runner，需要管理员加到全局，各个项目都以使用，但他的config需要小心配置，因为大家都shared同一种config，另一种就是specify的runner，可以按照项目进行添加，方法都差不多，这里以specify runner为例简单介绍一下。

先打开项目->setting->ci/cd->runner（全局的就是管理界面->Overview->Runners），会看到url和token，先记下来。在服务器上执行
```
sudo gitlab-runner register
```
接下来会提示输入url和token，description（可以随便写，或者直接跳过），tag和执行方法。tag比较重要，需要记好，后面通过tag来指定哪个机器来执行ci，执行方法有很多，shell或者docker等等，根据情况选，一般选shell就可以。

完成注册后，回到gitlab刚才的配置界面，一个specify的runner就能看到了。

### 3. 编写.gitlab-ci.yml

这个文件需要放到项目目录下，其实就是gitlab执行的配置脚本，我觉得讲的再清楚也不如看个例子来的清晰。所以先给个示例，这个示例就是在shell执行下用的，tag需要修改成你的runner的tag。

```
stages:
  - env_prepare
  - build
  - deploy

cache:
  key: ${CI_BUILD_REF_NAME}
  paths:
    - output/

# 环境搭建
install_deps_job:
  stage: install_deps
  # 在哪个分支执行脚本
  only:
    - master
  script:
    - echo 'env init'
    - bash scripts/env.sh
  tags:
    - tag

# 编译
build_job:
  stage: build
  only:
    - master
  script:
    - echo 'build source'
    - bash scripts/build.sh
  tags:
    - tag

# 部署
deploy_job:
  stage: deploy
  only:
    - master
  script:
    - echo 'deploy'
    - bash scripts/install.sh
  tags:
    - tag
```

## 可能遇到的问题

我用的gitlab版本里面auto devops默认就打开了，在pipeline里面不管怎么弄就是，一直pending。。。问题可能有两个，一个就是tag没有写对，导致找不到机器，再一个就是你的auto devops开了，以管理员身份登陆gitlab，修改配置，把auto devops设置为disable就可以了。

最后附上gitlab-runner的官方文档： [https://docs.gitlab.com/runner/](https://docs.gitlab.com/runner/)
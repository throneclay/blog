---
title: 用vscode remote在github上愉快的开发hexo
date: 2019-05-08 12:13:28
categories: 学习笔记
tags: hexo
plink: vscode_github_hexo
mathjax: false
---

用hexo真不是新鲜事了，毕业后工作一直很忙，最近组织调整事情变少了，发现博客也登不上了，域名也过期了，只得重新来弄，又发现之前配置的时候什么记录也没留下。回想当时为了开发博客还得自己安装一堆node.js的东西，每次还要解决一圈依赖问题就头疼。为了一劳永逸的解决这些问题，正好把最近刚看的docker+vscode用起来，这里记录下这个过程也方便大家参考。这里假设已经熟悉hexo的开发或者已经有自己的hexo项目，不了解的先阅读: https://hexo.io/zh-cn/docs/

## vscode remote 

vscode remote还是非常新鲜的东西，这里也算尝鲜版了，现在只有vscode insider版本支持vscode remote，后面肯定会合入stable版本的，这里先以insider为参考，现在尝鲜的同学移步: https://code.visualstudio.com/insiders/

简单说这个东西解决了两个问题，在服务器上无痛的用vscode开发和在docker中无痛的用vscode开发，之前的解决方法要么vim/emacs或者sshfs挂盘，要么高级点的IDE也能支持ssh或者docker。前者感觉总归不够爽，后面其实也就是jetbrains啦，是收费的。vscode能以接近文本编辑器的速度提供ide的服务，还能免费提供这些功能出来还是非常良心的。

废话不多说了，在plugin里搜remote development，作者是Microsoft装上就可以了，里面主要包括三个部分，这里主要是用Remote-Containers，需要提前安装docker desktop，安装docker移步: https://www.docker.com/get-started ,安装好启动就可以了。

### vscode Remote-Containers docker

想要认真学习下如何使用的可以看官方的教程，我也是按照教程来的：https://code.visualstudio.com/docs/remote/containers 里面给了一些很好的例子，可以做一下参考：
```
git clone https://github.com/Microsoft/vscode-remote-try-node
git clone https://github.com/Microsoft/vscode-remote-try-python
git clone https://github.com/Microsoft/vscode-remote-try-go
git clone https://github.com/Microsoft/vscode-remote-try-java
git clone https://github.com/Microsoft/vscode-remote-try-dotnetcore
git clone https://github.com/Microsoft/vscode-remote-try-php
git clone https://github.com/Microsoft/vscode-remote-try-rust
git clone https://github.com/Microsoft/vscode-remote-try-cpp
```
跟我们相关的是在自己的```hexo init```的文件夹下创建一个文件夹```.devcontainer```，这个文件夹下描述了docker相关的一些配置文件，最重要的有```Dockerfile```和```devcontainer.json```，```devcontainer.json```文件里面记录了这个项目的docker名字，开放的端口，需要的vscode的插件等等，这里给出我的hexo的配置供参考
```
{
    "name": "Hexo blog",
    "dockerFile": "Dockerfile",
    "appPort": 4000,
    "extensions": [
    ],
    "postCreateCommand": "npm install; npm audit fix"
}
```

如果你有写好的Dockerfile可以直接用，hexo其实是基于node.js的应用，这里可以使用node的docker作为base，可以把yarn也升级到最新，避免可能出现的一些问题。这里也给出我的Dockerfile，这个也是根据微软给的例子改过来的

```
#-----------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE in the project root for license information.
#-----------------------------------------------------------------------------------------

FROM node:lts

# Configure apt
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && apt-get update \
   && apt-get -y install --no-install-recommends apt-utils 2>&1

# Verify git and process tools are installed
RUN apt-get install -y git procps

# Remove outdated yarn from /opt and install via package 
# so it can be easily updated via apt-get upgrade yarn

RUN rm -rf /opt/yarn-* \
   && rm -f /usr/local/bin/yarn \
   && rm -f /usr/local/bin/yarnpkg \
   && apt-get install -y curl apt-transport-https lsb-release \
   && curl -sS https://dl.yarnpkg.com/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/pubkey.gpg | apt-key add - 2>/dev/null \
   && echo "deb https://dl.yarnpkg.com/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
   && apt-get update \
   && apt-get -y install --no-install-recommends yarn

# install theme dependencies

RUN npm config set registry https://registry.npm.taobao.org && npm install -g hexo-cli

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=dialog
```

完成这两个文件的创建后，你的hexo的项目较之前只是多了一个文件夹及里面的两个文件，如下
```
.devcontainer
├── Dockerfile
└── devcontainer.json
...
```
在vscode里面```Cmd+Shift+p```输入```Remote-Containers: Open Folder in Container...```，找到hexo的项目文件夹，等一会就可以进入了，```Ctrl+` ```打开终端，输入```hexo s```服务器就能打开了，接下来在vscode里愉快的写博客吧。

## github静态网页相关的tricks
github能够host静态网页，这个福利里面其实情况和tricks还是很多的，这里都做一下记录。

### 使用username.github.io访问自己的博客（用户级的网页host）

github免费为所有用户提供了一种host自己静态网页的方式，repo名称是```[username].github.io```，对于我的github名是throneclay，所以我的repo就是```throneclay.github.io```，这个repo中直接使用master分支就可以，文件里必须要有index.html文件。

访问的地址和这个repo的名字是完全一样的，对于我的这个就是https://throneclay.github.io 直接访问就可以了。

### 使用单独repo访问自己的博客（repo级的网页host）

除了对于每个用户都有唯一的一个网页host之外，你创建的每个repo都免费提供了一个网页host，使用方法就是使用这个repo的```gh-pages```分支，这个host的目的是为了给每个repo都有展示自己的机会，当然你也完全可以开一个blog的repo，直接用这个repo的```gh-pages```分支。这个分支要求一样也是必须要有index.html文件。当然，我们完全可以用我们的hexo生成完整的整个静态文件```hexo generate```就能在public文件夹下生成所有你需要推到这个分支下的文件。

访问的方法是访问```https://[username].github.io/[repo]```，这里username就是你github的用户名，repo就是这个repo的名字。

### 使用自己的域名访问github的hexo博客

很多人都注册了自己的域名，可以将域名指向这个github的博客，让他看上去不那么像在github上一样。上面两种方法都可以修改域名。

#### username.github.io中自定义域名
使用CNAME文件放在master分支下的文件的一级目录下即可。CNAME的文件内容就一行，直接写你的域名或者分给这个网址的域名。CNAME文件放在source/下，就可以自动在generate的时候放到public文件夹下。

配置自己的dns，将分过去的域名使用CNAME类型指向[username].github.io就可以了，你也可以使用A类型，IP你可以ping [username].github.io得到。两种方法都可以。


#### repo的gp-pages中自定义域名

这个比较trick，不过也解出来了，还是使用CNAME文件，放在```gp-pages```分支下的文件的以及目录即可。CNAME的文件内容就一行，直接写你的域名或者分给这个网址的域名。CNAME文件放在source/下，就可以自动在generate的时候放到public文件夹下。

配置自己的dns，你可以使用A类型，IP你可以ping [username].github.io得到。这种方法亲测有效。

至此，撒花～
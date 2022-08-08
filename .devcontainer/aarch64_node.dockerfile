FROM arm64v8/node:18.7

ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && apt-get update \
   && apt-get -y install --no-install-recommends apt-utils git procps python && apt-get clean && rm -rf /var/lib/apt/lists/* 2>&1

RUN npm config set registry https://registry.npm.taobao.org && npm install -g hexo-cli

ENV DEBIAN_FRONTEND=dialog

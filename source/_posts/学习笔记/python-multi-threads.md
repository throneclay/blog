---
title: python多线程编程
mathjax: true
date: 2020-05-06 08:59:00
categories: 学习笔记
tags: python多线程
plink: py-multi-threads
---

多线程编程, 找到了一个非常简洁又有效的网站，本来这个事情简单说一下就可以知道了，找了好多介绍发现都会讲一大堆。。终于在这里找到了想要的东西，这里安利一波：[https://segmentfault.com/a/1190000016330017](https://segmentfault.com/a/1190000016330017)

为了防止网站未来失效或者内容看不到了，我摘出一部分放在这里，原文都在[https://segmentfault.com/a/1190000016330017](https://segmentfault.com/a/1190000016330017)

## python的条件锁

```
#条件变量实例
from threading import Condition

c=Condition()
def producer():
    while True:
        c.acquire()
        #生产东西
        ...
        c.notify()
        c.release()

def consumer():
    while True:
        c.acquire()
        while 没有可用的东西:
            c.wait()#等待出现
        c.release()
        #使用生产的东西
        ...
```


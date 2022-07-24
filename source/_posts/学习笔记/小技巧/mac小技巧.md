title: MacOS小技巧
mathjax: false
date: 2017-01-04 20:56:53
categories: 学习笔记
tags: Mac
plink: mac
---
因为公司给配了个苹果笔记本，我也开始慢慢转向苹果系统，不得不说，这个系统还是很好的结合了windows和linux的优势，bug也相对少一些，用起来感觉比较可靠。但是用的时候还是有一些地方感觉不爽，这里记录了一点平时用macbook的一些小技巧，方便以后查阅，以后也会慢慢更新新遇到的问题。

## 如何disable mac自动生产.DS_Store文件
mac打开文件夹会自动生产.DS_Store文件，当与其他系统共享文件系统时，这个东西变得非常犯人，解决办法找到了官网的一篇文章，10.11亲测可用
[https://support.apple.com/zh-cn/ht1629](https://support.apple.com/zh-cn/ht1629)
重启后瞬间世界变得干净很多。

## 如何加快sd卡在mac上的写的速度
因为有树莓派，经常会写sd卡，但mac上sd卡写的速度实在太慢了，这里找了个方法能够恢复mac上sd卡的写速。
mac笔记本插上SD后，都知道在/dev/diskX是其位置，其中X是一个数字，但你dd往SD卡写东西的时候速度就变得非常非常非常慢，大概200K左右，解决办法就是用/dev/rdiskX代替前面的位置，这个位置是用的raw数据，写的速度瞬间回到10M+。

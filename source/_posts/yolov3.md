---
title: yolov3论文详解理论篇
mathjax: true
date: 2020-2-10 03:45:23
categories: 深度学习
tags: yolo
plink: yolo-learning
---

就在写这篇文章的时候，yolo作者Joseph Redmon宣布停止CV研究，很可能yolov3将成为yolo系列的终局。想到这个感觉还是要好好写一下yolo啊。本来只想写一篇来介绍一下yolov3并记录下我是如何用到自己数据集上，写完后发现篇幅很长，遂拆成两部分，此篇为理论部分，实战部分见。

因为工作原因，需要找一个准确率还不错，而且推理速度较低的网络完成目标检测的能力，马上就想起来yolov3了。说来惭愧的是yolov3出来已经有些时间了，但却一直没有认真阅读。趁这次机会，翻出存放已久的yolo的论文，结合生成的自己的数据好好实践了一把。darknet的这个backbone效果还是非常好的，而且很快我就得到了想要的模型。

## 模型及实现

### 模型思想

yolo的核心思想是将物体检测问题转化成回归问题进行求解。最终的输出通过使用不同channel来进行区分，不同channel的信息经过特定的处理得到的物体位置，类别等信息。由于不需要proposal过程对候选框进行计算，yolo的速度可以说是非常快的，而且全网络都是由convolution操作构成，计算效率很高，对于图像尺寸的兼容性非常好。

### 模型结构

模型结构按照backbone和head来说，backbone就是特征提取网络，head部分就是针对检测的部分网络。

#### backbone

backbone是用的自己设计的darknet网络。

#### head

head部分采用回归的方法直接得出物体的位置和尺寸。计算的层也直接使用了convolution层来进行计算，简单粗暴效果还很好。


### detection header



### 总结

论文地址是 https://pjreddie.com/media/files/papers/YOLOv3.pdf
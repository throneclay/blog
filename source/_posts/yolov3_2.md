---
title: yolov3实战指南--训练自有数据集并完成推理实践
mathjax: true
date: 2020-03-05 11:05:40
categories: 深度学习
tags: yolo
plink: yolo-learning2
---

就在写这篇文章的时候，yolo作者Joseph Redmon宣布停止CV研究，很可能yolov3将成为yolo系列的终局。想到这个感觉还是要好好写一下yolo啊。本来只想写一篇来介绍一下yolov3并记录下我是如何用到自己数据集上，写完后发现篇幅很长，遂拆成两部分。此篇为实战部分，理论篇见。

## darknet框架

我这里使用的是并不是原版的darknet，而是一个fork的版本，[https://github.com/AlexeyAB/darknet](https://github.com/AlexeyAB/darknet)，此版本兼容原版darkent，并对于darknet的代码结构进行了升级，对于上手非常友好。

编译是非常容易的，需要装好cuda和cudnn，我用了conda来创建编译环境。（你没看错，是conda，conda同样能够管理常用的c++环境）

```
conda create --name darknet cmake=3.8.2
conda activate darknet
conda install opencv
```
完成后，这个环境下的cmake版本就应该没问题了。进入repo根目录，进行编译

```
mkdir build
cd build
cmake ..
make
make install
```
编译没问题后，在根目录下会出现darknet，后面主要就是用它来执行训练等任务。

## 数据准备及config目录结构

在这里其实有三组config，分散在两个文件夹中，梳理一下

### data names

这类config的目的是提供typeid对应的名字，扩展名为names。有很多文件是放在data文件夹下，可以去文件夹下看coco.names作为参考。当然这里面文件放的比较乱，cfg文件夹下也能找到，不过根据扩展名很容易知道是哪些文件。

### data config

这类config的目的是指定数据的属性和位置，也包括上面刚提到的names的文件路径。扩展名是data。绝大部分位于cfg文件夹下，举个例子```cfg/coco.data```

```
classes= 80
train  = /home/pjreddie/data/coco/trainvalno5k.txt
valid  = coco_testdev
#valid = data/coco_val_5k.list
names = data/coco.names
backup = /home/pjreddie/backup/
eval=coco
```
必须要写的是```classes, train, valid, names, backup```，```eval```指的用什么方式进行evaluate。train文件要指明你的训练数据集的绝对地址，如果是自己的数据集，label文件要放在训练路径的上一层label文件夹下。名字同训练用的图片，扩展名是txt(这些都不需要显示指明，数据集要这样准备)

### network config



## 推理部分的实现及inference



### onnx模型转换



### c++部分实现



## 上线性能及效果

这里的性能主要是指的

## 接下来

代码这里主要参考的是这个repo：https://github.com/AlexeyAB/darknet 之所以没选用原版的darknet是因为这个repo代码结构更易读，同官方代码基本兼容，而且有比较不错的文档和说明
模型上线需要转tensorrt，选用了onnx作为中间模型，主要参考了: https://gitlab.com/aminehy/YOLOv3-Darknet-ONNX-TensorRT
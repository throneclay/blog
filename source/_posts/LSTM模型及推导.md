title: LSTM模型完整前向和后向推导
mathjax: true
date: 2017-02-18 12:16:47
categories: 机器学习
tags: LSTM
plink: LSTM
---

LSTM是1997年提出来的一种RNN神经网络结构。由于其LSTM block的设计，使得LSTM能够较好的处理时间序列。实际的应用中，发现LSTM模型确实比想象的更有效果。然而这么好的网络，在网上居然难以见到完整的前向和后向过程，能找到的最好的资料也是简单的把前向的几个公式拿出来。这里就总结下LSTM的完整推导，方便像我这样需要写底层的人来参考。

## RNN基本模型
LSTM是一种RNN结构,对于RNN来说,基本的特征就是在不同时间步上有信息的传递,如下图所示.可以看到每个RNN结构的输入有两个(地一个可以认为一个输入为0),输出也有两个.每个RNN结构的输入为上一个时间的RNN输出,以及当前时刻的输入.输出一个作为网络输出,另一个传给了下一个时刻.

![](http://7xnn25.com1.z0.glb.clouddn.com/image/LSTM/RNNModule.png)

## 权重定义和LSTM memory block

我在写的时候,权重$W$一般都是矩阵,矩阵的行是作为神经元的数量,也就是$channelOut$,而矩阵的列数是代表的一个神经元的输入,其实就是输入数据的维度$channelIn$.

一个LSTM经典结构的示意图如下,这里为了解决梯度消失和梯度爆炸,用了CEC在时间步间传输.一个LSTM结构有输入门$i$,遗忘门$f$,输出门$o$还有个配合输入门的门$g$,$g$单独写,因为他其实算是输入门的一部分,其激活函数是$tanh$,其他几个门是$sigmoid$,内部通过CEC结构后,结合输出门得到输出.

![](http://7xnn25.com1.z0.glb.clouddn.com/image/LSTM/LSTMModule.png)

## 前向过程

前向过程可以分成这样三个过程,第一个就是门的激活.这里四个门的激活过程如下:

$$ i = sigmoid(W\_{ix} \* x  + W\_{ih} \* h\_{t-1} + b\_i) $$

$$ f = sigmoid(W\_{fx} \* x + W\_{fh} \* h\_{t-1} + b\_f) $$

$$ o = sigmoid(W\_{ox} \* x + W\_{oh} \* h\_{t-1} + b\_o) $$

$$ g = tanh(W\_{gx} \* x + W\_{gh} \* h\_{t-1} + b\_g) $$

![前向过程1](http://7xnn25.com1.z0.glb.clouddn.com/image/LSTM/LSTMforward1.png)

第二个过程是记忆传导过程:

$$ C\_t = C\_{t-1} \cdot f + i \cdot g $$

![前向过程2](http://7xnn25.com1.z0.glb.clouddn.com/image/LSTM/LSTMforward2.png)

第三个过程就是输出过程了.

$$ h\_t = o \* tanh(C\_t) $$

![前向过程3](http://7xnn25.com1.z0.glb.clouddn.com/image/LSTM/LSTMforward3.png)


## 后向过程

后想过程使用的算法这里是BPTT,跟一般的BP过程的区别就是在于Through Time部分,这里你可以展开来看整个网络,但简单说就是多了处理不同时间步间数据传输时产生的梯度的问题.

跟前向过程正好相反,这里先从输出开始进行.


## 优化

参数上主要的一个优化方法是在初始化时,设置大的遗忘门偏置,能够提高初始的记忆能力.这是在遗忘门提出来的一个老的技巧,但还是很有效的.

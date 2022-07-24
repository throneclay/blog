title: SNAS论文阅读笔记
date: 2019-7-18 16:09:11
categories: 深度学习
tags: SNAS
plink: SNAS
mathjax: true
---

从Google第一篇AutoDL的论文开始，在这方面的论文层出不穷，目测已经成为一个很活跃的研究方向，从一开始上千块TPU发展到现在一天内就能搜到SOTA的结果。NAS已经火了有段时间了，近期才有时间系统的看一下AutoDL相关的内容，SNAS是我最近看的一篇论文，这里做下简单的整理和总结，主要也是为自己留下一份知识储备，方便以后快速回顾。

# 简介

这篇论文主要有两个贡献点或者创新点，一个是使用Gumbel分布将离散的One-hot同连续可微空间联系起来，再一个是增加资源限制的计算，搜索时会同时考虑进计算量，参数和内存访问的代价进去。也是通过cell的方式搭建网络。

# 实现

由于没有官方的代码，很多实现也是看论文以及darts的代码结合理解的。论文附录里有个图画的非常好，顺带说一下基本的流程和结构。

这里i,j都表示的是node，也就是tensor，$O^n_{i,j}$表示的是连接i,j之间的op的第n个候选op，可以是conv或者pooling或者其他各种op的组合。$z^n_{i,j}$可以理解为各个候选op对于输出结果的权重，不同的实现这里的处理差异很大，本文是使用了gumbel softmax将离散的one-hot转变为连续的gumbel分布，从而可以进行梯度下降。gumbel softmax在很多论文中都有提到，是一个非常重要的连接离散和连续空间的桥梁。one-hot简单说就是一个0-1向量，只有一个值为1，其他都为0.

这样的一个从i到j的结构在darts里是被称为mixop，这里暂且也叫它mixop吧。mixop的候选可以有很多，但太多的候选会导致一个是训练时间变长，再一个就是显存不一定够用。这里通常都是延续enas里面对于这种候选op的设定。

## 搜索空间和网络采样

$O_{i,j}$代表连接node(i)和node(j)的候选op，对于$x_j$就可以表示成如下：

$$x_j=\sum_{i<j}Õ_{i,j}(x_i)$$

这里的$Õ_{i,j}$表示的是选中的operation。由于最终网络只会选定一个op来连接i和j，这里论文将上式改写成每个候选op的结果乘以一个one-hot的结构。

$$x_j=\sum_{i<j}Õ_{i,j}(x_i)=\sum_{i<j}Z^T_{i,j}O_{i,j}(x_i)$$

这个地方的$Z^T_{i,j}$可以看作是各个候选op的权重，权重的不同将会直接影响mixop的连接，也相当于改变了cell的结构。所以问题就由找到一个合适的网络结构变成找到一个合适的one-hot变量Z。

## 结构和op的参数学习

### cell结构

由于论文里也提到snas的cell结构和mixop候选同enas，darts这些网络很接近，所以这里就假设是一样的，顺便也说一下cell结构是什么样的。

cell主要有网络结构的共享和简化网络结构抽象的功能，一般将cell抽象为normal和reduction两种，对于normal的结构，输入和输出的channel数保持不变，对于reduction的cell，相当于过了一次stride=2，输出的channel数也会加倍。这些都是简单的一些设置，完全可以走不同的设置看看效果。

enas的cell有两个输入，两个输入为他之前的cells，cell的输出为内部的各个mixop的concat。然后继续接下一个cell，以此反复。

在所有cell的最前面会有stem的结构，这个结构简单的话可以用一个大kernel的conv，通常会对输入的image的channel调整到一个合适的数值。像resnet等的第一个conv都是7x7的大kernel卷积。

最后的部分通常就是head了，head可以实现很多种，如针对不同问题的分类的head，或者可以接detection的head等等，不过backbone部分就是使用snas或者其他方法找到的网络结构了。

### 参数学习方法, Gumbel Softmax

继续前面的搜索最优one-hot变量$Z_{i,j}$的过程。由于$Z$是一个离散的变量，梯度到了这一层没有办法传播，为了能够将搜索$Z$的过程，这里让$Z$成为gumbel-softmax的输出，表达式如下

$$Z^k_{i,j}=f_{\alpha_{i,j}}(G^k_{i,j})
=\frac{exp((log\alpha^k_{i,j} + G^k_{i,j})/\lambda)}{\sum^n_{l=0}exp((log\alpha^l_{i,j} + G^l_{i,j})/\lambda)}$$

这一层很像softmax的表达式，多了$G^k_{i,j}$和$\lambda$。

$G^k_{i,j}=-log(-log(U^k_{i,j}))$是第k个gumbel随机变量，这里$G$就是服从gumbel分布的变量了，$U^k_{i,j}$就是第k个均匀分布的随机变量，$U$就是服从均匀分布。

$\lambda$被称为softmax的温度，这个值越小，输出的$Z^k_{i,j}$就越接近一个one-hot的输出，所以可以猜到一开始的温度是一个相对较大的值，随着搜索的进行，温度会逐渐变小，直到$Z$完全变为one-hot的结果。论文里没有提到如果对$\lambda$进行调整，我试了一些方法，大概$\lambda$从5.0或10.0开始下降，大概到1e-3基本可以认为就是one-hot的变量了。

这里面还有一个变量$\alpha$就是需要训练得到的结构参数了，这个值直接影响输出的one-hot的值，既然有两种cell，可以理解为也有两组$\alpha$的值了，一组是normal的，一组是reduction的。

### credit assignment

文中提到这个地方感觉像是被reviewer问到了，为了同enas做对比，主要是抓住强化学习难以及时将reward分配到每个mixop上面，而snas因为将离散的选择问题抽象为连续的gumbel分布，所以每个mixop上的梯度就可以当作其reward，当然这是把这个过程同强化学习的过程做对比，但所有走stochastic的方法都有这方面的便利，这里也就不展开讨论了。

## 资源限制

文中使用了一些对op的计算量和资源使用的抽象，通过对这些资源花费cost的优化达到资源限制的效果，这里记录下论文里的方法。

论文中记录了三个主要的候选参数，分别是1)参数量，2)float操作数、3)memory访问。参数量相当于计算weights部分的数值，float操作数按照各个op计算的过程估计，memory访问文中叫MAC，是输入和输出的尺寸。有了这些数值后，加上一个系数就。之前的loss就直接加上这个cost了。

$$E_{Z~p_\alpha(Z)}[L_\theta(Z)+C(Z)]=E_{Z~p_\alpha(Z)}[L_\theta(Z)+E_{Z~p_\alpha(Z)}[C(Z)]]$$

这个cost也是跟前面的one-hot相关的一个值，因此对于loss函数整体的优化还是会落到对$Z$的优化上，就和前面接起来了。

$$C(Z)=\sum_{i,j}C(Z_{i,j})=\sum_{i,j}Z^T_{i,j}C(O_{i,j})$$

论文里处理的比较粗暴，也没太考虑不同op差异巨大的问题，这里可以使用一些方法做一定的normalize，可能效果会更好

# 效果

这里简单展示一下论文里提到的效果。

cifar10的实验结果

| Architecture | Test error | Params(M) | Search Cost (GPU days)|
| --- | --- | --- | --- |
| snas(single-level) + mild constraint | 2.98 | 2.9 | 1.5 |
| snas(single-level) + moderate constraint | 2.85  | 2.8| 1.5 |
| snas(single-level) + aggressive constraint | 3.10 | 2.3| 1.5 |

imagenet的实验结果

| Architecture | Test error(top1) | Test error(top5) | Params(M) | Search Cost (GPU days)|
| --- | --- | --- | --- | --- |
| snas(single-level) + mild constraint | 27.3 | 9.2 | 4.3 | 1.5 |

# 思考

snas上能够看到enas，darts的影子，也能嗅到MNAS和更之后的FBNet的味道，这里重点也记录一下这几篇工作的一些要点，为进一步阅读抛砖引玉。

## ENAS，DARTS

enas感觉是第一篇把nas推向实际一点的工作，从enas开始，网络搜索开始逐渐平民化，不再是用超多GPU或TPU怼出来的离实际很远的东西。enas里面的cell，和mixop的方法到现在都一直沿用，enas的代码也开源，对于推动nas发展起了很重要的作用，enas是使用强化学习的一种方法，有很多思想可以借鉴。

darts是这两年把网络搜索压缩到单卡单天的一个工作，代码也是开源的，使用的也是基于梯度的方法，沿用了很多enas的设置，也采用cell和mixop的方法对网络搜索建模，之前跑过他们的代码，对于想快速学习是非常不错的选择。

## MNAS，FBNet

MNAS和FBNet还有很多这方面的工作，属于将实际落地中非常看中的延时和模型尺寸考虑进去，不仅注重网络搜索过程，也将实际手机上运行的延时结果反馈给网络搜索过程。

SNAS是一篇承上启下的论文，现在基于梯度的方法大有增长的趋势，到了darts和snas基本已经到了1个GPU day的水平，使用多目标优化的方法如把硬件和op的限制考虑进网络搜索中的也在慢慢兴起，未来这种类型的结合也肯定会层出不穷，如果这个时候想切入nas的领域，snas是一篇不错的切入点，缺点就是作者没有开出源码，如果有源码那就更好了。

至此，撒花～
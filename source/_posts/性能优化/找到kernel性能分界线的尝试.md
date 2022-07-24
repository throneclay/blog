title: 找到kernel性能分界线的尝试
date: 2019-07-18 9:20:59
categories: 性能优化
tags: kernel开发
plink: kernel_split
mathjax: true
---

实现一个大而美的kernel往往是不现实的，在各种硬件上针对特定case下的kernel很容易能够突破针对通用case实现的kernel，所以实现的kernel在某些case下表现好，某些case下表现的就不是那么好，如何快速正确的找到各个kernel的性能曲线，既能更好的了解这个kernel的优势和不足，也能为后续kernel选择重要的参考。这里的这篇就是针对kernel选择而做的一个尝试。

这里做了两个工作，第一个是刷了一下之前写的两组conv在常见case下的各种时间数据，后面给出头部信息，第二个是用sklearn的一些Manifold方法尝试对这些数据进行分割，这里选了两种看上去效果不错的方法，在这里对比一下。

这里给了两个perf文件，如果只有一个就用一个就好了，注释掉第二个，csv的文件头如下， type我这里写的是gemm或者direct，这两个是自己实现的kernel，cudnn代表直接跑的cudnn的kernel：

```
input_num,in_channels,out_channels,height,width,kernel_h,kernel_w,pad_h,pad_w,stride_h,stride_w,dilation_h,dilation_w,group,type,latency,
```

代码给出如下：

```
import csv
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import offsetbox
from sklearn.manifold import TSNE
from sklearn import (manifold, datasets, decomposition, ensemble, discriminant_analysis, random_projection)
from mpl_toolkits.mplot3d import Axes3D

self_perf = list()
cudnn_perf = list()

perf_file1 = "/Users/zhangshuai20/workspace/direct.csv"
with open(perf_file1, "rb") as csvfile:
    spamreader = csv.reader(csvfile, delimiter=',')
    for row in spamreader:
        if row[14] == 'type':
            continue
        if row[14] != 'cudnn':
            self_perf.append(row)
        else:
            cudnn_perf.append(row)

perf_file2 = "/Users/zhangshuai20/workspace/gemm.csv"
with open(perf_file2, "rb") as csvfile:
    spamreader = csv.reader(csvfile, delimiter=',')
    for row in spamreader:
        if row[14] == 'type':
            continue
        if row[14] != 'cudnn':
            self_perf.append(row)
        else:
            cudnn_perf.append(row)

feature_data = list()
self_label = list()
cudnn_label = list()

for row in self_perf:
    row_list = list()
    for r in row[:13]:
        row_list.append(int(r))
    feature_data.append(row_list)
    self_label.append(float(row[15]))

for row in cudnn_perf:
    cudnn_label.append(float(row[15]))

# print data

print('Computing t-SNE embedding')
# tsne = TSNE(n_components=2, init='pca', random_state=0)
# result = tsne.fit_transform(feature_data)

hasher = ensemble.RandomTreesEmbedding(n_estimators=100, random_state=3,                             max_depth=3)
X_transformed = hasher.fit_transform(feature_data)
pca = decomposition.TruncatedSVD(n_components=2)
result = pca.fit_transform(X_transformed)

fig = plt.figure()

idx = 0
count = 0
ratio = 0

## method 1 =======================================

ax = plt.subplot(111)
for item in result:
    if self_label[idx] < cudnn_label[idx]:
        ax.scatter(item[0], item[1], marker='*', c = 'r')
        ratio += self_label[idx] / cudnn_label[idx]
        count += 1
    else:
        ax.scatter(item[0], item[1], marker='+', c = 'orange')
    # print self_label[idx] < cudnn_label[idx]
    idx = idx + 1

## method 2 =======================================

# ax = plt.subplot(projection='3d')
# for item in result:
#     if self_label[idx] < cudnn_label[idx]:
#         count = count + 1
#         ratio += self_label[idx] / cudnn_label[idx]
#         ax.scatter(item[0], item[1], self_label[idx], marker='*', c = 'blue')
#     else:
#         ax.scatter(item[0], item[1], cudnn_label[idx], marker='+', c = 'orange')
#     idx = idx + 1
# ax.set_zlabel('Z')
# ax.set_ylabel('Y')
# ax.set_xlabel('X')

## ===============================================
plt.show()
print count
print "sass kernel is better than cudnn about: " + str(ratio / count)
print "better than cudnn % : " + str(float(count) / float(len(cudnn_label)))
```

我这里实现了两组不同的kernel，分别同cudnn进行对比，来指引我们什么时候选用什么样的kernel，红色是自己实现的kernel速度快于cudnn，黄色是cudnn的快于自己实现的kernel

![kernel性能demo1](/images/kernel_plot1.jpg)

![kernel性能demo2](/images/kernel_plot2.jpg)
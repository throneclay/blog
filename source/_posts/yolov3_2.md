---
title: yolov3实战指南--训练自有数据集并完成TensorRT推理实践
mathjax: true
date: 2020-03-05 11:05:40
categories: 深度学习
tags: yolo
plink: yolo-learning2
---

就在写这篇文章的时候，yolo作者Joseph Redmon宣布停止CV研究，很可能yolov3将成为yolo系列的终局。想到这个感觉还是要好好写一下yolo啊。本来只想写一篇来介绍一下yolov3并记录下我是如何用到自己数据集上，写完后发现篇幅很长，遂拆成两部分。

此篇为目的是要记录如何使用自己的数据集训练yolov3模型，并**最终得到能够上线的检测模型**。这里训练不是学术目的，而是面向生产环境。理论篇见[http://blog.throneclay.top/2020/02/19/yolo-learning/](http://blog.throneclay.top/2020/02/19/yolo-learning/)。

## darknet框架

直接使用原版代码也可以，但我这里使用的是并不是原版的darknet，而是一个更容易阅读的fork版本，[https://github.com/AlexeyAB/darknet](https://github.com/AlexeyAB/darknet)，此版本兼容原版darkent，并对于darknet的代码结构进行了升级，对于上手非常友好。

编译是非常容易的，需要装好cuda和cudnn，我用了conda来创建编译环境。（你没看错，是conda，conda同样能够管理常用的c++环境）。用conda可以轻松的在不同cmake版本中间穿梭，非常方便。

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

在这里其实有三组config，分散在两个文件夹中，分别是记录训练数据的config，扩展名为data。记录训练类别和名称的config，扩展名为names和网络的config，扩展名为cfg，内容比较直白，接下来分步骤说一下全流程。这里假设你的数据集为obj，网络名称也就叫做yolov3-obj了。

### 1. 创建网络cfg

复制一下cfg/yolov3.cfg到cfg/yolov3-obj.cfg，修改文件里的内容如下
```
batch=1              ==>  batch=64
subdivisions=1       ==>  subdivisions=16
max_batches = 500200 ==>  max_batches = (类别数 x 2000，如一共3类就是6000)
steps=400000,450000  ==>  steps=(上面max_batches的80%,, 90%，如4800,5400)
width=416            ==>  width=(网络输入图像大小，32的倍数，可选，不一定要修改这个参数，内部会自动resize)
height=416           ==>  height=(网络输入图像大小，32的倍数，可选，不一定要修改这个参数，内部会自动resize)
classes=80           ==>  classes=(类别数量， 即前面max_batches乘的类别数量)
filters=255          ==>  filters=(classes + 5) x 3 都是在[convolutional]，共有3处，需要都修改一下，这个filter是在[yolo] layer的上一层。
```

### 2. 创建obj.names

创建data/obj.names文件，一行有且只有一个对应的object name。最后输出也会按照这个顺序。

### 3. 创建obj.data文件

创建cfg/obj.data，内容如下

```
classes= 3
train  = train/train.txt
valid  = train/test.txt
names = data/obj.names
backup = train/backup/
```

解释一下，classes是上面提到的类别数，train指的训练数据的list，后面第6步会再说，位置放在darknet下新建一个train文件夹下，或者你可以修改其他名字，valid就是验证用的list，names指第2步创建的obj.names，backup是darknet存放训练产生的wegiths的位置，先把位置放到train/backup中，这里就需要提前把这里用到的文件夹创建出来

```
mkdir train
mkdir train/backup
```

### 4. 准备训练用的图片文件

准备下要训练的图片，假设放到/home/data/train_jpg文件夹下，我用的jpg文件的格式，其他格式没有测试过。

### 5. 准备label文件

继续沿用上面的设置，训练图片位于/home/data/train_jpg下，那么label文件就要放到/home/data/labels文件夹下。有多少训练用的图片就要有对应的label文件，名字和train_jpg下的图片一样，扩展名为txt，举个例子如果你有一张训练图片/home/data/train_jpg/0001.jpg就需要一个label在/home/data/labels/0001.txt，文件的格式如下：
```
<object-class> <reg_x_center> <reg_y_center> <reg_width> <reg_height>
```

举个例子，内容需要是像下面这种的东西：

```
0 0.003852 0.928161 0.007704 0.143678
1 0.537365 0.370690 0.008475 0.201149
1 0.771957 0.103448 0.009245 0.206897
1 0.857858 0.100575 0.008475 0.201149
1 0.994992 0.522989 0.008475 0.195402
0 0.996533 0.787356 0.006934 0.160920
```

**label的设置还是很重要的**，这里解释一下，文件中一行代表一个object，每行有5列，用空格进行分割，第一个数是整数，代表之前names文件中的第几个类别，剩下的4列为回归后的x中心，回归后的y中心，回归后的width和回归后的height。**其回归计算公式如下**:

```
reg_x_center = <absolute_x_center> / <image_width>
reg_y_center = <absolute_y_center> / <image_height>
reg_width = <absolute_width> / <image_width>
reg_height = <absolute_height> / <image_height>
```

每个值都不会大于1的，如果你有算出大于1的地方就肯定算错啦。

### 6. 准备train.txt

沿用上面的设置，训练图片都位于/home/data/train_jpg下，执行下面命令生成train.txt文件，valid.txt文件同理。valid.txt其实就是用来在训练的时候验证效果的，一般就是从train文件中分出一小部分用于valid。label文件不需要设置，darknet会根据train的文件名，自己去找对应的label文件。

```
find /home/data/train_jpg/ > train/train.txt
find /home/data/valid_jpg/ > train/valid.txt
```

### 7. 下载预训练的weights

为了能够让训练过程更顺畅，我们使用预训练的weights来加强效果，因为我们选用了yolov3.cfg，使用下面这个预训练weights
```
wget https://pjreddie.com/media/files/darknet53.conv.74
```

### 8. 开始训练

上面步骤确认没有问题后，执行下面命令，训练就开始了

```
./darknet detector train data/obj.data cfg/yolov3-obj.cfg darknet53.conv.74
```
运行这句命令后，会启动可视化的一个界面，如果你不想要可视化的界面，运行下面这句
```
./darknet detector train data/obj.data cfg/yolov3-obj.cfg darknet53.conv.74 -dont_show 
```

训练需要点时间，如果出现nan，只要不是在loss里面不用太担心，如果报错，请检查上面1-7步的内容。

## TensorRT推理部分的实现及inference

这里最后使用了TensorRT的C++部分API，实际上也用了python部分API。经过训练在train/backup下已经得到了你要的模型。

这里我们换用另一个项目继续得到TensorRT可用的模型[YOLOv3-Darknet-ONNX-TensorRT](https://gitlab.com/aminehy/YOLOv3-Darknet-ONNX-TensorRT)

我使用的是python2.7，虽然已经不更新了，但用python2.7加这个项目已经完全足够了，如果使用python3，可以多阅读下项目的README.md

```
conda create --name yolo_trt python=2.7
conda activate yolo_trt
python2 -m pip install -r requirements.txt
```

项目应该就算布好了。接下来我们装一下TensorRT的环境，为了兼容线上的版本，我还是用的TensorRT5，新的TensorRT应该跟这个差不多。到[https://developer.nvidia.com/tensorrt](https://developer.nvidia.com/tensorrt)官网下载TensorRT，为了方便安装和使用，我们还是下载他的tar package。

解压出来在home下的.bashrc文件中增加下面两句话就算安装完成了，我直接放我home下了，需要设置cudnn的LD_LIBRARY_PATH，否则会提示cudnn找不到。如果愿意也可以把TensorRT/bin放到PATH里，这里就不放了。
```
export CUDNN_ROOT=/usr/local/cudnn-7.6.0-cuda10.1_0
export LD_LIBRARY_PATH=/home/zhangshuai/TensorRT-5.1.2.2/lib:$CUDNN_ROOT/lib:$LD_LIBRARY_PATH
```

source一下.bashrc，执行TensorRT-5.1.2.2/bin/giexec，没问题的话就可以看到giexec的help提示。

### 安装TensorRT的python环境

我这里是python2.7的，因此安装2.7对应的TensorRT，先安装两个依赖，然后进python文件夹下安装对应的TensorRT。

```
conda activate yolo_trt
pip install TensorRT-5.1.2.2/uff/uff-0.6.3-py2.py3-none-any.whl
pip install TensorRT-5.1.2.2/graphsurgeon/graphsurgeon-0.4.0-py2.py3-none-any.whl
pip install TensorRT-5.1.2.2/python/tensorrt-5.1.2.2-cp27-none-linux_x86_64.whl
```

安装没问题可以测试一下，不报错说明已经安装成功。

```
python -c "import tensorrt"
```

### onnx模型转换

[YOLOv3-Darknet-ONNX-TensorRT](https://gitlab.com/aminehy/YOLOv3-Darknet-ONNX-TensorRT)这个项目其实写的已经很好了，主要就是两个python：yolov3_to_onnx.py和onnx_to_tensorrt.py，其实我们只用第一个文件就可以转换获得onnx的模型，第二个python能够进一步得到trt的engine，trt的engine不是很好用，对于TensorRT的版本，卡的型号都有绑定，不过可以用第二个文件检查第一步产生的onnx模型是不是对的。

#### 1. yolov3_to_onnx.py转换onnx模型
把之前backup训练得到的yolov3_all_final.weights放到项目路径下，修改weights_file_path指向你的weights,默认的参数就是416x416对应的参数，在项目路径下创建engine文件夹，在之前创建的yolo_trt下直接运行

```
python yolov3_to_onnx.py
```
不出问题的话，engine下就多了一个onnx的模型

#### 2. onnx_to_tensorrt.py

这个文件可能需要修改一下output_shape，我这里修改了
```
output_shapes = [(1, 255, 19, 19), (1, 255, 38, 38), (1, 255, 76, 76)]
  ==>  output_shapes = [(1, 51, 13, 13), (1, 51, 26, 26), (1, 51, 52, 52)]
```
其实运行一下根据报错也很容易看到。
修改后确认下test文件夹是否存在，你可以放入一些自己的测试图片，运行就能看到模型从load到inference的过程了，results文件夹下会得到这次的一些结果。
```
python onnx_to_tensorrt.py
```

至此，全流程算是走了一遍了，但我们的目的是上线C++的项目，所以还要继续。

### c++部分实现

C++部分分为两部分，一部分就是load图像，跑TensorRT的过程，可以参考TensorRT/samples/trtexec代码。这里就不再多说什么，最后你会获得三组输出，处理的方法都是一样的，这里写了个函数，应该可以帮你理解和处理yolov3的输出。这个函数可以处理一个输出的box结果，最后的结果就是这三组输出的总和。

```
__inline__ float sigmoid_f(const float& value) {
  return 1.f / (1.f + expf(-value));
}

void TrafficLightDetector::get_detection_bbox(
    std::vector<std::vector<float> > &bbox, // the output of this function
    int batch_index,
    const float* output_data, // tensorrt output data on cpu
    int channel, // output data channel
    int height, // output data height
    int width, // output data width
    int image_origin_height, // image origin height 416
    int image_origin_width, // image origin width 416
    std::vector<std::vector<int> > anchor_mask, // {{6, 7, 8}, {3, 4, 5}, {0, 1, 2}};
    std::vector<std::vector<float> > anchors, // {{10, 13}, {16, 30}, {33, 23}, 
                                              // {30, 61}, {62, 45}, {59, 119},
                                              // {116, 90}, {156, 198}, {373, 326}};
    int output_index, // anchor_mask index
    float obj_thresh = 0.3f // score threshold
    ) {

  int tensor_idx = output_index;
  output_data += batch_index * channel * height * width;
  int size = height * width;
  int stride = height * width;

  for (int i = 0; i < size; ++i) {

    int max_anchor = -1;
    int max_index = -1;
    float max_confidence = -1.f;

    for (unsigned int anchor_i = 0; 
        anchor_i < anchor_mask[tensor_idx].size(); ++anchor_i) {

      int max_index_ = -1;
      float max_confidence_ = -1.f;

      float confidence = sigmoid_f(output_data[
          anchor_i * (5 + classes) * stride + 4 * stride + i]);

      for (int c = 0; c < classes; ++c) {
        float bbox_confidence = confidence * sigmoid_f(output_data[
            anchor_i * (5 + classes) * stride + (5 + c) * stride + i]);

        if (bbox_confidence > obj_thresh) {
          if (bbox_confidence > max_confidence_) {
            max_confidence_ = bbox_confidence;
            max_index_ = c;
          }
        }
      }

      if (max_confidence_ > max_confidence) {
        max_confidence = max_confidence_;
        max_index = max_index_;
        max_anchor = anchor_i;
      }
    }

    // found bbox
    if (max_index != -1) {
      float grid_x = (float)(i % width);
      float grid_y = (float)(i / width);
      std::cout << "max_index = " << max_index
        << " max_anchor = " << max_anchor
        << " i = " << i
        << " grid_x = " << grid_x <<
        " grid_y = " << grid_y << std::endl;

      // compute bbox information
      float box_x = sigmoid_f(output_data[
          max_anchor * (5 + classes) * stride + i]);
      float box_y = sigmoid_f(output_data[
          max_anchor * (5 + classes) * stride + stride + i]);
      float box_w = expf(output_data[
          max_anchor * (5 + classes) * stride + 2 * stride + i]);
      float box_h = expf(output_data[
          max_anchor * (5 + classes) * stride + 3 * stride + i]);
      box_w *= anchors[anchor_mask[tensor_idx][max_anchor]][0];
      box_h *= anchors[anchor_mask[tensor_idx][max_anchor]][1];
      std::cout << "box_x = " << box_x
        << " box_y = " << box_y
        << " box_w = " << box_w
        << " box_h = " << box_h << std::endl;

      // regression
      box_x += grid_x;
      box_y += grid_y;
      box_x /= (float)width;
      box_y /= (float)height;
      box_w /= (float)resize_width;
      box_h /= (float)resize_height;
      box_x -= box_w / 2.f;
      box_y -= box_h / 2.f;
      box_x *= (float)image_origin_width;
      box_y *= (float)image_origin_height;
      box_w *= (float)image_origin_width;
      box_h *= (float)image_origin_height;

      bbox.push_back({(float)batch_index, box_x, box_y, box_w, box_h,
          max_confidence, (float)max_index});
    }
  }
}
```

## 上线性能及效果

整体跑下来我这边性能还是相当不错的，2080TI，10ms以内。后面有时间再更新一下其他卡的时间。

## 接下来

代码这里主要参考的是这个repo：https://github.com/AlexeyAB/darknet 之所以没选用原版的darknet是因为这个repo代码结构更易读，同官方代码基本兼容，而且有比较不错的文档和说明
模型上线需要转tensorrt，选用了onnx作为中间模型，主要参考了: https://gitlab.com/aminehy/YOLOv3-Darknet-ONNX-TensorRT
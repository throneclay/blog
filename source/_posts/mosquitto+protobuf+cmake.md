---
title: mosquitto+protobuf实战
mathjax: true
date: 2020-02-17 15:55:44
categories: 学习笔记
tags: mosquitto
plink: mqtt_protobuf
---

因为前段时间急需一个能够搞定通信问题，所以调研了一下，找到了mosquitto适配后效果非常好，但他的例子比较少，我写了一个简单的示例，通信采用了mqtt协议，mosquitto搭建的服务器，通信的内容采用了protobuf进行序列化和反序列化，基本能够应付常见的各类情况。

mqtt是一种轻量级的通信协议，基于服务器和客户端，能够订阅和发布消息。网上的介绍非常多，mqtt能够很好的胜任信息通信任务，支持的平台也非常广泛。mqtt功能强大，占资源少，特别适合在车上进行一些通信和数据的传输。利用protobuf对数据进行封装，既能很好的完成编解码，又能广泛支持不同设备。网上的教程其实很多，但都没有示例代码，这里顺便写了个小的example，能方便学习和开发。

mosquitto是mqtt的一种开源实现，之所以用mosquitto是因为他非常小，而且很好编译，官网在这里：[https://mosquitto.org/](https://mosquitto.org/)

代码的repo在这里：[https://github.com/eclipse/mosquitto](https://github.com/eclipse/mosquitto)

这里分成三部分介绍，1、先介绍服务器的搭建，客户端可以用mosquitto自带的工具，2、介绍c++段的mosquitto，3、简单介绍一下python上的paho。

## 1、mosquitto服务器的搭建和配置

服务器这里使用了阿里云的服务器，mosquitto默认需要1883的TCP入端口。需要在安全策略里设置一下。端口当然也可以选其他端口进行配置。

服务器终端安装mosquitto和mosquitto-clients，后者是一些客户端，方便我们测试用。
```
sudo apt install mosquitto mosquitto-clients
```

安装好后看一下服务是否开启，没开启把status换成start再执行一遍。
```
sudo systemctl status mosquitto
```

此时基本的服务器就搭好了。。是不是很简单，先测试一下，开两个服务器的终端，一个执行下面的命令来监听
```
mosquitto_sub -h localhost -p 1883 -t "demo/1"
```

其中-h为服务器的地址，-p指明端口，-t表示监听的topic。

这时我们再开一个新的终端，执行一下发布
```
mosquitto_pub -h localhost -p 1883 -t "demo/1" -m "test"
```

这里多了一个-m 表示消息的内容，是字符串格式的。只要topic能够匹配，监听那边就可以收到消息。

### 这里多说一下关于topic

topic用"/"进行划分，支持通配符，有单层通配符和多层通配符。

"+"为单层通配符，当写成"demo/+"时，能且只能通配"demo/任何消息"，只能代表一层的消息，也可以这样写"demo/+/test"。注意当写为"demo/+"时，不能匹配"demo"

“#“为多层通配符，能够匹配任意多层的topic（包括0层），只能用来结尾。可以写成"#"或"demo/#"。

### 服务器配置

配置文件在/etc/mosquitto/mosquitto.conf，不过我们一般不修改这个文件，而是把.conf文件放到/etc/mosquitto/conf.d/下，这里举个配置端口的例子，在/etc/mosquitto/conf.d/下，新建port.conf文件，输入下面内容，可以让mosquitto服务器同时监听1885,1886,1887端口，并且把1886的协议为mqtt，1887端口协议为websockets，各取所需。
```
port 1885
listener 1886
protocal mqtt
listener 1887
protocal websockets
```

也可以配置密码，通过用户名密码更加安全
```
sudo mosquitto_passwd -c /etc/mosquitto/passwd username
```

会提示输入密码，这里加上-c 是让他生成密码文件，不加-c 代表已有文件，原地增加用户

接着在/etc/mosquitto/conf.d/下新建passwd.conf输入下面命令
```
allow_anonymous false
password_file /etc/mosquitto/passwd
```

意思就是字面意思。。重启服务
```
sudo systemctl stop mosquitto
sudo systemctl start mosquitto
```

接下来就需要带上用户名密码来发布和监听topic了。

## 2、c++部分的mosquitto+protobuf，完成消息的订阅和发布

这部分全部代码都在我的repo里，见文章最后，编译一个客户端的库写了个脚本，就不用自己去找源码包，自己编译了，项目基于cmake的，需要确保自己已经安装protobuf了，剩下的就是编译了。

这部分全部代码都在我的repo里，见文章最后，编译一个客户端的库写了个脚本，就不用自己去找源码包，自己编译了，项目基于cmake的，需要确保自己已经安装protobuf了，剩下的就是编译了。

代码我放到github上了（见最后）简单介绍一下代码结构和运行方法。

proto目录下放有proto文件，message里面的东西就是要传输的内容，因此两边都要能够看到这个proto的内容。

src下有两个文件，pub_simple.cpp 和 sub_callback.cpp文件，分别是用来发布和订阅topic的代码。其实mosquitto的使用方法很多，也可以使用他的c++库，通过继承来得到更简单的接口，但这里我还是选用c的接口，自己封装类来使用，原因是这样灵活性更高。

订阅部分代码使用了call_back的方式，没有选用simple，call_back更灵活一些，而pub选用了simple的结构，其实发布的时候你已经很确定这个使用要发布消息，所以simple就足够了。

clone下代码后进入scripts会自动帮你编译一个mosquitto的库，方便移植，不管是在树莓派，还是服务器上，都可以轻松得到需要的库。

按照github上提示的方法运行，不出意外你已经拥有了足够起步的mosquitto的example

## 3、paho，简单介绍一下

paho是多平台多语言的客户端的库，主要就是支持的语音多，而且里面有各种示例，接口大家都差不多，官网见这里。一般我们的用法就是mosquitto搭建服务器，客户端如果用其他什么语言就选用paho了，c/c++的paho感觉比较费劲，还不如直接用mosquitto来的舒服，见第二部分，看c/c++的用法。

[https://www.eclipse.org/paho/](https://www.eclipse.org/paho/)

paho的example比较多，文档写的也好，下到python的代码后，里面就有example。直接看代码比在这里看我啰嗦效率高得多，我就不再赘述了。。

## 最后

完整的c++mosquitto客户端使用protobuf进行消息的发布和订阅的代码在这里：

[https://github.com/throneclay/mosquitto_example](https://github.com/throneclay/mosquitto_example)
title: ipython notebook服务器的搭建
date: 2015-11-12 21:16:57
categories: 学习笔记
tags: ipython
plink: ipythonNotebookServer
mathjax: true
---

## ipython介绍和安装
ipython是一个很好用的python交互式shell，支持自动补全，语法高亮，代码调试，支持bash命令，在linux下使用的很是开心。本来像python这样的语言，很适合在shell中交互式编程，配合ipython来使用，很方便。
在Fedora下安装可以直接使用yum
```
sudo dnf install ipython -y
```
ipython安装成功后可以直接输入ipython来启动，当然功能实在太多，这里介绍几个比较常用的功能：
### 自动补全功能
自动补全和bash的补全一样也是使用tab。在ipython里面可以通过查看历史机制来把代码保存出来，
### 历史记录功能
输入hist可以快速查看那些输入的历史记录，输入hist -n可以去掉历史记录中的序号，方便保存代码。至于其他很多功能就不一一介绍了，有需要的可以从自行查找。
### edit功能
在ipython中输入edit会根据环境变量$EDITOR调用相应的编辑器，默认使用vi（linux）或者记事本（windows）。
1. edit (filename.py) 可以编辑当前的filename.py文件，如果文件不存在，则会新建一个新的文件，如果文件存在则会打开该文件，默认会编辑一个tmp下的临时文件，当你退出编辑器后会自动执行刚刚文件的内容。
2. edit -x (filename.py) 跟上面的功能几乎一样，只不过当你退出后不执行文件内容。
3. edit -p 编辑上一次的文件，编辑器退出时自动运行刚刚的文件内容。

### run 一个文件
输入run filename.py 可以运行filename.py这个文件。
1. run -n filename.py 运行filename.py但阻止\_\_name\_\_="\_\_main\_\_"
2. run -i filename.py 运行filename.py使其在当前的名字空间下运行而不是在一个新的名字空间中。
3. run -p filename.py 运行filename.py并使用python的profiler模块分析源代码，使用该选项的代码不会运行在当前名字空间。

### debugger接口
ipython中输入magic pdb可以查看相关的介绍信息。
### 宏
宏允许用户为一段代码定义一个名字，这样以后使用这个名字来运行这段代码，可以想象成是文本的替换，往往配合hist来使用
假设有一个历史记录如下：
```
In [3]: hist
1: L=[]
2:
for i in L:
    print L
In [4]: macro print_L 2
```
这样就为第2行创建了一个宏，以后想输出L的内容时，可以直接输入
```
In [5]: L.append(1)
In [6]: print_L
Out [1]: 1
```
这是一个很强大的功能，但注意这里跟定义的函数完全不是一回事，不要搞混了。
ipython的功能还有很多，这里介绍几个常用的功能，如果还是不了解可以输入help来看看手册。
## ipython notebook
其实这里重点是要介绍这里的，但想到了ipython的强大，忍不住把他的常用功能列了一下，下面开始正题：
ipython notebook做的真是不错，能够搭建一个服务器来远程进行编程，甚至有的人使用他来搭建博客，这里重点介绍一下他的服务器如何搭建。官方的doc在这里： http://ipython.org/ipython-doc/3/notebook/index.html
### ipython notebook的安装和搭建
在Fedora 21上安装ipython notebook可以使用yum
```
sudo yum install ipython-notebook python-setuptools python-matplotlib -y
```
ipython notebook会使用mathjax在浏览器中显示latex的一些代码，如果能事先安装mathjax的话，ipython notebook就不需要联网了，所以我们选择安装mathjax。启动ipython，输入下面两行代码
```
from IPython.external.mathjax import install_mathjax
install_mathjax()
```
如果只是想本机使用可以直接输入ipython notebook，使用浏览器访问http://127.0.0.1:8888 就可以了，但为了能够将本机真正编程一个服务器，还需要继续。
其实ipython notebook可以理解成是某个服务器托管的一个网页，所以这里的服务器应该是可以用很多种的，官网的配置使用的nbserver，这里就介绍nbserver的配置
首先创建一个名为nbserver的配置文件：
```
ipython profile create nbserver
```
在配置nbserver的配置文件之前，我们还需要得到几个内容，登陆密码和私人证书
登陆密码可以使用ipython提供的一个passwd函数来计算得到
```
IN [1]: from IPython.lib import passwd
IN [2]: passwd()
Enter password:
Verify password:
Out[2]: 'sha1:xxxxxxxxxxxxxxxxxxxxxxxxx'
```
创建私人证书：
```
openssl req -x509 -nodes -days 10000 -newkey rsa:1024 -keyout mycert.pem -out mycert.pem
```
这时候会有个输入信息的过程，直接跳过，生成的mycert.pem就是你的私人证书了，我把它放在~/workspace/下
现在就可以去修改nbserver的配置文件了，配置文件是~/.config/ipython/preofile_nbserver 或者 ~/.ipython/preofile_nbserver下的ipython_notebook_config.py 默认内容全部注释掉了，我们不用管他，直接添加下面几句，根据自己的情况可以做一下调整
```
c = get_config()

# Notebook config
c.NotebookApp.certfile = u'/absolute/path/to/your/certificate/mycert.pem'
c.NotebookApp.ip = '*'
c.NotebookApp.open_browser = False
c.NotebookApp.password = u'sha1:bcd259ccf...[your hashed password here]'
# It is a good idea to put it on a known, fixed port
c.NotebookApp.port = 9999
```
完成后，使用下面这句来运行服务器：
```
ipython notebook --profile=nbserver
```
用浏览器访问一下你的服务器吧，默认使用的https协议，所以输入网站的时候注意一下 https://ip_of_your_server:9999
如果不能访问，检查一下你的端口是不是被防火墙阻挡了，把iptables的对应端口打开一下
### ipython notebook 的一些常用功能
ipython notebook的几个常用的功能在这里列一下，其他的很多功能还得多去看看手册
#### 本地运行
在本地运行的ipython notebook默认生成的文件扩展名是ipynb格式，其实可以改成py格式，只需要在启动ipython notebook时加上--script的参数就可以
```
ipython notebook --script
```
#### 执行一个代码
与ipython的shell形式不同的是在notebook中，代码是写在cell中的，你的回车并不能触发这一块代码的运行，输入shift+enter才能执行这段代码
#### pylab的模式
matplotlib生成的图片可以通过弹出一个新页面的形式来显示，也可以嵌入网页内显示：
```
ipython notebook --pylab  ## 默认显示，弹出一个新的页面
ipython notebook --pylab inline  ## 生成的图片嵌入同一个网页内显示
```

ipython的内容很多，另一个跟ipython结合很紧密的工具是matplotlib，有时间的时候也会记录一下。

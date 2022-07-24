title: 树莓派使用yeelink记录历史温度
date: 2015-10-30 22:51:42
categories: 嵌入式
tags: raspberryPi
plink: rpiyeelink
mathjax: true
---

对于树莓派本身的运行状况检测，有很多种方式可以进行记录，我使用了yeelink网站来进行记录，配合系统的crontab功能也能做到定时自动上传的效果。crontab是一个linux定时任务管理工具，使用它可以方便的实现定时执行特定任务的功能。这里记录下如何配置和部分代码，很多代码可以直接再次使用。

## 系统查看CPU和GPU的温度

**查看CPU的温度**，不用多解释，网上说的太多了，而且确实很容易看
```
cat /sys/class/thermal/thermal_zone0/temp
```
除以1000就是你当前的CPU温度了。

**查看GPU的温度**，会有坑，先不说。查看GPU温度使用的是vcgencmd命令
```
/opt/vc/bin/vcgencmd measure_temp
```
如果你的能直接运行，显示的是温度等于多少，那你很可能是使用pi用户。对于不是pi用户，而是自己建的新用户来说，会出现下面的问题
```
$ /opt/vc/bin/vcgencmd measure_temp
VCHI initialization failed
```
遇到 VCHI initialization failed 是因为你的用户没有权限看这个温度，你不是video组的成员。解决方法就是把你的用户加到video组里面
```
sudo usermod -a -G video [你的用户名]
```
再运行一下查看命令，是不是已经可以了啊。

## 使用yeelink API上传温度数据

这里使用了yeelink的API，首先取yeelink.net官网申请帐号，申请完后去“账户-我的账户设置”中查看你的API KEY。 点击“我的设备”，增加新设备后，在管理设备中添加数值型的传感器，测得是温度就把温度的单位写上。加一个GPU温度，一个CPU温度。完事后，记录两个传感器的URL。

好了，准备工作完成，接下来上python的代码，这段代码有可能提示找不到requests，你就直接apt-get install python-requests就可以了，其他的应该没什么问题了。
```
#!/usr/bin/env python
# -*- coding: utf-8 -*-
import requests
import json
import time
import commands

def main():

    # 需要填自己申请到的yeelink api Key 以及你的数据的url
	apiheaders = {'U-ApiKey': '1abdd376b71106d75b3b16bf409269fe', 'content-type': 'application/json'}
	apiurl_gpu = 'http://api.yeelink.net/v1.0/device/8901/sensor/37929/datapoints'
	apiurl_cpu = 'http://api.yeelink.net/v1.0/device/8901/sensor/37928/datapoints'

    # 查看GPU温度
    gpu = commands.getoutput( '/opt/vc/bin/vcgencmd measure_temp' ).replace( 'temp=', '' ).replace( '\'C', '' )
	gpu = float(gpu)
	#print('gpu value:%.2f' % gpu)
	payload_gpu = {'value': gpu}
	r = requests.post(apiurl_gpu, headers=apiheaders, data=json.dumps(payload_gpu))

    # 查看CPU温度
	file = open("/sys/class/thermal/thermal_zone0/temp")
	cpu = float(file.read()) / 1000
	file.close()
	payload_cpu = {'value': cpu}
	r = requests.post(apiurl_cpu, headers=apiheaders, data=json.dumps(payload_cpu))
	time.sleep(1)

if __name__ == '__main__':
    main()
```
将上面的代码修改后保存成yeelink.py文件，放在home下，运行看能不能上传数据。
```
python yeelink.py
```

## 使用crontab定时运行

crontab是Linux里面的计划任务，对于想定时启动的任务来说，很方便，而且人家默认打开的文件里面非常详细的描述了自己怎么用（甚至还给了一个例子。。）使用方法就是运行下面这句话，他会使用你默认的编辑器打开crontab的。
```
crontab -e
```
对于你想每10分钟做一次的操作或者每5分钟做一次。可以在对应的地方写成*/10或者*/5这种形式，我们就是让他每十分钟上传一次吧，在文件的最下面写上这一句
```
# 分 时 一个月中的哪一天  哪一个月 一个星期中的哪一天  命令
*/10 * * * * python ~/yeelink.py
```
解释：

* \* \*  \*  \*  \* 命令
* 前面的五个\*号，表示分、时、日、月、周，如：
* 代表意义 分钟 小时 日期 月份 周
* 数字范围 0-59 0-23 1-31 1-12 0-7
* \*号代表任何时间都接受的意思，任意。
* \*号之间用空格分开，如果是一段范围，用-号连接；如果是隔开几个时间，用,号表示。
* 另外，命令必须是编写计划任务的用户有权限执行的，并且最后用绝对路径。


保存退出就好了，这样以后每10分钟就会自动上传你的CPU和GPU的温度，运行一段时间后，你也可以方便的看到你的近期温度的情况。

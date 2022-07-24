title: Fedora23安装fcitx拼音输入法
date: 2015-12-15 13:31:35
categories: 学习笔记
tags: Linux
plink: fedora-fcitx-install
mathjax: true
---

12月份fedora23正式上线，据说23是最好用的fedora版本，然后我就装上自己试试，发现确实比以前做的要好很多。其中感觉dnf做的要比之前的yum更智能，反应也很快，多个dnf同时安装时，锁机制更合理。

我这里使用的时fedora 23的kde版本，语言使用的是en\_US.utf8。安装完发现这上面ibus，fcitx都没装，所以省去了卸载输入法的步骤，感觉确实做的不错。

## 安装输入法
使用dnf安装fcitx，这里fcitx-configtool是fcitx的配置图形界面
```
sudo dnf install fcitx fcitx-pinyin fcitx-configtool
```
## 安装图形管理依赖
很多人说到fcitx安装成功了，配置也配置好了，在浏览器或者其他应用里面可以用，但在terminal中就不能使用，这是因为没有装fcitx的图形管理包所导致的。kde依赖于qt5,而gnome依赖于gtk3（fedora 23是这个版本），所以接下来继续使用dnf
```
# kde界面使用：
sudo dnf install fcitx-qt5
# gnome界面使用：
sudo dnf install fcitx-gtk3
```
## 安装输入法选择器
这里使用im-chooser
```
sudo dnf install im-chooser
```
安装完成后在终端中运行im-chooser选择fcitx，注销后继续
## 选择输入法
打开fcitx-configtool,添加pinyin输入法，至此就成功完成了输入法的安装。

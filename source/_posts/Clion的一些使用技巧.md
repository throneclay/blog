title: Clion的一些使用技巧
mathjax: true
date: 2017-03-28 23:47:20
categories: 学习笔记
tags: Clion
plink: clion
---
Clion是我最近发现的一个非常好用的IDE，界面做的很漂亮，而且功能做的不错，尤其跨平台的特点对我来说很方便，在Mac和linux上找个好看好用的IDE并不容易。缺点之一是Clion上用的是CMakeLiist而不是我熟悉的Makefile来管理项目，所以也就有了这里的记录。其实慢慢用多了感觉CMakeList也还是能接受的。

另外话说这么好的IDE居然可以用学生邮箱免费拿到License。。

## CXX_FLAGS

设置C++的FLAGS用下面一句
```
set(CMAKE_CXX_FLAGS '[FLAGS]')
# 例如设置-mkl
set(CMAKE_CXX_FLAGS '-mkl')
```
设置C的FLAGS用下面一句
```
set(CMAKE_C_FLAGS '[FLAGS]')
# 例如设置-mkl
set(CMAKE_C_FLAGS '-mkl')
```

## 设置编译器

同样分为C++的和C的编译器
```
# 设置intel编译器
set(CMAKE_CXX_COMPILER /opt/intel/bin/icpc)
或
set(CMAKE_C_COMPILER /opt/intel/bin/icc)
```

## Clion链接库
感觉其实也没什么好说的,直接说一下我是怎么链接的两个库好了.
### Clion链接Intel OpenCL库
CMake可以根据你设置的一些关键变量去查找到底这个文件出现在哪个文件夹下,能够一定程度的适应不同的系统,所以首先要查找,查找include和lib路径
```
find_path(OPENCL_INCLUDE CL/opencl.h PATHS /opt/intel/opencl/include/)
find_library(OPENCL_LIBRARY libOpenCL.so PATHS /opt/intel/opencl/)
```
找到后就很简单了,include里指定路径,最后的时候链接上库,假设我们的目标文件名为test,在最后的add\_executable函数后需要接上target\_link\_libraries
```
include_directories(${OPENCL_INCLUDE})

....

add_executable(test ${SOURCE_FILES})
target_link_libraries(test ${OPENCL_LIBRARY})
```

### Clion链接Intel MKL库
同上面提到的,链接MKL也需要先查找头文件路径和库路径,这里不同的是还需要查找Openmp的库,因为不链接Openmp会在后期各种报错
```
find_path(MKL_INCLUDE mkl.h PATHS /opt/intel/mkl/include/)
find_library(MKL_LIBRARY libmkl_intel_lp64.so PATHS /opt/intel/mkl/lib/intel64/)
find_library(OPENMP_LIBRARY libiomp5.so PATHS /opt/intel/lib/intel64)
```
最后指定include路径和lib的链接,如果多个库或者头文件,空格隔开即可.当然还需要'-mkl'的FLAGS指定(见上文).
```
include_directories(${MKL_INCLUDE})

....

add_executable(test ${SOURCE_FILES})
target_link_libraries(test ${MKL_LIBRARY} ${OPENMP_LIBRARY})
```

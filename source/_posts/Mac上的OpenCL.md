title: Mac上的OpenCL
mathjax: true
date: 2016-7-20 11:19:39
categories: 并行计算
tags: OpenCL
plink: macocl
---

OpenCL是一个为异构平台编写程序的框架，多种异构计算设备都支持OpenCL如CPU，GPU，MIC，DSP，FPGA。OpenCL最初由苹果公司开发，拥有其商标权，并在与AMD，IBM，英特尔和nVIDIA技术团队的合作之下初步完善。随后，苹果将这一草案提交至Khronos Group。

由于实习期间公司配的是Macbook，为了方便学习OpenCL，我在Mac上也测试了下OpenCL的代码，这里记录一下，方便以后开发。

首先，OpenCL的代码需要库，编译时用clang编译，带的编译选项是-framework OpenCL
头文件是<OpenCL/opencl.h>

我写的一个测试代码如下，同时放到github上了[https://github.com/throneclay/macOpencl](https://github.com/throneclay/macOpencl)
```
#include <stdio.h>
#include <stdlib.h>
#include <OpenCL/opencl.h>

int main(int argc, char* const argv[]) {
    cl_uint num_devices, i;
    clGetDeviceIDs(NULL, CL_DEVICE_TYPE_ALL, 0, NULL, &num_devices);

    cl_device_id* devices = calloc(sizeof(cl_device_id), num_devices);
    clGetDeviceIDs(NULL, CL_DEVICE_TYPE_ALL, num_devices, devices, NULL);

    char buf[128];
    for (i = 0; i < num_devices; i++) {
        clGetDeviceInfo(devices[i], CL_DEVICE_NAME, 128, buf, NULL);
        fprintf(stdout, "Device %s supports ", buf);

        clGetDeviceInfo(devices[i], CL_DEVICE_VERSION, 128, buf, NULL);
        fprintf(stdout, "%s\n", buf);
    }

    free(devices);
}
```

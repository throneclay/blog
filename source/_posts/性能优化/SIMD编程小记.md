title: SIMD编程小记
date: 2015-12-16 18:49:40
categories: 性能优化
tags: SIMD
plink: SIMD
mathjax: true
---

SIMD是指的单指令多数据的一种并行处理方式，目前大多数CPU都集成有向量处理器VPU就是一种典型的SIMD处理单元。Intel的SSE，AVX等等指令集就是用来操作VPU的。如果能够很好的利用起VPU，能够达到很好的加速效果。写这篇文章主要是因为最近在看各种向量化技术，顺便还看到了一个很好的表格，特此在这里记一下。

## 头文件 Headers
CPU上的向量化技术目前主要流行SSE和AVX，其中AVX是现在INTEL最新的CPU向量化技术。SSE和AVX都需要特殊的“函数”来告知此处使用VPU（向量处理器）来处理，这些函数的特点就是特别底层，类似汇编但又不是汇编。想要使用这些指令就需要包上对应的头文件，下面这个表格总结了关于SIMD的相关的头文件。使用时当然不需要知道这么多，immintrin.h这个文件把所有的SIMD指令都包含在内了（X86,AMD 3dnow等），如果只想使用X86系列的所有指令，那就包x86intrin.h文件。
```
+----------------+------------------------------------------------------------------------------------------+
|     Header     |                                         Purpose                                          |
+----------------+------------------------------------------------------------------------------------------+
| x86intrin.h    | x86 instructions _rdtsc()                                                                |
| mmintrin.h     | MMX (Pentium MMX!)                                                                       |
| mm3dnow.h      | 3dnow! (K6-2) (deprecated)                                                               |
| xmmintrin.h    | SSE + MMX (Pentium 3, Athlon XP)                                                         |
| emmintrin.h    | SSE2 + SSE + MMX (Pentiuem 4, Ahtlon 64)                                                 |
| pmmintrin.h    | SSE3 + SSE2 + SSE + MMX (Pentium 4 Prescott, Ahtlon 64 San Diego)                        |
| tmmintrin.h    | SSSE3 + SSE3 + SSE2 + SSE + MMX (Core 2, Bulldozer)                                      |
| popcntintrin.h | POPCNT (Core i7, Phenom subset of SSE4.2 and SSE4A)                                      |
| ammintrin.h    | SSE4A + SSE3 + SSE2 + SSE + MMX (Phenom)                                                 |
| smmintrin.h    | SSE4_1 + SSSE3 + SSE3 + SSE2 + SSE + MMX (Core i7, Bulldozer)                            |
| nmmintrin.h    | SSE4_2 + SSE4_1 + SSSE3 + SSE3 + SSE2 + SSE + MMX (Core i7, Bulldozer)                   |
| wmmintrin.h    | AES (Core i7 Westmere, Bulldozer)                                                        |
| immintrin.h    | AVX, SSE4_2 + SSE4_1 + SSSE3 + SSE3 + SSE2 + SSE + MMX (Core i7 Sandy Bridge, Bulldozer) |
+----------------+------------------------------------------------------------------------------------------+
```
## 编译器
目前gcc和intel的icc都支持SSE和AVX指令，但相对来说intel的编译器编译出来的代码速度一般更快一些。使用的时候带上编译选项-msse或者-mavx。不同的是对于icc还可以使用-xcode以区别gcc的编译，比如-xSSE4.2或-xAVX，对于一些特定的Intel硬件，-xcode是唯一可以用的向量化选项。

## CPU理论浮点峰值性能
一颗CPU的理论浮点峰值性能反应了这颗CPU的最大浮点处理能力，通常也称为CPU的吞吐量。一般来说，CPU浮点风机统计的浮点计算类型只包含乘法和加法（包括减法）。对于Intel X86系列的CPU来说，计算峰值双精度为单精度的一半。
计算理论浮点峰值实际上就是计算一个CPU每秒种完成的乘法和加法的次数，他的单位是GFLOPS。这样我们可以得到下面的公式（VPU就是向量处理单元）
          单精度浮点峰值性能 = VPU数量 × VPU频率 × 每周期乘法和加法的吞吐
目前主要计算时使用了VPU代替CPU主要因为VPU的性能远比CPU好，举个例子，我的i5-3470,VPU数量应该是2个，VPU主频近似于CPU主频3.2G，AVX具有FMA能够同时计算加法和乘法，同时采用SIMD计算的方式，能同时计算256长度（8个单精度浮点）的向量，因此就是2×3.2×16=102.4GFLOPS同查到的数值一致（证明确实只有两个AVX处理单元）。再比如Intel Xeon Phi 7110P协处理器，拥有61个VPU，每个核主频1.091GHz，每个VPU长度512位（16个单精度浮点），也支持FMA，因此就是61×1.091×32=2129.632GFLOPS，同手册上一致。其实使用这个公式的目的不是让你计算浮点性能（这个往往很容易知道），主要是来判断你有多少个VPU数量，这样在开线程的时候，可以根据这个数量来开充分向量化的线程。而不再根据你有多少个硬件线程数来开线程。
其实书上往往告诉你，并行计算表现最好的时候是你开的线程数等于硬件核心数的时候。但现在SIMD技术的不断成熟，编写出来的代码如果是充分向量化后的代码 ，最合适的线程数应该是你的VPU的数量。但往往我们不能达到这个充分向量化，因为程序中毕竟还有很多不适合SIMD编程的地方。对于这种VPU跑不满的问题，要么通过优化算法使其适合做成SIMD程序，要么通过增加线程数，使得不同线程达到互相掩盖访存延迟的效果。

这里并不涉及SIMD编程的内容，感兴趣自己找找Intel AVX指令集手册来看看。

## 不同架构下的向量处理器
这里是我在网上看到的关于不同微架构下的向量处理器达到最大Flops时使用的指令方式。

Intel Core 2 and Nehalem:
* 4 DP FLOPs/cycle: 2-wide SSE2 addition + 2-wide SSE2 multiplication
* 8 SP FLOPs/cycle: 4-wide SSE addition + 4-wide SSE multiplication

Intel Sandy Bridge/Ivy Bridge:
* 8 DP FLOPs/cycle: 4-wide AVX addition + 4-wide AVX multiplication
* 16 SP FLOPs/cycle: 8-wide AVX addition + 8-wide AVX multiplication

Intel Haswell/Broadwell/Skylake:
* 16 DP FLOPs/cycle: two 4-wide FMA (fused multiply-add) instructions
* 32 SP FLOPs/cycle: two 8-wide FMA (fused multiply-add) instructions

AMD K10:
* 4 DP FLOPs/cycle: 2-wide SSE2 addition + 2-wide SSE2 multiplication
* 8 SP FLOPs/cycle: 4-wide SSE addition + 4-wide SSE multiplication

AMD Bulldozer/Piledriver/Steamroller, per module (two cores):
* 8 DP FLOPs/cycle: 4-wide FMA
* 16 SP FLOPs/cycle: 8-wide FMA

Intel Atom (Bonnell/45nm, Saltwell/32nm, Silvermont/22nm):
* 1.5 DP FLOPs/cycle: scalar SSE2 addition + scalar SSE2 multiplication every other cycle
* 6 SP FLOPs/cycle: 4-wide SSE addition + 4-wide SSE multiplication every other cycle

AMD Bobcat:
* 1.5 DP FLOPs/cycle: scalar SSE2 addition + scalar SSE2 multiplication every other cycle
* 4 SP FLOPs/cycle: 4-wide SSE addition every other cycle + 4-wide SSE multiplication every other cycle

AMD Jaguar:
* 3 DP FLOPs/cycle: 4-wide AVX addition every other cycle + 4-wide AVX multiplication in four cycles
* 8 SP FLOPs/cycle: 8-wide AVX addition every other cycle + 8-wide AVX multiplication every other cycle

ARM Cortex-A9:
* 1.5 DP FLOPs/cycle: scalar addition + scalar multiplication every other cycle
* 4 SP FLOPs/cycle: 4-wide NEON addition every other cycle + 4-wide NEON multiplication every other cycle

ARM Cortex-A15:
* 2 DP FLOPs/cycle: scalar FMA or scalar multiply-add
* 8 SP FLOPs/cycle: 4-wide NEONv2 FMA or 4-wide NEON multiply-add

Qualcomm Krait:
* 2 DP FLOPs/cycle: scalar FMA or scalar multiply-add
* 8 SP FLOPs/cycle: 4-wide NEONv2 FMA or 4-wide NEON multiply-add

IBM PowerPC A2 (Blue Gene Q), per core (supports 4 hyperthreads):
* 8 DP FLOPs/cycle: 4-wide QPX FMA every cycle
* SP elements are extended to DP and processed on the same units

IBM PowerPC A2 (Blue Gene Q), per thread:
* 4 DP FLOPs/cycle: 4-wide QPX FMA every other cycle
* SP elements are extended to DP and processed on the same units

Intel MIC (Xeon Phi), per core (supports 4 hyperthreads):
* 16 DP FLOPs/cycle: 8-wide FMA every cycle
* 32 SP FLOPs/cycle: 16-wide FMA every cycle

Intel MIC (Xeon Phi), per thread:
* 8 DP FLOPs/cycle: 8-wide FMA every other cycle
* 16 SP FLOPs/cycle: 16-wide FMA every other cycle

单片机STM32开发，大多数人都是在Windows下的Keil软件上进行的。Keil软件不仅要付费，编译还非常非常慢（据说优化做得好）。

在Linux的开发环境下，使用gcc编译、gdb调试，不仅软件是自由开源免费，编译速度还非常非常快。

就以我曾经做过的一个项目为例，同样的代码在同样配置的电脑上，在Windows系统的**Keil下全部编译要8分钟左右**，而在Linux的**gcc下全部编译只需要几秒**，编译时间是几十倍的关系。

以Semtech公司开源的LoRa节点代码为例，说明STM32 的Linux开发环境的搭建和使用，github项目链接为[LoRaMac-node](https://github.com/Lora-net/LoRaMac-node)。

开发环境以**`Ubuntu18.04`**为例，以默认的NucleoL073板子（STM32L073）进行演示。

# 软件安装

参考文件[development-environment.md](https://github.com/Lora-net/LoRaMac-node/blob/master/doc/development-environment.md)。

先安装开发必备软件：

```sh
sudo apt install build-essential -y
```

安装GNU ARM-Toolchain，或源码安装（参考[网站](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm)）：

```sh
sudo apt install gcc-arm-none-eabi -y
```

安装OpenOCD，或源码安装（参考[网站](http://openocd.org/getting-openocd/)）：

```sh
sudo apt-get install openocd -y
```

# 编译代码

参考文件[development-environment.md](https://github.com/Lora-net/LoRaMac-node/blob/master/doc/development-environment.md)。

在项目的顶层目录下，创建build文件夹并进入：

```sh
mkdir build
cd build
```

生成makefile文件：

```sh
cmake -DCMAKE_TOOLCHAIN_FILE="cmake/toolchain-arm-none-eabi.cmake" ..
```

编译的结果为`src/apps/LoRaMac/LoRaMac-classA*`

STM32L073的cmake文件为[cmake/stm32l0.cmake](https://github.com/Lora-net/LoRaMac-node/blob/master/cmake/stm32l0.cmake)，编译工具链的cmake文件为[cmake/toolchain-arm-none-eabi.cmake](https://github.com/Lora-net/LoRaMac-node/blob/master/cmake/toolchain-arm-none-eabi.cmake)。如果是其他芯片平台，可以参考这些文件修改。

# 烧录固件和调试代码

参考文件[development-environment.md](https://github.com/Lora-net/LoRaMac-node/blob/master/doc/development-environment.md)。

运行openocd软件（注意这个窗口不能关闭）：

```sh
openocd -f interface/stlink-v2-1.cfg  -f target/stm32l0.cfg
```

`interface/stlink-v2-1.cfg`（stlink配置文件）和`target/stm32l0.cfg`（芯片平台配置文件）都位于`/usr/share/openocd/scripts`目录下。

运行gdb：

```sh
arm-none-eabi-gdb src/apps/LoRaMac/LoRaMac-classA
#此时已经进入gdb，以下命令前的(gdb)表示处于gdb程序中
(gdb) target extended-remote localhost:3333 #让gdb和openocd连接
(gdb) monitor reset halt #重置
(gdb) load	#下载固件到板子
(gdb) thbreak main	#在main函数中打断点
(gdb) continue	#这时候将会停在断点处
(gdb) continue	#这时候将会继续运行
```

运行gdb之后，可以打断点，单步调试，查看变量值  等等等等，比Windows下的Keil好用多了。

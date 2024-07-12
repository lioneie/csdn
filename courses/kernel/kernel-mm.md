我们知道，操作系统是横跨软件和硬件的桥梁，其中内存寻址是操作系统设计的硬件基础之一。

先介绍几个概念。

```sh
logical                 linear              physical
address  +------------+ address  +--------+ address
-------->|segmentation|--------->| paging |--------->
         |   unit     |          |  unit  |
         +------------+          +--------+
```

MMU，英文全称Memory Management Unit，中文翻译为内存管理单元，又叫分页内存管理单元（Paged Memory Management Unit），把虚拟地址转换成物理地址。MMU以page大小为单位管理内存，虚拟内存的最小单位就是page。

# 几个概念

- 中断（interrupt）: 定义为一个事件，该事件改变cpu执行的指令顺序，分为同步中断和异步中断。同步（synchronous）中断: 只有在一条指令终止执行后cpu才会发出中断，同步中断称为异常。异步（asynchronous）中断: 由其他硬件设备随机产生的，如间隔定时器或I/O设备。一般我们所说的中断特指异步中断，也叫硬中断(hardirq)。
  - 可屏蔽中断（maskable interrupt）: I/O设备发出的所有中断请求都产生可屏蔽中断，控制单元忽略处理屏蔽状态（masked）的中断。
  - 不可屏蔽中断（nonmaskable interrupt）: 只有几个危急事件（如硬件故障）才引起不可屏蔽中断。
- 异常（exception）: 由程序的错误（处理器本身）产生，或由内核必须处理的异常（如缺页）条件产生的。
  - 处理器探测异常（processor-detected exception）: cpu执行指令时探测到的反常条件所产生的异常。根据cpu产生异常时保存在x86的`eip`寄存器或arm64的`pc`寄存器中的值，可以分为3组:
    - 故障（fault）: 保存在x86的`eip`寄存器或arm64的`pc`寄存器中的值是引起故障的指令地址，异常处理程序执行完后，那条指令重新执行，如缺页异常，纠正引起缺页异常的反常条件后重新执行同一指令。
    - 陷阱（trap）: 保存在x86的`eip`寄存器或arm64的`pc`寄存器中的值是随后要执行的指令地址，只有当没有必要重新执行已终止的指令时，才触发陷阱，陷阱的主要用途是为了调试程序。
    - 异常中止（abort）: x86的`eip`寄存器或arm64的`pc`寄存器中不能保存引起异常的指令所在的确切位置，用于报告严重的错误，如硬件故障或系统表中无效的值或不一致的值。异常终止处理程序只能终止进程，别无选择。
  - 编程异常（programmed exception）: 编程者发出请求时发生。以下几种情况会发生编程异常: x86下`int`（用于触发中断）和`int3`（触发特定的中断3，用于断点），arm64的`SVC`（对应x86的`int`）和`BRK`（对应x86的`int3`），以及x86下的`into`（检查溢出）和`bound`（检查地址出界）指令检查的条件不为真时。控制单元把编程异常作为陷阱来处理，也叫软件中断（software interrupt），简称软中断（softirq），编程异常有两种用途: 执行系统调用和给调试程序通报一个特定的事件。

# 中断简介

连接到计算机的硬件有很多，如硬盘、鼠标、键盘等，cpu的速度比这些外围硬件设备高出几个数量级，轮询（polling）会让内核做很多无用功，所以需要中断这种机制让硬件在需要时通知内核。中断本质上是一种电信号，硬件设备在生成中断时不考虑与cpu的时钟同步，也就是中断随时可以产生，内核随时可能会被新来的中断打断。硬件设备产生的电信号直接送入中断控制器（简单的电子芯片）的输入引脚。不同设备对应的中断不同，每个中断对应一个中断号，又叫中断请求（IRQ）线，但有些中断号是动态分配的，如连接在PCI（Peripheral Component Interconnect）总线上的设备。

进程上下文（process context）是一种内核所处的操作模式，此时内核代表进程执行，如执行系统调用或运行内核线程，可以通过`current`宏关联当前进程，进程上下文中可以睡眠，也可以调用调度器。


响应中断时，内核会执行一个函数，这个函数叫中断处理程序（interrupt handler）或中断服务例程（interrupt service routine，ISR），中断处理程序处理要非常快。执行中断处理程序时，内核处于中断上下文（interrupt context），又叫原子上下文中，不可阻塞，`current`宏指向被中断的进程，中断上下文中不可睡眠，中断栈的大小定义在`IRQ_STACK_SIZE`。

中断处理程序中要处理得快，完成的工作量就受限，所以把中断处理分为上半部（top half）和下半部（bottom half）。上半部做有严格时限的工作，如对中断应答或复位硬件，这时所有中断都被禁止。能稍后完成的工作推迟到下半部。

# 中断处理程序

## 注册中断处理程序

通过`request_irq()`注册一个中断处理程序，注意`request_irq()`函数会睡眠:
```c
/**
 * request_irq - 为中断线添加处理程序
 * @irq:        要分配的中断线（中断号）
 * @handler:    当IRQ发生时调用的函数。
 *              线程中断的主要处理程序
 *              如果为NULL，将安装默认的主要处理程序
 * @flags:      处理标志
 * @name:       产生此中断的设备名称，会被/proc/irq/和/proc/interrupts使用
 * @dev:        传递给处理函数的cookie，用于共享中断线，一般会传递驱动程序的设备结构
 *
 * 此调用分配一个中断并建立一个处理程序；有关详细信息，请参见
 * request_threaded_irq()的文档。
 * Return: 成功时返回0，常见错误为-EBUSY，表示给定中断线已经在使用，或没有指定IRQF_SHARED
 */
static inline int __must_check
request_irq(unsigned int irq, irq_handler_t handler, unsigned long flags,
            const char *name, void *dev)

/**
 *      request_threaded_irq - 分配一个中断线
 *      @irq: 要分配的中断线
 *      @handler: 当 IRQ 发生时调用的函数。
 *                线程中断的主要处理程序。
 *                如果 handler 为 NULL 且 thread_fn != NULL
 *                则安装默认的主要处理程序。
 *      @thread_fn: 从 irq 处理程序线程调用的函数
 *                  如果为 NULL，则不创建 irq 线程
 *      @irqflags: 中断类型标志
 *      @devname: 声明设备的 ASCII 名称
 *      @dev_id: 传递回处理函数的 cookie
 *
 *      此调用分配中断资源并启用
 *      中断线和 IRQ 处理。从此
 *      调用后，您的处理函数可能会被调用。由于
 *      您的处理函数必须清除主板引发的任何中断，
 *      因此您必须小心初始化硬件
 *      并以正确的顺序设置中断处理程序。
 *
 *      如果您想为设备设置线程化的 irq 处理程序，
 *      则需要提供 @handler 和 @thread_fn。@handler 仍然
 *      在硬中断上下文中被调用，并且必须检查
 *      中断是否来自设备。如果是，则需要禁用设备上的
 *      中断并返回 IRQ_WAKE_THREAD，这将唤醒处理程序线程并运行
 *      @thread_fn。此分离处理程序设计对于支持
 *      共享中断是必要的。
 *
 *      Dev_id 必须全局唯一。通常使用设备数据结构的
 *      地址作为 cookie。由于处理程序接收此值，
 *      因此使用它是有意义的。
 *
 *      如果您的中断是共享的，则必须传递一个非 NULL dev_id，
 *      因为在释放中断时需要此值。
 *
 *      标志：
 *
 *      IRQF_SHARED             中断是共享的
 *      IRQF_TRIGGER_*          指定活动边缘或电平
 *      IRQF_ONESHOT            在掩蔽中断线的情况下运行 thread_fn
 */
int request_threaded_irq(unsigned int irq, irq_handler_t handler,
                         irq_handler_t thread_fn, unsigned long irqflags,
                         const char *devname, void *dev_id)
```

`irq_handler_t handler`参数的的定义如下:
```c
// include/linux/interrupt.h
typedef irqreturn_t (*irq_handler_t)(int, void *);
```

`flags`参数可以为`0`，也可能是以下值:
```c
/*
 * 这些对应于 linux/ioport.h 中的 IORESOURCE_IRQ_*(IORESOURCE_IRQ_HIGHEDGE等) 定义，
 * 用于选择中断线行为。当请求一个中断而未指定 IRQF_TRIGGER 时，
 * 应假定设置为“已配置”，这可能是根据机器或固件初始化。
 */
#define IRQF_TRIGGER_NONE       0x00000000
#define IRQF_TRIGGER_RISING     0x00000001
#define IRQF_TRIGGER_FALLING    0x00000002
#define IRQF_TRIGGER_HIGH       0x00000004
#define IRQF_TRIGGER_LOW        0x00000008
#define IRQF_TRIGGER_MASK       (IRQF_TRIGGER_HIGH | IRQF_TRIGGER_LOW | \
                                 IRQF_TRIGGER_RISING | IRQF_TRIGGER_FALLING)
#define IRQF_TRIGGER_PROBE      0x00000010

/*
 * 这些标志仅由内核作为中断处理例程的一部分使用。
 *
 * IRQF_SHARED - 允许多个设备共享中断
 * IRQF_PROBE_SHARED - 当调用者预计会发生共享不匹配时设置
 * IRQF_TIMER - 标记此中断为定时器中断的标志
 * IRQF_PERCPU - 中断是每个 CPU 的
 * IRQF_NOBALANCING - 排除此中断进行中断平衡的标志
 * IRQF_IRQPOLL - 中断用于轮询（在共享中断中，仅第一个注册的中断
 *                出于性能原因被考虑）
 * IRQF_ONESHOT - 硬中断处理程序完成后不会重新使能中断。
 *                用于需要保持中断线禁用的线程中断，直到
 *                线程处理程序运行。
 * IRQF_NO_SUSPEND - 在挂起期间不禁用此中断。并不保证
 *                   此中断会唤醒系统从挂起状态。见 Documentation/power/suspend-and-interrupts.rst
 * IRQF_FORCE_RESUME - 在恢复时强制启用，即使设置了 IRQF_NO_SUSPEND
 * IRQF_NO_THREAD - 中断不能被线程化
 * IRQF_EARLY_RESUME - 在 syscore 期间尽早恢复 IRQ，而不是在设备
 *                恢复时。
 * IRQF_COND_SUSPEND - 如果 IRQ 与 NO_SUSPEND 用户共享，在挂起中断后执行此
 *                中断处理程序。对于系统唤醒设备，用户需要在
 *                他们的中断处理程序中实现唤醒检测。
 * IRQF_NO_AUTOEN - 用户请求时不要自动启用 IRQ 或 NMI。
 *                用户稍后将通过 enable_irq() 或 enable_nmi()
 *                显式启用它。
 * IRQF_NO_DEBUG - 在逃逸检测中排除 IPI 和类似处理程序，
 *                 取决于 IRQF_PERCPU。
 */
#define IRQF_SHARED             0x00000080
#define IRQF_PROBE_SHARED       0x00000100
#define __IRQF_TIMER            0x00000200
#define IRQF_PERCPU             0x00000400
#define IRQF_NOBALANCING        0x00000800
#define IRQF_IRQPOLL            0x00001000
#define IRQF_ONESHOT            0x00002000
#define IRQF_NO_SUSPEND         0x00004000
#define IRQF_FORCE_RESUME       0x00008000
#define IRQF_NO_THREAD          0x00010000
#define IRQF_EARLY_RESUME       0x00020000
#define IRQF_COND_SUSPEND       0x00040000
#define IRQF_NO_AUTOEN          0x00080000
#define IRQF_NO_DEBUG           0x00100000

#define IRQF_TIMER              (__IRQF_TIMER | IRQF_NO_SUSPEND | IRQF_NO_THREAD)
```

## 释放中断处理程序

```c
/**
 *      free_irq - 释放通过 request_irq 分配的中断
 *      @irq: 要释放的中断线
 *      @dev_id: 设备标识以释放
 *
 *      移除中断处理程序。如果中断线不再被任何驱动程序使用，
 *      则将其禁用。在共享 IRQ 的情况下，调用者必须确保在调用
 *      此函数之前，在其驱动的卡上禁用中断。该函数在此 IRQ
 *      的任何正在执行的中断完成之前不会返回。
 *
 *      此函数不得在中断上下文中调用。必须从进程上下文中调用。
 *
 *      返回传递给 request_irq 的 devname 参数。
 */
const void *free_irq(unsigned int irq, void *dev_id)
```

## 编写中断处理程序

举个例子:
```c
static irqreturn_t tg3_test_isr(int irq, void *dev_id)
```

返回值定义如下:
```c
/**
 * enum irqreturn - irqreturn 类型值，可以使用IRQ_RETVAL(x)将其他值转换为枚举值
 * @IRQ_NONE:           中断不是来自此设备或未被处理
 * @IRQ_HANDLED:        中断已被此设备处理
 * @IRQ_WAKE_THREAD:    处理程序请求唤醒处理程序线程
 */
enum irqreturn {
        IRQ_NONE                = (0 << 0),
        IRQ_HANDLED             = (1 << 0),
        IRQ_WAKE_THREAD         = (1 << 1),
};
```

中断处理程序在执行时，相应的中断线在所有cpu上都会被屏幕，但其他中断都是打开的。

共享的中断处理程序如下:
```c
// 共享的中断处理程序的dev参数不能传NULL，一般传设备结构的指针
err = request_irq(tnapi->irq_vec, tg3_test_isr,  
                  IRQF_SHARED, dev->name, tnapi);
```

非共享的中断处理程序如下:
```c
retval = request_irq(rtc_irq, efw,
                0, dev_name(&cmos_rtc.rtc->dev),
                cmos_rtc.rtc);
```

# 实现

中断处理系统的实现依赖于cpu、中断控制器的类型、体系结构的设计、机器本身。

中断从硬件到内核的路径:

- 硬件产生一个中断，通过总线把电信号发给中断控制器（interrupt controller unit）。
- 中断控制器把中断发给cpu。
- cpu中断内核。

x86系统结构下函数流程如下:
```c
common_interrupt
  __common_interrupt
    handle_irq
      generic_handle_irq_desc
        handle_edge_irq
          handle_irq_event
            handle_irq_event_percpu
              __handle_irq_event_percpu
              add_interrupt_randomness
```

# `/proc/interrupts`

为了便于观察，我们以单核cpu为例:
```sh
           CPU0       
  0:         56   IO-APIC   2-edge      timer
  1:          9   IO-APIC   1-edge      i8042
  4:        546   IO-APIC   4-edge      ttyS0
  8:          1   IO-APIC   8-edge      rtc0
  9:          0   IO-APIC   9-fasteoi   acpi
 12:         15   IO-APIC  12-edge      i8042
 24:          0  PCI-MSIX-0000:00:05.0   0-edge      virtio3-config
 25:       1710  PCI-MSIX-0000:00:05.0   1-edge      virtio3-req.0
 26:          0  PCI-MSIX-0000:00:04.0   0-edge      virtio2-config
 27:          0  PCI-MSIX-0000:00:04.0   1-edge      virtio2-control
 28:          0  PCI-MSIX-0000:00:04.0   2-edge      virtio2-event
 29:        322  PCI-MSIX-0000:00:04.0   3-edge      virtio2-request
 30:          0  PCI-MSIX-0000:00:02.0   0-edge      virtio0-config
 31:         54  PCI-MSIX-0000:00:02.0   1-edge      virtio0-input.0
 32:         81  PCI-MSIX-0000:00:02.0   2-edge      virtio0-output.0
 33:          0  PCI-MSIX-0000:00:03.0   0-edge      virtio1-config
 34:          0  PCI-MSIX-0000:00:03.0   1-edge      virtio1-requests
NMI:          0   Non-maskable interrupts
LOC:       2937   Local timer interrupts
SPU:          0   Spurious interrupts
PMI:          0   Performance monitoring interrupts
IWI:          0   IRQ work interrupts
RTR:          0   APIC ICR read retries
RES:          0   Rescheduling interrupts
CAL:          0   Function call interrupts
TLB:          0   TLB shootdowns
TRM:          0   Thermal event interrupts
THR:          0   Threshold APIC interrupts
DFR:          0   Deferred Error APIC interrupts
MCE:          0   Machine check exceptions
MCP:          1   Machine check polls
HYP:          1   Hypervisor callback interrupts
ERR:          0
MIS:          0
PIN:          0   Posted-interrupt notification event
NPI:          0   Nested posted-interrupt event
PIW:          0   Posted-interrupt wakeup event
```

- 第一列: 中断线。
- 第二列: 接收中断数目的计数器。
- 第三列: 中断控制器。
- 第四列: 设备名称，也就是`request_irq()`的`name`参数。如果中断是共享的，则所有设备名都会列出来，以逗号分隔。

相关函数流程:
```c
call_read_iter
  proc_reg_read_iter
    seq_read_iter
      show_interrupts
```


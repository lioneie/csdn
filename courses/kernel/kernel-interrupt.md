# 几个概念

- 中断（interrupt）: 定义为一个事件，该事件改变cpu执行的指令顺序，分为同步中断和异步中断。同步（synchronous）中断: 只有在一条指令终止执行后cpu才会发出中断，同步中断称为异常。异步（asynchronous）中断: 由其他硬件设备随机产生的，如间隔定时器或I/O设备。一般我们所说的中断特指异步中断，也叫硬中断(hardirq)。
  - 可屏蔽中断（maskable interrupt）: I/O设备发出的所有中断请求都产生可屏蔽中断，控制单元忽略处理屏蔽状态（masked）的中断。
  - 不可屏蔽中断（nonmaskable interrupt）: 只有几个危急事件（如硬件故障）才引起不可屏蔽中断。
- 异常（exception）: 由程序的错误（处理器本身）产生，或由内核必须处理的异常（如缺页）条件产生的。
  - 处理器探测异常（processor-detected exception）: cpu执行指令时探测到的反常条件所产生的异常。根据cpu产生异常时保存在x86的`eip`寄存器或arm64的`pc`寄存器中的值，可以分为3组:
    - 故障（fault）: 保存在x86的`eip`寄存器或arm64的`pc`寄存器中的值是引起故障的指令地址，异常处理程序执行完后，那条指令重新执行，如缺页异常，纠正引起缺页异常的反常条件后重新执行同一指令。
    - 陷阱（trap）: 保存在x86的`eip`寄存器或arm64的`pc`寄存器中的值是随后要执行的指令地址，只有当没有必要重新执行已终止的指令时，才触发陷阱，陷阱的主要用途是为了调试程序。
    - 异常中止（abort）: x86的`eip`寄存器或arm64的`pc`寄存器中不能保存引起异常的指令所在的确切位置，用于报告严重的错误，如硬件故障或系统表中无效的值或不一致的值。异常终止处理程序只能终止进程，别无选择。
  - 编程异常（programmed exception）: 编程者发出请求时发生。以下几种情况会发生编程异常: x86下`int`（用于触发中断）和`int3`（触发特定的中断3，用于断点），arm64的`SVC`（对应x86的`int`）和`BRK`（对应x86的`int3`），以及x86下的`into`（检查溢出）和`bound`（检查地址出界）指令检查的条件不为真时。控制单元把编程异常作为陷阱来处理，也叫软件中断（software interrupt），注意软件中断和中断下半部的软中断（softirq）不是一个概念，编程异常有两种用途: 执行系统调用和给调试程序通报一个特定的事件。

# 中断简介

连接到计算机的硬件有很多，如硬盘、鼠标、键盘等，cpu的速度比这些外围硬件设备高出几个数量级，轮询（polling）会让内核做很多无用功，所以需要中断这种机制让硬件在需要时通知内核。中断本质上是一种电信号，硬件设备在生成中断时不考虑与cpu的时钟同步，也就是中断随时可以产生，内核随时可能会被新来的中断打断。硬件设备产生的电信号直接送入中断控制器（interrupt controller unit，简单的电子芯片）的输入引脚。不同设备对应的中断不同，每个中断对应一个中断号，又叫中断请求（Interrupt ReQuest，IRQ）线，但有些中断号是动态分配的，如连接在PCI（Peripheral Component Interconnect）总线上的设备。

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

// devm: managed device
// 类似垃圾回收机制，不需要调用free_irq()
// 请参考补丁[at86rf230: use devm_request_irq](https://lore.kernel.org/all/1398359358-11085-5-git-send-email-alex.aring@gmail.com/)
static inline int __must_check
devm_request_irq(struct device *dev, unsigned int irq, irq_handler_t handler,
                 unsigned long irqflags, const char *devname, void *dev_id)
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

## 中断处理程序的实现

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

# 中断控制

控制中断系统是为了提供同步，通过禁止中断，可以确保某个中断处理程序不会抢占当前代码，还可以禁止内核抢占，但不能防止其他cpu的并发访问，禁止中断只能防止其他中断处理程序的并发访问。

禁止和激活当前处理器的本地中断，可以在中断上下文和进程上下文中使用:
```c
local_irq_disable(); // 禁止当前cpu本地中断
local_irq_enable(); // 激活当前cpu本地中断
```

激活时恢复到原来的状态，可以在中断上下文和进程上下文中使用:
```c
unsigned long flags;
local_irq_save(flags); // 禁止中断
local_irq_restore(flags); // 中断恢复到原来的状态
```

禁止（屏蔽掉，masking out）指定中断线，可以在中断上下文和进程上下文中使用，多个中断处理程序共享的中断线，不能用这些接口禁止中断。:
```c
// 禁止所有处理器指定的中断线，等待当前中断处理程序执行完
void disable_irq(unsigned int irq)
// 禁止所有处理器指定的中断线，不会等待当前中断处理程序执行完
void disable_irq_nosync(unsigned int irq)
// 激活所有处理器指定的中断线，嵌套时最后一次调用enable_irq时才真正激活中断线
void enable_irq(unsigned int irq)
// 等待特定的中断处理程序的退出
void synchronize_irq(unsigned int irq)
```

查询中断系统的状态:
```c
// 本地cpu上的中断系统被禁止返回非0，否则返回0
irqs_disabled()
/*
 * 宏用于检索当前执行上下文：
 *
 * in_nmi()             - 我们处于 NMI 上下文，Non-Maskable Interrupt 非屏蔽中断，一种高优先级中断，通常用于处理紧急事件，如硬件故障或性能监控
 * in_hardirq()         - 我们处于硬 IRQ 上下文
 * in_serving_softirq() - 我们处于 softirq 上下文
 * in_task()            - 我们处于任务上下文
 */
#define in_nmi()                (nmi_count())
#define in_hardirq()            (hardirq_count())
#define in_serving_softirq()    (softirq_count() & SOFTIRQ_OFFSET)
#define in_task()               (!(in_nmi() | in_hardirq() | in_serving_softirq()))
```

# 下半部

中断处理程序（又叫上半部，top half）执行时，最好的情况下，与该中断同级的中断（当然包括当前的中断线）会被屏蔽，中断处理程序要执行得越快越好，中断处理程序所做的事情越少越好，但至少要操作硬件对中断进行确认、有时要从硬件copy数据等，中断处理程序只能作为整个硬件处理流程的一部分，下半部（bottom half）执行与中断处理密切相关但中断处理程序本身不处理的工作。上半部和下半部的工作划分:

- 如果任务对时间敏感，放在上半部。
- 如果任务与硬件相关，放在上半部。
- 如果任务不能被其他中断打断（尤其是相同的中断），放在上半部。
- 其他所有任务，放到下半部。

一般下半部在中断处理程序一返回就会马上执行，下半部执行的时候，允许响应所有中断。有以下几种下半部机制:

- 已经废弃的BH: 接口简单，提供一个静态创建的链表，每个BH在全局范围内同步，永远不允许两个BH同时执行，有性能瓶颈。在v2.5放弃。
- 已经废弃的任务队列（task queues）: 当时是用来取代BH的，定义一组队列，每个队列包含一个由等待调用的函数组成的链表，对性能要求较高的子系统（如网络）不能胜任。在v2.5放弃。
- 软中断（softirq）: 静态定义的下半部接口，可以在所有cpu上同时执行，即使类型相同也可以。对性能要求较高的场景（如网络）使用软中断。
- tasklet: 基于软中断实现的灵活性强、动态创建的下半部实现机制，不同类型的tasklet可以在不同cpu上同时执行。
- 工作队列（work queues）: 取代任务队列，在进程上下文中执行。
- `threaded_irq`: 除了中断处理函数执行完，还会执行一个进程上下文的函数。
- 内核定时器: 也是软中断的一种（`TIMER_SOFTIRQ`），如果需要在确定的时间点运行某个操作，可以尝试使用定时器。

软中断和tasklet处于中断上下文中（所以不能休眠），工作队列和`threaded_irq`处于进程上下文中。

## 软中断

软中断（softirq）使用得比较少，网络和scsi子系统直接使用了软中断，内核定时器和tasklet都是基于软中断的。一个软中断不会抢占另一个软中断，软中断只能被中断处理程序抢占，软中断处理程序执行时当前cpu上的软中断被禁止，但其他软中断可以（相同类型的软中断也可以）在其他cpu上同时执行，所以要有严格的锁保护。

用以下结构表示:
```c
/* softirq 掩码和活动字段已移动到 irq_cpustat_t 中
 * asm/hardirq.h 以获得更好的缓存使用。  KAO
 */
struct softirq_action
{
        void    (*action)(struct softirq_action *);
};
```

定义含有`NR_SOFTIRQS`个软中断的数组，目前`HI_SOFTIRQ`优先级最高，`RCU_SOFTIRQ`优先级最低:
```c
static struct softirq_action softirq_vec[NR_SOFTIRQS]
```

待处理的软中断在以下地方被检查和执行:

- 硬件中断代码处返回时。
- `ksoftirqd`内核线程中。
- 显式检查和执行待处理软中断的代码中，如网络子系统。

软中断处理程序的一个例子是:
```c
void net_tx_action(struct softirq_action *h)
```

注册软中断处理程序:
```c
open_softirq(NET_TX_SOFTIRQ, net_tx_action);
```

在`__do_softirq()`中调用软中断处理程序:
```c
__u32 pending = local_softirq_pending(); // 读取待处理的位图
set_softirq_pending(0); // 将位图清0
while ((softirq_bit = ffs(pending))) {
        h = softirq_vec;
        h->action(h);
        h++;
        pending >>= softirq_bit; // 找到下一个待处理的位
}
```

触发软中断:
```c
// 会禁止中断，然后恢复原来的状态
raise_softirq(TIMER_SOFTIRQ);
// 如果中断已经被禁止，用这个函数会优化性能
raise_softirq_irqoff(NET_TX_SOFTIRQ);
```

内核中不会立刻处理重新触发的软中断，大量软中断出现时，内核会唤醒每个处理器上的`ksoftirqd/n`（`n`是处理器编号）来处理，这些线程优先级最低（`nice`值是`19`），具体请查看`struct smp_hotplug_thread softirq_threads`。

禁止和激活本地处理器的软中断和tasklet（tasklet基于软中断）用以下函数，可以嵌套使用:
```c
void local_bh_disable(void)
// 嵌套使用时最后一个local_bh_enable激活下半部
void local_bh_enable(void)
```

## tasklet

tasklet是用软中断实现的下半部机制（`HI_SOFTIRQ`和`TASKLET_SOFTIRQ`），注意名字中虽然有task，但和进程（任务）没有任何关系。

```c
/* Tasklets --- BH的多线程类比。

   此API已弃用。请考虑使用线程IRQ：
   https://lore.kernel.org/lkml/20200716081538.2sivhkj4hcyrusem@linutronix.de

   与通用softirqs的主要区别：tasklet   同时只在一个CPU上运行。

   与BH的主要区别：不同的tasklet
   可以在不同的CPU上同时运行。

   属性：
   * 如果调用tasklet_schedule()，则保证该tasklet将在此后至少在某个CPU上执行一次。
   * 如果tasklet已经被调度，但其执行尚未开始，它将仅执行一次。
   * 如果该tasklet已在另一个CPU上运行（或从tasklet本身调用调度），它将被重新调度以便稍后执行。
   * tasklet在自身方面是严格序列化的，但不与其他tasklet序列化。如果客户端需要某种任务间同步，则需使用自旋锁。
 */
struct tasklet_struct
{
        struct tasklet_struct *next;
        unsigned long state; // TASKLET_STATE_SCHED或TASKLET_STATE_RUN
        atomic_t count; // 引用计数
        bool use_callback;
        union {
                void (*func)(unsigned long data); // 处理函数
                void (*callback)(struct tasklet_struct *t);
        };
        unsigned long data; // 处理函数的参数
};
```

已调度的tasklet存放在下面两个链表:
```c
static DEFINE_PER_CPU(struct tasklet_head, tasklet_vec);
static DEFINE_PER_CPU(struct tasklet_head, tasklet_hi_vec);
```

由`tasklet_schedule()`（对应`TASKLET_SOFTIRQ`）和`tasklet_hi_schedule()`（对应`HI_SOFTIRQ`）调度，处理程序是`tasklet_action()`和`tasklet_hi_action()`。

静态创建tasklet:
```c
// .count初始化为0，激活状态
static DECLARE_TASKLET(fst_tx_task, fst_process_tx_work_q);
// .count初始化为1，禁止状态
static DECLARE_TASKLET_DISABLED(keyboard_tasklet, kbd_bh);
```

动态创建tasklet:
```c
tasklet_init(&ic->i_send_tasklet, rds_ib_tasklet_fn_send,
             (unsigned long)ic);
```

tasklet处理函数的一个例子:
```c
static void rds_ib_tasklet_fn_send(unsigned long data)
```

禁止或激活tasklet:
```c
void tasklet_disable(struct tasklet_struct *t)
// tasklet_disable_nosync不太安全，一般不用
void tasklet_disable_nosync(struct tasklet_struct *t)
// DECLARE_TASKLET_DISABLED创建的，也得用tasklet_enable激活
void tasklet_enable(struct tasklet_struct *t)
// 从挂起的队列中移去已调度的tasklet，先等待tasklet执行完成再移去，只能在进程上下文中使用（会休眠）
void tasklet_kill(struct tasklet_struct *t)
```

## 工作队列

工作队列（work queue）把工作交给内核线程执行，在进程上下文中，允许重新调度和休眠。

工作队列子系统提供了默认的工作者线程（worker thread），在`workqueue_init_early()`中创建了`system_wq`等工作队列，如果需要任务也可以创建自己的工作者列队，用以下结构表示:
```c
/*
 * 外部可见的工作队列。它将发出的工作项通过其 pool_workqueues 转发到适当的 worker_pool。
 */
struct workqueue_struct
```

所有的工作者线程都要执行`worker_thread()`，初始化后死循环并开始休眠，当有操作插入到队列中，线程唤醒执行。表示工作的数据结构如下:
```c
struct work_struct {
        atomic_long_t data;
        struct list_head entry;
        work_func_t func;
#ifdef CONFIG_LOCKDEP
        struct lockdep_map lockdep_map;
#endif
};
```

还有以下几个相关的结构体:
```c
/*
 * 做实际繁重工作的可怜家伙。所有在职工人要么担任经理角色，要么在空闲列表中，或在忙碌哈希中。
 * 有关锁注释（L、I、X...）的详细信息，请参阅 workqueue.c。
 *
 * 仅在工作队列和异步中使用。
 */
struct worker

struct worker_pool
```

`struct work_struct`对象在`worker_thread()`中用`worker_pool *pool`的`worklist`链表连接。

创建推后的工作:
```c
// 编译时静态创建
DECLARE_WORK(p9_poll_work, p9_poll_workfn);
DECLARE_DELAYED_WORK(name, func)
// 运行时动态创建
INIT_WORK(&priv->tx_onestep_tstamp, enetc_tx_onestep_tstamp);
INIT_DELAYED_WORK(_work, _func)
```

工作队列处理函数的一个例子是:
```c
void p9_poll_workfn(struct work_struct *work)
```

工作队列处理函数由工作者线程执行，运行在进程上下文中，但不能访问用户空间，因为内核线程在用户空间没有相关的内存映射（系统调用时内核代表用户空间进程运行，会映射用户空间内存）。

使用默认的工作队列进行调度:
```c
bool schedule_work(struct work_struct *work)
// 经过一段时间再执行
bool schedule_delayed_work(struct delayed_work *dwork, unsigned long delay)
```

刷新工作队列和取消延迟执行的工作:
```c
// 直到队列中所有对象执行完成，注意不会取消延迟执行的工作
flush_scheduled_work()
// 取消延迟执行的工作
bool cancel_delayed_work(struct delayed_work *dwork)
```

创建新的工作队列:
```c
create_workqueue(name)
// 调度执行工作, include/linux/workqueue.h
bool queue_work(struct workqueue_struct *wq, struct work_struct *work)
// 经过一段时间再执行
bool queue_delayed_work(struct workqueue_struct *wq, struct delayed_work *dwork, unsigned long delay)
// 刷新指定的工作队列
flush_workqueue(wq)
```

## `threaded_irq`

以下两个函数中，`handler`函数执行于中断上下文，`thread_fn`函数执行于内核线程（进程上下文），如果`handler`函数返回`IRQ_WAKE_THREAD`，`thread_fn`函数会被执行。

```c
/**
 *      request_threaded_irq - 分配一个中断线
 *      @irq: 要分配的中断线
 *      @handler: 当 IRQ 发生时调用的函数。
 *                线程中断的主要处理程序。
 *                如果 handler 为 NULL 且 thread_fn != NULL，
 *                则安装默认的主要处理程序 irq_default_primary_handler。
 *      @thread_fn: 从 irq 处理程序线程中调用的函数
 *                  如果为 NULL，则不创建 irq 线程
 *      @irqflags: 中断类型标志
 *      @devname: 设备的 ASCII 名称
 *      @dev_id: 传递回处理程序函数的 cookie
 *
 *      此调用分配中断资源并启用中断线和 IRQ 处理。从此调用开始，
 *      您的处理程序函数可能会被调用。由于您的处理程序函数必须清除
 *      电路板引发的任何中断，因此您必须注意初始化硬件并按照正确的
 *      顺序设置中断处理程序。
 *
 *      如果您想为设备设置线程化 irq 处理程序，则需要提供 @handler 和 
 *      @thread_fn。@handler 仍在硬中断上下文中调用，并且必须检查中断
 *      是否来自该设备。如果是，它需要禁用设备上的中断并返回 
 *      IRQ_WAKE_THREAD，这将唤醒处理程序线程并运行 @thread_fn。
 *      这种分离的处理程序设计是支持共享中断所必需的。
 *
 *      dev_id 必须是全局唯一的。通常使用设备数据结构的地址作为 cookie。
 *      由于处理程序接收此值，因此使用它是有意义的。
 *
 *      如果您的中断是共享的，您必须传递非 NULL dev_id，因为这在释放
 *      中断时是必需的。
 *
 *      标志：
 *
 *      IRQF_SHARED             中断是共享的
 *      IRQF_TRIGGER_*          指定活动边缘或电平
 *      IRQF_ONESHOT            运行 thread_fn 时屏蔽中断线，thread_fn执行后重新使能中断线
 */
int request_threaded_irq(unsigned int irq, irq_handler_t handler,
                         irq_handler_t thread_fn, unsigned long irqflags,
                         const char *devname, void *dev_id)

/**
 *      devm_request_threaded_irq - 为受管设备分配中断线
 *      @dev: 请求中断的设备
 *      @irq: 要分配的中断线
 *      @handler: 当 IRQ 发生时调用的函数，如果 handler 为 NULL 且 thread_fn != NULL，
 *            则安装默认的主要处理程序 irq_default_primary_handler。
 *      @thread_fn: 在线程中断上下文中调用的函数。如果设备在 @handler 中处理所有内容，则为 NULL
 *      @irqflags: 中断类型标志
 *      @devname: 设备的 ASCII 名称，如果为 NULL，则使用 dev_name(dev)
 *      @dev_id: 传递回处理程序函数的 cookie
 *
 *      除了额外的 @dev 参数外，此函数接受相同的参数并执行与
 *      request_threaded_irq() 相同的功能。使用此函数请求的 IRQ 将在
 *      驱动程序卸载时自动释放。
 *
 *      如果使用此函数分配的 IRQ 需要单独释放，则必须使用 devm_free_irq()。
 */
// devm: managed device
// 类似垃圾回收机制，不需要调用free_irq()
// 请参考补丁[at86rf230: use devm_request_irq](https://lore.kernel.org/all/1398359358-11085-5-git-send-email-alex.aring@gmail.com/)
int devm_request_threaded_irq(struct device *dev, unsigned int irq,
                              irq_handler_t handler, irq_handler_t thread_fn,
                              unsigned long irqflags, const char *devname,
                              void *dev_id)
```
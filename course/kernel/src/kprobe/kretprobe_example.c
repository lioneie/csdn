// SPDX-License-Identifier: GPL-2.0-only
/*
 * kretprobe_example.c
 *
 * Here's a sample kernel module showing the use of return probes to
 * report the return value and total time taken for probed function
 * to run.
 *
 * usage: insmod kretprobe_example.ko func=<func_name>
 *
 * If no func_name is specified, kernel_clone is instrumented
 *
 * For more information on theory of operation of kretprobes, see
 * Documentation/trace/kprobes.rst
 *
 * Build and insert the kernel module as done in the kprobe example.
 * You will see the trace data in /var/log/messages and on the console
 * whenever the probed function returns. (Some messages may be suppressed
 * if syslogd is configured to eliminate duplicate messages.)
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kprobes.h>
#include <linux/ktime.h>
#include <linux/sched.h>

// int ext2_readdir(struct file *file, struct dir_context *ctx)
static char func_name[KSYM_NAME_LEN] = "ext2_readdir";
module_param_string(func, func_name, KSYM_NAME_LEN, 0644);
MODULE_PARM_DESC(func, "Function to kretprobe; this module will report the"
			" function's execution time");

/* per-instance private data */
struct my_data {
	ktime_t entry_stamp;
};

/* Here we use the entry_handler to timestamp function entry */
static int entry_handler(struct kretprobe_instance *ri, struct pt_regs *regs)
{
	struct my_data *data;
	struct file *file;
	struct dir_context *ctx;
	struct dentry *tmp;

	if (!current->mm)
		return 1;	/* Skip kernel threads */

	data = (struct my_data *)ri->data;
	data->entry_stamp = ktime_get();
// x86_64函数参数用到的寄存器: RDI, RSI, RDX, RCX, R8, R9
#ifdef CONFIG_X86
	file = (struct file *)regs->di;
	ctx = (struct dir_context *)regs->si;
	pr_info("ip = %lx, flags = 0x%lx\n",
		regs->ip, regs->flags);
#endif
// aarch64函数参数用到的寄存器: X0 ~ X7
#ifdef CONFIG_ARM64
	file = (struct file *)regs->regs[0];;
	ctx = (struct dir_context *)regs->regs[1];;
	pr_info("pc = 0x%lx, pstate = 0x%lx\n",
		(long)regs->pc, (long)regs->pstate);
#endif
	struct inode *inode = file_inode(file);
	hlist_for_each_entry(tmp, &inode->i_dentry, d_u.d_alias)
		break;
	pr_info("dir name:%s, ctx:0x%p\n",
		tmp->d_name.name, ctx);
	return 0;
}
NOKPROBE_SYMBOL(entry_handler);

/*
 * Return-probe handler: Log the return value and duration. Duration may turn
 * out to be zero consistently, depending upon the granularity of time
 * accounting on the platform.
 */
static int ret_handler(struct kretprobe_instance *ri, struct pt_regs *regs)
{
	unsigned long retval = regs_return_value(regs);
	struct my_data *data = (struct my_data *)ri->data;
	s64 delta;
	ktime_t now;

	now = ktime_get();
	delta = ktime_to_ns(ktime_sub(now, data->entry_stamp));
	pr_info("%s returned %lu and took %lld ns to execute\n",
			func_name, retval, (long long)delta);
	return 0;
}
NOKPROBE_SYMBOL(ret_handler);

static struct kretprobe my_kretprobe = {
	.handler		= ret_handler,
	.entry_handler		= entry_handler,
	.data_size		= sizeof(struct my_data),
	/* Probe up to 20 instances concurrently. */
	.maxactive		= 20,
};

static int __init kretprobe_init(void)
{
	int ret;

	my_kretprobe.kp.symbol_name = func_name;
	ret = register_kretprobe(&my_kretprobe);
	if (ret < 0) {
		pr_err("register_kretprobe failed, returned %d\n", ret);
		return ret;
	}
	pr_info("Planted return probe at %s: %p\n",
			my_kretprobe.kp.symbol_name, my_kretprobe.kp.addr);
	return 0;
}

static void __exit kretprobe_exit(void)
{
	unregister_kretprobe(&my_kretprobe);
	pr_info("kretprobe at %p unregistered\n", my_kretprobe.kp.addr);

	/* nmissed > 0 suggests that maxactive was set too low. */
	pr_info("Missed probing %d instances of %s\n",
		my_kretprobe.nmissed, my_kretprobe.kp.symbol_name);
}

module_init(kretprobe_init)
module_exit(kretprobe_exit)
MODULE_LICENSE("GPL");

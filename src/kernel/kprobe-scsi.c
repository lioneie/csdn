// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright (C) 2022 ChenXiaoSong
 */

#define DEV_NAME		"sda"
#define PART_OFFSET_SEC		(6291712UL) // Unit: @SECTOR_SZ
#define SECTOR_SZ		(4096UL)
#define EXT4_BS			(4096UL)
#define EXPECT_FILE_NAME 	"/mnt/file-expect"
#define EXPECT_FILE_SZ		(40UL*1024UL*1024UL)
#define SCSI_SEC_UNIT		(512UL)
#define SECTOR_FACTOR		(SECTOR_SZ/SCSI_SEC_UNIT)

// Unit: @SCSI_SEC_UNIT
#define FIRST_SEC_OF_RANGE(ext4_blknum)	((ext4_blknum)*EXT4_BS/SCSI_SEC_UNIT + \
					 PART_OFFSET_SEC*SECTOR_FACTOR)
#define  LAST_SEC_OF_RANGE(ext4_blknum)	((ext4_blknum)*EXT4_BS/SCSI_SEC_UNIT + \
					 PART_OFFSET_SEC*SECTOR_FACTOR + \
					 EXT4_BS/SCSI_SEC_UNIT-1UL)

#define DECLARE_SEC_RANGE_ARR \
	static struct disk_sec_range sec_range_arr[] = {\
		{FIRST_SEC_OF_RANGE(663552UL), LAST_SEC_OF_RANGE(663552UL)}, \
		{FIRST_SEC_OF_RANGE(663553UL), LAST_SEC_OF_RANGE(663553UL)}, \
		{FIRST_SEC_OF_RANGE(663554UL), LAST_SEC_OF_RANGE(673791UL)}, \
	};

#define pr_fmt(fmt) "%s: " fmt, __func__

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/syscalls.h>
#include <linux/kprobes.h>

#include <linux/bio.h>
#include <linux/bitops.h>
#include <linux/blkdev.h>
#include <linux/completion.h>
#include <linux/kernel.h>
#include <linux/export.h>
#include <linux/init.h>
#include <linux/pci.h>
#include <linux/delay.h>
#include <linux/hardirq.h>
#include <linux/scatterlist.h>
#include <linux/blk-mq.h>
#include <linux/ratelimit.h>
#include <asm/unaligned.h>

#include <scsi/scsi.h>
#include <scsi/scsi_cmnd.h>
#include <scsi/scsi_dbg.h>
#include <scsi/scsi_device.h>
#include <scsi/scsi_driver.h>
#include <scsi/scsi_eh.h>
#include <scsi/scsi_host.h>
#include <scsi/scsi_transport.h> /* __scsi_init_queue() */
#include <scsi/scsi_dh.h>

#include <trace/events/scsi.h>

#include <../drivers/scsi/scsi_debugfs.h>
#include <../drivers/scsi/scsi_priv.h>
#include <../drivers/scsi/scsi_logging.h>

struct disk_sec_range {
	sector_t min;
	sector_t max;
};

static char write_symbol[KSYM_NAME_LEN] = "scsi_dispatch_cmd";
static char  read_symbol[KSYM_NAME_LEN] = "scsi_finish_command";
DECLARE_SEC_RANGE_ARR

static struct kprobe write_kp = {
	.symbol_name	= write_symbol,
};
static struct kprobe read_kp = {
	.symbol_name	= read_symbol,
};

static char expect_buf[EXPECT_FILE_SZ];
static struct file *file = NULL;

static bool scsi_is_write(struct scsi_cmnd *cmd)
{
	return (cmd->cmnd[0] == WRITE_6) || (cmd->cmnd[0] == WRITE_10) ||
	       (cmd->cmnd[0] == WRITE_12) || (cmd->cmnd[0] == WRITE_16) ||
	       (cmd->cmnd[0] == WRITE_32);
}

static bool scsi_is_read(struct scsi_cmnd *cmd)
{
	return (cmd->cmnd[0] == READ_6) || (cmd->cmnd[0] == READ_10) ||
	       (cmd->cmnd[0] == READ_12) || (cmd->cmnd[0] == READ_16) ||
	       (cmd->cmnd[0] == READ_32);
}

/* Just copy from scsi_dispatch_cmd() */
static bool scsi_dispatch_cmd_check(struct scsi_cmnd *cmd)
{
	struct Scsi_Host *host;

	if (!cmd || !cmd->device || !cmd->device->host)
		return false;

	host = cmd->device->host;

	/* check if the device is still usable */
	if (unlikely(cmd->device->sdev_state == SDEV_DEL)) {
		return false;
	}
	/* Check to see if the scsi lld made this device blocked. */
	if (unlikely(scsi_device_blocked(cmd->device))) {
		return false;
	}
	/*
	 * Before we queue this command, check if the command
	 * length exceeds what the host adapter can handle.
	 */
	if (cmd->cmd_len > cmd->device->host->max_cmd_len) {
		return false;
	}
	if (unlikely(host->shost_state == SHOST_DEL)) {
		return false;
	}
	return true;
}

static void print_err_data(char *expect_arr, char *data_arr,
			   unsigned long len, unsigned long expect_offset)
{
	unsigned long i;
	for (i = 0; i < len; i++) {
		char expect = expect_arr[i];
		char data = data_arr[i];
		if (data != expect) {
			printk("pos:%lx, data:%02x, expect:%02x\n",
			       expect_offset+i, data, expect&0xff);
		}
	}
}

static void check_scsi_data(struct scsi_cmnd *cmd, struct kprobe *p)
{
	char *scsi_buf;
	unsigned long i = 0;
	bool condition;
	unsigned long range_cnt = sizeof(sec_range_arr) / sizeof(struct disk_sec_range);
	bool is_write = scsi_is_write(cmd);
	bool is_read = scsi_is_read(cmd);
	sector_t sec = cmd->request->__sector;
	unsigned long len = cmd->request->__data_len;
	unsigned long expect_offset;

	condition = (is_write && !is_read) || (!is_write && is_read);
	if (!condition)
		return;

	condition = (cmd->request->rq_disk != NULL &&
	             !strncmp(cmd->request->rq_disk->disk_name, DEV_NAME, 3));
	if (!condition) {
		return;
	}

	condition = false;
	expect_offset = 0;
	for (i = 0; i < range_cnt; i++) {
		struct disk_sec_range range = sec_range_arr[i];
		if (sec >= range.min && sec <= range.max) {
			condition = true;
			expect_offset += (sec-range.min) * SCSI_SEC_UNIT;
			break;
		}
		expect_offset += (range.max-range.min+1) * SCSI_SEC_UNIT;
	}
	if (!condition) {
		return;
	}

	scsi_buf = kmalloc(len, GFP_KERNEL);
	if (!scsi_buf)
		return;
	sg_copy_to_buffer(cmd->sdb.table.sgl, cmd->sdb.table.nents,
			   scsi_buf, len);
	if (memcmp(expect_buf+expect_offset, scsi_buf, len) != 0) {
		printk("%s, %s, scsi check data error, sector:%ld, len:%ld, "
		       "expect offset:%ld\n",
		       p->symbol_name, (is_write ? "write" : "read"), sec, len,
		       expect_offset);
		print_err_data(expect_buf+expect_offset, scsi_buf, len, expect_offset);
	}

	kfree(scsi_buf);
}

static int __kprobes write_handler_pre(struct kprobe *p, struct pt_regs *regs)
{
	struct scsi_cmnd *cmd;
#ifdef CONFIG_X86
	cmd = (struct scsi_cmnd *)regs->di;
#endif
#ifdef CONFIG_ARM64
	cmd = (struct scsi_cmnd *)regs->regs[0];
#endif
	if (cmd->sc_data_direction != DMA_TO_DEVICE)
		return 0;

	if (!scsi_dispatch_cmd_check(cmd)) {
		return 0;
	}

	check_scsi_data(cmd, p);

	/* A dump_stack() here will give a stack backtrace */
	return 0;
}

static int __kprobes read_handler_pre(struct kprobe *p, struct pt_regs *regs)
{
	struct scsi_cmnd *cmd;
#ifdef CONFIG_X86
	cmd = (struct scsi_cmnd *)regs->di;
#endif
#ifdef CONFIG_ARM64
	cmd = (struct scsi_cmnd *)regs->regs[0];
#endif
	if (cmd->sc_data_direction != DMA_FROM_DEVICE)
		return 0;

	check_scsi_data(cmd, p);

	/* A dump_stack() here will give a stack backtrace */
	return 0;
}

static bool read_expect_data(void)
{
	loff_t pos;
	long res;

	file = filp_open(EXPECT_FILE_NAME, O_RDONLY, 0644);

	if (IS_ERR(file)) {
		printk("error occured while opening file %s, exiting...\n",
		       EXPECT_FILE_NAME);
		file = NULL;
		return false;
	}

	pos = 0;
	res = kernel_read(file, expect_buf, EXPECT_FILE_SZ, &pos);

	if (res > 0) {
		printk("kernel_read success, res: %ld\n", res);
	} else {
		printk("read data fail, res: %ld\n", res);
		filp_close(file, NULL);  
		file = NULL;
		return false;
	}
	return true;
}

static int __init kprobe_init(void)
{
	int ret;

	if (!read_expect_data())
		return -1;

	write_kp.pre_handler = write_handler_pre;
	ret = register_kprobe(&write_kp);
	if (ret < 0) {
		pr_err("register_kprobe failed, returned %d\n", ret);
		return ret;
	}
	pr_info("Planted kprobe at %p\n", write_kp.addr);

	read_kp.pre_handler = read_handler_pre;
	ret = register_kprobe(&read_kp);
	if (ret < 0) {
		pr_err("register_kprobe failed, returned %d\n", ret);
		return ret;
	}
	pr_info("Planted kprobe at %p\n", read_kp.addr);

	return 0;
}

static void __exit kprobe_exit(void)
{
	unregister_kprobe(&write_kp);
	pr_info("kprobe at %p unregistered\n", write_kp.addr);

	unregister_kprobe(&read_kp);
	pr_info("kprobe at %p unregistered\n", read_kp.addr);

	if(file) {
		filp_close(file, NULL);
	}
}

module_init(kprobe_init)
module_exit(kprobe_exit)
MODULE_LICENSE("GPL");

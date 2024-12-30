# SPDX-License-Identifier: GPL-2.0-only
# builds the kprobes example kernel modules;
# then to use one (as root):  insmod <module_name.ko>

obj-m += kretprobe_smb.o

ARCH=arm64
CROSS_COMPILE='aarch64-linux-gnu-'

KDIR := /home/sonvhi/chenxiaosong/code/linux/aarch64-build
PWD     := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} clean

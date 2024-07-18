# SPDX-License-Identifier: GPL-2.0-only
# builds the kprobes example kernel modules;
# then to use one (as root):  insmod <module_name.ko>

obj-m += kretprobe_smb.o

ARCH=arm64
CROSS_COMPILE='aarch64-linux-gnu-'

KDIR := /home/sonvhi/chenxiaosong/code/tmp-linux/build

all:
	make -C ${KDIR} M=`pwd` ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}

clean:
	rm -f *.ko *.o *.mod *.mod.o *.mod.c .*.cmd *.symvers  modul*

# SPDX-License-Identifier: GPL-2.0-only
# builds the kprobes example kernel modules;
# then to use one (as root):  insmod <module_name.ko>

obj-m += kprobe_example.o
obj-m += kretprobe_example.o

CROSS_COMPILE=''

KDIR := /home/linux/code/linux/build

all:
	make -C ${KDIR} M=`pwd`

clean:
	rm -f *.ko *.o *.mod *.mod.o *.mod.c .*.cmd *.symvers  modul*

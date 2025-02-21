# SPDX-License-Identifier: GPL-2.0-or-later
#
# Makefile for kernel socket example.
#

obj-m += kernel-socket-server.o
obj-m += kernel-socket-client.o

KDIR	:= /home/sonvhi/chenxiaosong/code/linux/x86_64-build/
PWD	:= $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean


obj-m += kprobe-df-long-time.o

# ARCH=arm64
# CROSS_COMPILE='aarch64-linux-gnu-'

KDIR	:= /home/sonvhi/chenxiaosong/code/linux/x86_64-build
PWD     := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} clean


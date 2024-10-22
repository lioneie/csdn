obj-m += kprobe-df-long-time.o

CROSS_COMPILE=''

KDIR := /home/sonvhi/chenxiaosong/code/x86_64-linux/build

all:
	make -C ${KDIR} M=`pwd`

clean:
	rm -f *.ko *.o *.mod *.mod.o *.mod.c .*.cmd *.symvers  modul*

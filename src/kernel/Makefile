obj-m += kprobe-scsi.o

KDIR := /home/sonvhi/chenxiaosong/code/aarch64-4.19

all:
	make -C ${KDIR} M=`pwd`

clean:
	rm -f *.ko *.o *.mod *.mod.o *.mod.c .*.cmd *.symvers  modul*

obj-m += kprobe-df-long-time.o

CROSS_COMPILE=''

KDIR := /home/linux/code/linux/build

all:
	make -C ${KDIR} M=`pwd`

clean:
	rm -f *.ko *.o *.mod *.mod.o *.mod.c .*.cmd *.symvers  modul*

obj-m += crash-test.o

KBUILD_CFLAGS += -g

KDIR := /home/linux/code/linux/build

all:
	make -C ${KDIR} M=`pwd`

clean:
	rm -f *.ko *.o *.mod *.mod.o *.mod.c .*.cmd *.symvers  modul*

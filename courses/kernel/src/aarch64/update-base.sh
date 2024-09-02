kernel_version=aarch64-klinux-4.19

qemu-system-aarch64 \
-smp 8 \
-m 4096 \
-machine virt \
-cpu cortex-a72 \
-kernel /home/sonvhi/chenxiaosong/code/$kernel_version/build/arch/arm64/boot/Image \
--virtfs local,id=kmod_dev,path=/home/sonvhi/chenxiaosong/,security_model=none,mount_tag=9p \
-device virtio-scsi-pci \
-net nic,model=virtio,macaddr=00:11:22:33:44:55 \
-net bridge,br=virbr0 \
-drive file=aarch64-bullseye.qcow2,if=none,cache=none,id=root,format=qcow2,file.locking=off \
-device virtio-blk,drive=root,id=d_root \
-append "nokaslr console=ttyAMA0 root=/dev/vda rw kmemleak=on" \
-nographic \

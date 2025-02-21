array=(1 2 3 4)
image_type=`basename $(pwd)`
dst_path=$(pwd)/../../vm/

for element in ${array[@]}
do
	if [ ! -d "${dst_path}/${element}.${image_type}" ]
	then
		echo "*******************${element}.${image_type}: path do not exist************"
		exit 1
	fi
	rm ${dst_path}/${element}.${image_type}/image.qcow2 -rf
	qemu-img create -F qcow2 -b $(pwd)/${image_type}.qcow2 -f qcow2 ${dst_path}${element}.${image_type}/image.qcow2
	if [ $? -ne 0 ]
	then
		exit 1
	fi

	cp update-base.sh ${dst_path}/${element}.${image_type}/start.sh
	format_num=$(printf "%02d\n" ${element})
	gdb_port=`expr 5550 + $element`
	sed -i "s/00:11:22:33:44:55/00:11:22:33:44:${format_num}/g" ${dst_path}/${element}.${image_type}/start.sh
	sed -i "s/${image_type}.qcow2/image.qcow2/g" ${dst_path}/${element}.${image_type}/start.sh
	echo "-drive file=1,if=none,format=raw,cache=writeback,file.locking=off,id=dd_1 \\" >> ${dst_path}/${element}.${image_type}/start.sh
	echo "-device scsi-hd,drive=dd_1,id=disk_1,logical_block_size=4096,physical_block_size=4096 \\" >> ${dst_path}/${element}.${image_type}/start.sh
	echo "-drive file=2,if=none,format=raw,cache=writeback,file.locking=off,id=dd_2 \\" >> ${dst_path}/${element}.${image_type}/start.sh
	echo "-device scsi-hd,drive=dd_2,id=disk_2,logical_block_size=4096,physical_block_size=4096 \\" >> ${dst_path}/${element}.${image_type}/start.sh
	echo "-drive file=nvme1,if=none,format=raw,cache=writeback,file.locking=off,id=b_nvme_1 \\" >> ${dst_path}/${element}.${image_type}/start.sh
	echo "-device nvme,drive=b_nvme_1,serial=d_b_nvme_1 \\" >> ${dst_path}/${element}.${image_type}/start.sh
	echo "-drive file=nvme2,if=none,format=raw,cache=writeback,file.locking=off,id=b_nvme_2 \\" >> ${dst_path}/${element}.${image_type}/start.sh
	echo "-device nvme,drive=b_nvme_2,serial=d_b_nvme_2 \\" >> ${dst_path}/${element}.${image_type}/start.sh
	echo "-gdb tcp::${gdb_port} \\" >> ${dst_path}/${element}.${image_type}/start.sh
done

echo "###############successful####################"

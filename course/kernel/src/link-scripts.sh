. ~/.top-path
base_image_path=${MY_TOP_PATH}/qemu-kernel/base_image

arch_array=(	x86_64		aarch64	)
release_array=(	bullseye	bullseye)

num=${#arch_array[@]}
idx=0
while(( $idx < $num ))
do
	dst_path=${base_image_path}/${arch_array[$idx]}-${release_array[$idx]}/create-qcow2.sh
	rm ${dst_path}
	ln -s ${PWD}/${arch_array[$idx]}/create-qcow2.sh ${dst_path}
	dst_path=${base_image_path}/${arch_array[$idx]}-${release_array[$idx]}/update-base.sh
	rm ${dst_path}
	ln -s ${PWD}/${arch_array[$idx]}/update-base.sh ${dst_path}
	idx=`expr ${idx} + 1`
done

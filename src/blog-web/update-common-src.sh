. ~/.top-path

code_path=${MY_CODE_TOP_PATH}
# 导入其他脚本
. ${code_path}/blog/src/blog-web/common-lib.sh

scan_gitee_md() {
	local -n file_array=$1 # 不能命名成array
	md_dir="${md_dir%/}/" # 确保目录末尾有 /
	# 使用 find 命令查找所有 .md 文件并将结果存储到 array 数组中
	while IFS= read -r md_file; do
		# md_file=${md_file/$md_dir} # 干掉前缀
		file_array+=(${md_file})
	done < <(find ${md_dir} -type f -name "*.md")
}

update_md_sign() {
	local md_dir=$1
	local array=()

	scan_gitee_md array

	local sign_file=${code_path}/blog/src/blog-web/sign.md
	local begin_str='<!-- sign begin -->'
	local end_str='<!-- sign end -->'
	local element_count="${#array[@]}" # 总个数
	local count_per_line=1
	for ((index=0; index<${element_count}; index=$((index + ${count_per_line}))))
	do
		local src_file=${array[${index}]}

		comm_rm_mid_lines "${begin_str}" "${end_str}" ${src_file}
		remove_line "${begin_str}" ${src_file}
		remove_line "${end_str}" ${src_file}
		cat ${sign_file} >> ${src_file}.tmp
		cat ${src_file} >> ${src_file}.tmp
		mv ${src_file}.tmp ${src_file}
	done
}

update_common_src() {
	local src_file=$1
	local dst_file=$2
	local begin_str=$3
	local end_str=$4

	cp ${src_file} ${src_file}.tmp
	sed -i "/${begin_str}/,/${end_str}/!d" ${src_file}.tmp # 只保留begin到end的内容
	sed -i '1d;$d' ${src_file}.tmp # 删除第一行和最后一行
	comm_rm_mid_lines "${begin_str}" "${end_str}" "${dst_file}"
	sed -i -e "/${begin_str}/r ${src_file}.tmp" ${dst_file}
	rm ${src_file}.tmp
}

update_md_sign "${code_path}/blog/src/gitee-md/"

. ~/.top-path
MY_ECHO_DEBUG=0

src_path=${MY_CODE_TOP_PATH}/blog

tmp_src_path=$1

. ${src_path}/src/blog-web/common-lib.sh

# add_common array[@] ${common_file}
add_common() {
	local except_array=("${!1}") # 使用间接引用来接收数组
	local array=("${!2}") # 使用间接引用来接收数组
	local target_path=$3

	local common_file=${target_path}/common.md

	local element_count="${#array[@]}" # 总个数
	local count_per_line=1
	for ((index=0; index<${element_count}; index=$((index + ${count_per_line}))))
	do
		local ifile=${array[${index}]}

		if [[ ${ifile} == ${common_file} ]]; then
			continue
		fi

		local src_file=${src_path}/${ifile}
		local dst_file=${tmp_src_path}/${ifile}
		local dst_dir="$(dirname "${dst_file}")" # 所在的文件夹
		if [ ! -d "${dst_dir}" ]; then
			mkdir -p "${dst_dir}" # 文件夹不存在就创建
		fi
		comm_echo "src_file:${src_file}, dst_file:${dst_file}"

		comm_is_in_array except_array[@] ${ifile}
		if [[ $? == 0 ]]; then
			comm_echo "${ifile} do not add common"
			cp "${src_file}" "${dst_file}" # 只复制
			continue
		fi

		cp ${common_file} ${dst_file}
		cat ${src_file} >> ${dst_file}
	done
}

scan_md() {
	local -n array_ref=$1
	local target_path=$2
	local mid_path=$3

	target_path="${target_path%/}/" # 确保目录末尾有 /
	# 使用 find 命令查找所有 .md 文件并将结果存储到 array 数组中
	while IFS= read -r md_file; do
		md_file="${md_file/$target_path}" # 干掉前缀
		md_file=$(comm_normalize_path "${mid_path}/${md_file}")
		comm_echo "${md_file}"
		# 追加到数组中
		array+=("${md_file}")
	done < <(find "${target_path}" -type f -name "*.md")
}

create_full_course_md() {
	local course=$1

	local mid_path="courses/${course}/"
	local target_path=${src_path}/${mid_path}
	local except_array=(
		courses/${course}/${course}.md
	)
	local array=()
	scan_md array "${target_path}" "${mid_path}"
	add_common except_array[@] array[@] "${target_path}"
}

create_full_course_md "kernel"
create_full_course_md "nfs"
create_full_course_md "smb"
create_full_course_md "algorithms"


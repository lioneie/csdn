#!/bin/bash
. ~/.top-path
tmp_repo_path=${MY_CODE_TOP_PATH}/tmp/

. ${MY_CODE_TOP_PATH}/blog/src/blog-web/common-lib.sh

parse_line() {
	local line=$1
	local file=$2

	# 获取第3和第4个字符（从0开始）
	local word1="${line:3:1}" # 汉字也是一个字符？
	local word2="${line:4:1}"

	local modified_line="${line}"
	# 如果第3和第4个字符相同，则删除第4个字符
	if [ "${word1}" == "${word2}" ]; then
		# 删除第4个字符
		modified_line="${line:0:3}${line:4}"
		word2=""
	fi

	if [[ -z "${word2}" || "${word2}" =~ ^[0-9]+$ ]]; then
		echo "${word1} 没有繁体字"
	else
		echo "${word1} 有繁体字"
		echo "${modified_line}" >> "traditional-${file}"
	fi

	# 输出处理后的行
	echo "${modified_line}" >> "${file}.tmp"
}

parse_frequently_used() {
	local file=$1
	> "traditional-${file}" # 清空

	# 读取文件并处理每一行
	while IFS= read -r line; do
		parse_line "${line}" "${file}"
	done < "${file}"
	mv "${file}.tmp" "${file}"
}

cd ${tmp_repo_path}/calligraphy/frequently-used/
parse_frequently_used 500.md
parse_frequently_used 2500.md

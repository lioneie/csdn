#!/bin/bash
. ~/.top-path
tmp_repo_path=${MY_CODE_TOP_PATH}/tmp/

. ${MY_CODE_TOP_PATH}/blog/src/blog-web/common-lib.sh

MY_ECHO_DEBUG=0

parse_line() {
	local line=$1
	local file=$2

	# 获取第1和第2个字符（从0开始）
	local word1="${line:0:1}"
	local word2="${line:1:1}"

	local modified_line="1. ${line}" # 加上序号

	# \t 两边必须是单引号
	if [[ "${word2}" == $'\t' ]]; then
		comm_echo "${word1} 没有繁体字"
	else
		comm_echo "${word1} 有繁体字"
		echo "${modified_line}" >> "traditional-${file}.md"
	fi

	# 输出处理后的行
	echo "${modified_line}" >> "${file}.tmp"
}

create_md() {
	local file=$1
	# 读取文件并处理每一行
	while IFS= read -r line; do
		parse_line "${line}" "${file}"
	done < "${file}.md"
	mv "${file}.tmp" "${file}.md"
}

deduplicate() {
	local file=$1

	# 读取文件并处理每一行
	while IFS= read -r line; do
		word1="${line:0:1}" # 汉字也是一个字符？
		word2="${line:1:1}"

		modified_line="${line}"
		if [ "${word1}" == "${word2}" ]; then
			modified_line=${word1} # 只保留第1个字
			comm_echo "${word1} 没有繁体字"
		else
			comm_echo "${word1} 有繁体字"
		fi
		echo "${modified_line}" >> "${file}.tmp"

	done < "${file}.txt"
	mv "${file}.tmp" "${file}.txt"
}

parse_frequently_used() {
	local file=$1

	deduplicate ${file}
	# 清空
	> "${file}.md"
	> "traditional-${file}.md"

	# 五笔网站:
	# 	https://toolb.cn/wbconvert (可选，默认全码优先)
	# 	https://tool.lu/py5bconvert/ (只能简码，还要用dos2unix转换，有些字没有，如"该")
	# 	https://toolkits.cn/wubi (全码和简码全部列出)
	if [ ! -f "${file}-wubi.txt" ]; then
		echo "${file}-wubi.txt 不存在"
		return
	else
		echo "${file}-wubi.txt 存在"
	fi

	paste ${file}.txt ${file}-wubi.txt > ${file}.md

	create_md ${file}
}

cd ${tmp_repo_path}/calligraphy/frequently-used/
parse_frequently_used 500
parse_frequently_used 2500


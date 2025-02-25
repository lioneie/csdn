#!/bin/bash

# 繁体字网站:
# 	https://www.2weima.com/jianfan.html （可选）
# 	http://www.ku51.net/ （可选）
# 	http://www.aies.cn/
# 	https://www.sojson.com/convert/cn2spark.html
# 	https://5ujq.com/

# 五笔网站:
# 	https://toolb.cn/wbconvert (可选，默认全码优先)
# 	https://tool.lu/py5bconvert/ (只能简码，还要用dos2unix转换，有些字没有，如"该")
# 	https://toolkits.cn/wubi (全码和简码全部列出)

. ~/.top-path
tmp_repo_path=${MY_CODE_TOP_PATH}/tmp/

. ${MY_CODE_TOP_PATH}/blog/src/blog-web/common-lib.sh

MY_ECHO_DEBUG=0

# 有繁体字返回0, 无繁体字返回1
parse_line() {
	local line=$1
	local file=$2
	local index=$3
	local traditional_index=$4

	local ret=1

	# 获取第1和第2个字符（从0开始）
	local word1="${line:0:1}"
	local word2="${line:1:1}"

	local all_line="${index}. ${line}" # 加上序号
	local traditional_line="${traditional_index}. ${line}"

	# \t 两边必须是单引号
	if [[ "${word2}" == $'\t' ]]; then
		comm_echo "${word1} 没有繁体字"
	else
		comm_echo "${word1} 有繁体字"
		echo "${traditional_line}" >> "${file}-traditional.md"
		ret=0
	fi

	# 输出处理后的行
	echo "${all_line}" >> "${file}.tmp"
	return $ret
}

create_md() {
	local file=$1
	# 读取文件并处理每一行
	local index=1
	local traditional_index=1
	while IFS= read -r line; do
		parse_line "${line}" "${file}" "${index}" "${traditional_index}"
		if [[ $? == 0 ]]; then
			traditional_index=$((traditional_index + 1))
		fi
		index=$((index + 1))
	done < "${file}.md"
	mv "${file}.tmp" "${file}.md"
}

__deduplicate() {
	local str=$1
	local ret=""
	for ((i=0; i<${#str}; i++)); do
		local word="${str:i:1}"
		if [[ ! "${ret}" =~ "${word}" ]]; then
			ret="${ret}${word}"
		fi
	done
	echo "${ret}"
}

deduplicate() {
	local file=$1

	local index=1
	# 读取文件并处理每一行
	while IFS= read -r line; do
		local raw_word="${line:0:1}"
		local wubi_words=$(sed -n ${index}p ${file}-raw-traditional.txt)
		local full_words="${raw_word}${wubi_words}"
		local dedup_words=$(__deduplicate ${full_words})
		local str_len="${#dedup_words}"

		# echo "${dedup_words} ${str_len}"
		if [ "${str_len}" == 1 ]; then
			comm_echo "${raw_word} 没有繁体字"
		else
			comm_echo "${raw_word} 有繁体字"
			echo "${dedup_words}" >> "${file}-traditional.txt"
		fi
		echo "${dedup_words}" >> "${file}.tmp"
		index=$((index + 1))
	done < "${file}-raw-simplified.txt"
	mv "${file}.tmp" "${file}.txt"
}

parse_frequently_used() {
	local file=$1

	cd ${tmp_repo_path}/calligraphy/frequently-used/${file}/
	# 清空
	> "${file}.txt"
	> "${file}.md"
	> "${file}-traditional.txt"
	> "${file}-traditional.md"

	deduplicate ${file}

	if [ ! -f "${file}-wubi.txt" ]; then
		echo "${file}-wubi.txt 不存在"
		return
	else
		echo "${file}-wubi.txt 存在"
	fi

	paste ${file}.txt ${file}-wubi.txt > ${file}.md

	create_md ${file}
}

parse_frequently_used 500
parse_frequently_used 2500
parse_frequently_used 1000


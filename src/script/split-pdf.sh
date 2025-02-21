. ~/.top-path
. ${MY_CODE_TOP_PATH}/blog/src/blog-web/common-lib.sh

# 检查参数
if [ $# -ne 1 ]; then
        echo "用法: bash $0 <pdf文件>"
        exit 1
fi
filename=$1

pages_per_file=100

split_pdf() {
	local filename=$1
	local pages_per_file=$2

	local full_path="$(realpath "${filename}")"
	local dir_path="$(dirname "${full_path}")"
	local total_pages=$(echo "$(pdftk ${filename} dump_data | grep NumberOfPages)" | awk -F': ' '{print $2}')
	local file_num=$(comm_ceil_divide ${total_pages} ${pages_per_file})
	echo "total_pages: ${total_pages}, full_path: ${full_path}, dir_path: ${dir_path}"

	for i in $(seq 1 ${file_num}); do
		local begin_page=$(( (i - 1) * pages_per_file + 1 ))
		local end_page=$(( i * pages_per_file ))
	    
		if [[ ${end_page} -gt ${total_pages} ]]; then
			end_page=${total_pages}
		fi
		echo "begin_page: ${begin_page}, end_page: ${end_page}"
		pdftk ${full_path} cat ${begin_page}-${end_page} output ${dir_path}/part${i}.${filename}
	done
}

split_pdf "${filename}" "${pages_per_file}"

# 合并就直接输入命令
# pdftk part1.pdf part2.pdf cat output merged.pdf
# pdftk part* cat output merged.pdf

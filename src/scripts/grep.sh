# 检查参数
if [ $# -ne 1 ]; then
        echo "用法: bash $0 <要查找的字符串>"
        exit 1
fi
string=$1

while IFS= read -r file; do
	if [[ "${file}" == "." || "${file}" == ".." || \
	      "${file}" == ".git" ]]; then
		continue
	fi
	grep -r "${string}" "${file}" # 也可以直接用 | grep -v "^\.git/"
done < <(printf "%s\n" "$(ls -1 -a)")


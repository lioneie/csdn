. ~/.top-path
code_path=${MY_CODE_TOP_PATH}
MY_ECHO_DEBUG=0

# 导入其他脚本
. ${code_path}/blog/src/blog-web/common-lib.sh

# 检查参数
if [ $# -ne 2 ]; then
        echo "用法: bash $0 <被替换的老字符串> <替换的新字符串>"
        exit 1
fi
old_string=$1
new_string=$2

sed_repo() {
	local repo=$1
	local repo_path="${code_path}/${repo}"

	if [ ! -d "${repo_path}" ]; then
		return
	fi
	cd "${repo_path}"

	while IFS= read -r file; do
		if [[ "${file}" == "." || "${file}" == ".." || \
		      "${file}" == ".git" ]]; then
			continue
		fi
		if [ -f "${file}" ]; then
			sed -i "s|${old_string}|${new_string}|g" "${file}"
		elif [ -d "${file}" ]; then
			find "${file}" -type f -exec sed -i "s|${old_string}|${new_string}|g" {} +
		fi
	done < <(printf "%s\n" "$(ls -1 -a)")
}

sed_repo "blog"
sed_repo "tmp"
sed_repo "private-blog"
sed_repo "private-tmp"
sed_repo "myfs"


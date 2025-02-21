. ~/.top-path
code_path=${MY_CODE_TOP_PATH}
MY_ECHO_DEBUG=0

# 导入其他脚本
. ${code_path}/blog/src/blog-web/common-lib.sh

# 检查参数
if [ $# -lt 1 ]; then
        echo "用法: bash $0 <要查找的字符串>"
        exit 1
fi
string=$1

grep_repo() {
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
		grep -rHnT "${string}" "${file}" # 也可以直接用 | grep -v "^\.git/"
	done < <(printf "%s\n" "$(ls -1 -a)")
}

grep_repo "blog"
grep_repo "tmp"
grep_repo "private-blog"
grep_repo "private-tmp"
grep_repo "myfs"


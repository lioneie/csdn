. ~/.top-path
code_path=${MY_CODE_TOP_PATH}
DEBUG=1

not_exist_repos=()
not_clean_repos=()
not_sync_repos=()
ok_repos=()

my_echo() {
	if [ "$DEBUG" -eq 1 ]; then
		echo "$@"
	fi
}

check_git() {
	local repo=$1
	local path=${code_path}/${repo}

	if [ ! -d "${path}" ]; then
		my_echo "${repo}目录不存在"
		not_exist_repos+=(${repo})
		return
	fi

	cd ${path}
	status=$(git status -s)

	if [ ! -z "${status}" ]; then
		my_echo "${repo}有未提交的更改:"
		my_echo "${status}"
		not_clean_repos+=(${repo})
		return
	fi

	git fetch origin
	if [ $? -ne 0 ]; then
		echo "!!! ${repo} fetch fail !!!"
		exit
	fi
	origin_commit=$(git rev-parse origin/master)
	master_commit=$(git rev-parse master)
	my_echo "${repo} origin_commit: ${origin_commit}"
	my_echo "${repo} master_commit: ${master_commit}"

	if [ "${origin_commit}" == "${master_commit}" ]; then
		my_echo "${repo}全部搞定"
		ok_repos+=(${repo})
	else
		my_echo "${repo}未push/pull"
		not_sync_repos+=(${repo})
	fi
}

print_result() {
	my_echo
	my_echo "未提交的仓库: ${not_clean_repos[@]}"
	my_echo "未push/pull的仓库: ${not_sync_repos[@]}"
	my_echo "不存在的仓库: ${not_exist_repos[@]}"
	my_echo "全部搞定的仓库: ${ok_repos[@]}"
}

check_git "blog"
check_git "tmp"
check_git "private-blog"
check_git "private-tmp"

print_result

. ~/.top-path
code_path=${MY_CODE_TOP_PATH}
MY_ECHO_DEBUG=0

# 导入其他脚本
. ${code_path}/blog/src/blog-web/common-lib.sh

not_exist_repos=()
not_clean_repos=()
not_sync_repos=()
ok_repos=()

print_result() {
	echo
	comm_print_array "not_exist_repos[@]" "$(comm_yellow_color)" "不存在的仓库:" "${not_exist_repos[@]}" "$(comm_no_color)"
	comm_print_array "ok_repos[@]" "$(comm_green_color)" "全部搞定的仓库:" "${ok_repos[@]}"  "$(comm_no_color)"
	comm_print_array "not_clean_repos[@]" "$(comm_red_color)" "未提交的仓库:" "${not_clean_repos[@]}" "$(comm_no_color)"
	comm_print_array "not_sync_repos[@]" "$(comm_red_color)" "未push/pull的仓库:" "${not_sync_repos[@]}" "$(comm_no_color)"
}

check_git() {
	local repo=$1
	comm_check_repo ${code_path}/${repo} not_exist_repos not_clean_repos not_sync_repos ok_repos
}

check_git "blog"
check_git "tmp"
check_git "private-blog"
check_git "private-tmp"
check_git "myfs"
. ${code_path}/private-blog/script/check-gitee.sh
print_result

. ~/.top-path
code_path=${MY_CODE_TOP_PATH}

reset_repo() {
	local repo=$1
	cd ${code_path}/${repo}
	git fetch origin
	git reset --hard origin/master
}

reset_repo "blog"
reset_repo "tmp"
reset_repo "private-blog"
reset_repo "private-tmp"
. ${code_path}/private-blog/others-blog/reset-gitee.sh
. ${code_path}/blog/src/blog-web/push-github.sh

. ~/.top-path
code_path=${MY_CODE_TOP_PATH}

machine=""
if [ $# -ge 1 ]; then
	machine=$1
fi
echo "machine: ${machine}"
if [[ "${machine}" != "aliyun-server" ]]; then
	echo "wrong machine"
	exit 1
fi

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
bash ${code_path}/blog/src/blog-web/push-github.sh false

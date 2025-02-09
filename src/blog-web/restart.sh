# 运行命令不断检查 while true; do bash restart.sh; sleep 90; done
. ~/.top-path
src_path=${MY_CODE_TOP_PATH}/blog # 替换为你的仓库路径
. ${src_path}/src/blog-web/common-lib.sh

is_replace_ip=true # 是否要替换ip
other_ip="${1:-$(comm_defaut_local_ip)}" # 内网要替换的ip

comm_create_params "${is_replace_ip}" "${other_ip}"

code_path=${MY_CODE_TOP_PATH} # 替换成你的仓库路径
is_restart=false # 是否重新启动

# 更新git仓库代码
# $1: 仓库名， $2: 是否推送到github
update_repo() {
	local repo=$1
	local is_github=$2
	# 如果是局域网ip，就不更新仓库
	if [ ${is_replace_ip} = true ]; then
		is_restart=true # 但要重启所有
		return
	fi
	cd ${code_path}/${repo}/
	timeout 20 git fetch origin # 最多20秒超时，有时会因为网络原因卡住
	local_head=$(git rev-parse HEAD)
	origin_head=$(git rev-parse origin/master)
	if [ "${local_head}" != "${origin_head}" ]; then
		timeout 20 git pull origin master
		is_restart=true
		if [ ${is_github} = true ]; then
			timeout 20 git push github master
		fi
	fi
	cd -
}

update_repo blog ${is_replace_ip} # 部署在公网服务器就推到github
update_repo tmp false # 不用推到github
update_repo private-blog false # 不用推到github

if [ "${is_restart}" = false ]; then
	echo "no change"
fi
bash ${code_path}/blog/src/blog-web/do-restart.sh ${is_replace_ip} ${other_ip} ${is_restart}

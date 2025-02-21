. ~/.top-path

if [ $# -ne 3 ]; then
	echo "Usage: $0 \${is_replace_ip} \${other_ip} \${is_restart}"
	exit 1
fi

is_replace_ip=$1
other_ip=$2 # 内网要替换的ip
is_restart=$3

src_path=${MY_CODE_TOP_PATH} # 替换成你的仓库路径
config_file=/etc/nginx/sites-enabled/default

copy_config() {
	rm ${config_file}
	bash ${src_path}/blog/src/blog-web/create-nginx-404.sh "${other_ip}"
	mv ${src_path}/blog/src/blog-web/nginx-config.full ${config_file}
	if [ ${is_replace_ip} = true ]; then
		# 局域网删除ssl相关配置
		sed -i '/# ssl begin/,/# ssl end/d' ${config_file} # 只能按行为单位删除
	fi
}

restart_private() {
	# 部署在局域网
	if [ ${is_replace_ip} = true ]; then
		bash ${src_path}/private-blog/script/create-html.sh ${other_ip}
	fi
}

restart_all() {
	if [ ${is_restart} = false ]; then
		return
	fi
	echo "recreate html, restart service"
	copy_config
	bash ${src_path}/blog/src/blog-web/create-html.sh ${is_replace_ip} ${other_ip}
	restart_private
	iptables -F # 根据情况决定是否要清空防火墙规则
	service nginx restart # 重启nginx服务，docker中不支持systemd
}

restart_all

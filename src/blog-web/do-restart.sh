if [ $# -ne 3 ]; then
    echo "Usage: $0 \${is_replace_ip} \${other_ip} \${is_restart}"
    exit 1
fi

is_replace_ip=$1
other_ip=$2 # 内网要替换的ip
is_restart=$3

src_path=/home/sonvhi/chenxiaosong/code # 替换成你的仓库路径
dst_path=/var/www/html
config_file=/etc/nginx/sites-enabled/default

copy_config() {
    rm ${config_file}
    cp ${src_path}/blog/src/blog-web/nginx-config ${config_file}
    if [ ${is_replace_ip} = false ]; then
        cat ${src_path}/blog/../private-blog/scripts/others-nginx-config >> ${config_file}
    else
        # 局域网删除ssl相关配置
        sed -i '/# ssl begin/,/# ssl end/d' ${config_file} # 只能按行为单位删除
    fi
}

restart_private() {
    # 部署在局域网
    if [ ${is_replace_ip} = true ]; then
        bash ${src_path}/private-blog/scripts/create-html.sh ${other_ip}
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

update_others_blog() {
    bash ${src_path}/private-blog/scripts/update-others-blog.sh ${is_restart} ${is_replace_ip}
}

restart_all
# update_others_blog

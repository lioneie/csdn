src_path=/home/sonvhi/chenxiaosong/code/blog # 替换为你的仓库路径
dst_path=/var/www
tmp_html_path=${dst_path}/html-tmp
html_path=${dst_path}/html
sign_path=${tmp_html_path}

is_public_ip=$1
lan_ip=$2

. ${src_path}/src/blog-web/common-lib.sh
. ${src_path}/src/blog-web/array.sh

init() {
    rm -rf ${tmp_html_path}
    mkdir -p ${tmp_html_path}
    bash ${src_path}/courses/courses.sh true
}

exit() {
    rm ${html_path}/ -rf
    mv ${tmp_html_path} ${html_path}
    bash ${src_path}/courses/courses.sh false
}

copy_secret_repository() {
    # pictures是我的私有仓库
    cp ${src_path}/../pictures/public/ ${tmp_html_path}/pictures -rf
}

copy_public_files() {
    # css样式
    cp ${src_path}/src/blog-web/stylesheet.css ${tmp_html_path}/
}

# 局域网签名
update_lan_sign() {
    local sign_file=${tmp_html_path}/sign.html
    # 局域网的处理
    if [[ ${is_public_ip} == false ]]; then
        replace_with_lan_ip ${sign_file} ${lan_ip}
        # 内网主页
        sed -i 's/主页/内网主页/g' ${sign_file}
        # 在<ul>之后插入公网主页
        sed -i -e '/<ul>/a<li><a href="https://chenxiaosong.com/">公网主页: chenxiaosong.com</a></li>' ${sign_file}
        # 私有仓库的脚本更改签名
        bash ${src_path}/../private-blog/scripts/update-sign.sh ${sign_file}
    fi
}

init
create_sign ${src_path}/src/blog-web/sign.md ${tmp_html_path}
update_lan_sign
create_html ${src_path} ${tmp_html_path} ${sign_path} ${is_public_ip} ${lan_ip}
copy_secret_repository
copy_public_files
change_perm ${tmp_html_path}
exit

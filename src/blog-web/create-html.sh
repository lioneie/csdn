src_path=/home/sonvhi/chenxiaosong/code/blog # 替换为你的仓库路径
dst_path=/var/www
tmp_html_path=${dst_path}/html-tmp
html_path=${dst_path}/html

is_public_ip=$1

. ${src_path}/src/blog-web/common-lib.sh
. ${src_path}/src/blog-web/array.sh

init_begin() {
    rm -rf ${tmp_html_path}
    mkdir -p ${tmp_html_path}
    bash ${src_path}/courses/courses.sh
}

init_end() {
    rm ${html_path}/ -rf
    mv ${tmp_html_path} ${html_path}
}

copy_secret_repository() {
    # pictures是我的私有仓库
    cp ${src_path}/../pictures/public/ ${tmp_html_path}/pictures -rf
}

copy_public_files() {
    # css样式
    cp ${src_path}/src/blog-web/stylesheet.css ${tmp_html_path}/
}

init_begin
create_sign ${src_path}/src/blog-web/sign.md ${tmp_html_path} ${is_public_ip}
create_html ${src_path} ${tmp_html_path}
copy_secret_repository
copy_public_files
change_perm ${tmp_html_path}
init_end

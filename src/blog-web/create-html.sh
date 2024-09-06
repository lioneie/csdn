src_path=/home/sonvhi/chenxiaosong/code # 替换为你的仓库路径
dst_path=/var/www
tmp_html_path=${dst_path}/html-tmp
html_path=${dst_path}/html

. ${src_path}/blog/src/blog-web/common-lib.sh
. ${src_path}/blog/src/blog-web/array.sh

init_begin() {
    mkdir -p ${tmp_html_path}
    bash ${src_path}/blog/courses/courses.sh
}

init_end() {
    rm ${html_path}/ -rf
    mv ${tmp_html_path} ${html_path}
}

copy_secret_repository() {
    # pictures是我的私有仓库
    cp ${src_path}/pictures/public/ ${tmp_html_path}/pictures -rf
}

copy_public_files() {
    # css样式
    cp ${src_path}/blog/src/blog-web/stylesheet.css ${tmp_html_path}/
}

init_begin
create_sign ${src_path}/blog/src/blog-web/sign.md ${tmp_html_path}
create_html ${src_path}/blog ${tmp_html_path}
copy_secret_repository
copy_public_files
change_perm ${tmp_html_path}
init_end

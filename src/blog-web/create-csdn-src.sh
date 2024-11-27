# 此脚本用于生成CSDN等博客网站的文件

src_path=/home/sonvhi/chenxiaosong/code/blog # 替换为你的仓库路径
dst_path=/home/sonvhi/chenxiaosong/csdn-src

. ${src_path}/src/blog-web/common-lib.sh
. ${src_path}/src/blog-web/array.sh

init() {
    rm -rf ${dst_path}
    bash ${src_path}/courses/courses.sh true
}

exit() {
    bash ${src_path}/courses/courses.sh false
}

change_private_perm() {
    chown -R sonvhi:sonvhi ${dst_path}
    chmod -R 770 ${dst_path}
}

__create_csdn_src() {
    local ifile=$1
    local ofile=$2
    local src_path=$3
    local dst_path=$4
    local src_file=$5

    local dst_file=${dst_path}/${ifile} # 输出文件
    local dst_dir="$(dirname "${dst_file}")" # 输出文件所在的文件夹
    if [ ! -d "${dst_dir}" ]; then
        mkdir -p "${dst_dir}" # 文件夹不存在就创建
    fi

    cd ${src_path}
    echo '<!--' >> ${dst_file}
    git log --oneline ${ifile} | head -n 1 >> ${dst_file}
    echo '--> ' >> ${dst_file}
    echo >> ${dst_file}

    echo '[建议点击这里查看个人主页上的最新原文](https://chenxiaosong.com/'${ofile}')' >> ${dst_file}
    echo >> ${dst_file}
    cat ${src_path}/src/blog-web/sign.md >> ${dst_file}
    echo >> ${dst_file}
    cat ${src_file} >> ${dst_file}

    create_src_for_header ${dst_file}
}

create_csdn_src() {
    local array=("${!1}")
    local src_path=$2
    local dst_path=$3

    local element_count="${#array[@]}" # 总个数
    local count_per_line=5
    for ((index=0; index<${element_count}; index=$((index + ${count_per_line})))); do
        local is_toc=${array[${index}]}
        local is_sign=${array[${index}+1]}
        local ifile=${array[${index}+2]}
        local ofile_or_ipathprefix=${array[${index}+3]}
        local html_title=${array[${index}+4]}
        local pandoc_options=$(get_pandoc_common_options)

        local ipath_prefix
        local ofile=${ofile_or_ipathprefix}
        local src_file=${src_path}/${ifile} # 源路径拼接
        if [[ ${ofile_or_ipathprefix} == ~ ]]; then
            ofile="${ifile%.*}.html" # 使用参数扩展去除文件名的后缀，再加.html
        elif [ -d "${ofile_or_ipathprefix}" ]; then # ofile_or_ipathprefix是目录绝对路径, 代表源文件路径前缀
            ipath_prefix=${ofile_or_ipathprefix}
            src_file=${ipath_prefix}/${ifile}
            ofile="${ifile%.*}.html" # 使用参数扩展去除文件名的后缀，再加.html
        fi

        # 以上内容和common-lib.sh中的create_html()一样

        __create_csdn_src $ifile $ofile $src_path $dst_path $src_file

    done
}

init
create_csdn_src array[@] ${src_path} ${dst_path}
change_private_perm
exit

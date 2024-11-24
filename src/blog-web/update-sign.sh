code_path=/home/sonvhi/chenxiaosong/code/
# 导入其他脚本
. ${code_path}/blog/src/blog-web/common-lib.sh

array=(
    tmp/photos/陈孝松照片.md
    tmp/calligraphy/书法.md
    tmp/calligraphy/赵孟𫖯.md
    tmp/calligraphy/欧阳询.md
    tmp/calligraphy/颜真卿.md
    tmp/calligraphy/柳公权.md
    tmp/calligraphy/书法.md
)

update_sign() {
    local array=("${!1}") # 使用间接引用来接收数组

    local sign_file=${code_path}/blog/src/blog-web/sign.md
    local begin_str='<!-- sign begin -->'
    local end_str='<!-- sign end -->'
    local element_count="${#array[@]}" # 总个数
    local count_per_line=1
    for ((index=0; index<${element_count}; index=$((index + ${count_per_line}))))
    do
        local ifile=${array[${index}]}
        local src_file=${code_path}/${ifile}

        remove_begin_end "${begin_str}" "${end_str}" ${src_file}
        cat ${sign_file} >> ${src_file}.tmp
        cat ${src_file} >> ${src_file}.tmp
        mv ${src_file}.tmp ${src_file}
    done
}

update_sign array[@]

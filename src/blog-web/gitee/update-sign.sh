code_path=/home/sonvhi/chenxiaosong/code/
# 导入其他脚本
. ${code_path}/blog/src/blog-web/common-lib.sh

array=()

scan_md() {
    local md_dir=$1
    md_dir="${md_dir%/}/" # 确保目录末尾有 /
    # 使用 find 命令查找所有 .md 文件并将结果存储到 array 数组中
    while IFS= read -r md_file; do
        # md_file=${md_file/$md_dir} # 干掉前缀
        array+=(${md_file})
    done < <(find ${md_dir} -type f -name "*.md")
}

update_sign() {
    local array=("${!1}") # 使用间接引用来接收数组

    local sign_file=${code_path}/blog/src/blog-web/sign.md
    local begin_str='<!-- sign begin -->'
    local end_str='<!-- sign end -->'
    local element_count="${#array[@]}" # 总个数
    local count_per_line=1
    for ((index=0; index<${element_count}; index=$((index + ${count_per_line}))))
    do
        local src_file=${array[${index}]}

        remove_begin_end "${begin_str}" "${end_str}" ${src_file}
        cat ${sign_file} >> ${src_file}.tmp
        cat ${src_file} >> ${src_file}.tmp
        mv ${src_file}.tmp ${src_file}
    done
}

scan_md ${code_path}/blog/src/blog-web/gitee/
update_sign array[@]

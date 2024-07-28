src_path=/home/sonvhi/chenxiaosong/code/blog
dst_path=/tmp/blog

. ${src_path}/src/blog-web/common-lib.sh

kernel_files() {
    local common_file=${src_path}/courses/kernel/common.md
    # 每一行代表： 是否在开头添加公共内容 文件相对路径
    local array=(
        0 courses/kernel/kernel.md
        1 courses/kernel/kernel-introduction.md
        1 courses/kernel/kernel-dev-environment.md
        1 courses/kernel/kernel-book.md
        1 courses/kernel/kernel-source.md
        1 courses/kernel/kernel-fs.md
        1 courses/kernel/kernel-debug.md
        1 courses/kernel/kernel-mm.md
        1 courses/kernel/kernel-patches.md
    )

    local element_count="${#array[@]}" # 总个数
    local count_per_line=2
    for ((index=0; index<${element_count}; index=$((index + ${count_per_line}))))
    do
        local is_add_common=${array[${index}]}
        local ifile=${array[${index}+1]}

        local src_file=${src_path}/${ifile}
        local dst_file=${dst_path}/${ifile}
        local dst_dir="$(dirname "${dst_file}")" # 所在的文件夹
        if [ ! -d "${dst_dir}" ]; then
            mkdir -p "${dst_dir}" # 文件夹不存在就创建
        fi
        if [[ ${is_add_common} == 1 ]]; then
            cp ${common_file} ${dst_file}
        fi
        cat ${src_file} >> ${dst_file}
    done
}

rm -rf ${dst_path}
mkdir ${dst_path} -p
kernel_files
remove_private ${dst_path}

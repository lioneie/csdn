get_pandoc_common_options() {
    # --standalone: 此选项指示 pandoc 生成一个完全独立的输出文件，包括文档标题、样式表和其他元数据，使输出文件成为一个完整的文档。
    # --metadata encoding=gbk: 这个选项允许您添加元数据。在这种情况下，您将 encoding 设置为 gbk，指定输出 HTML 文档的字符编码为 GBK。这对于确保生成的文档以正确的字符编码进行保存非常重要。
    # --toc: 这个选项指示 pandoc 生成一个包含文档目录（Table of Contents，目录）的 HTML 输出。TOC 将包括文档中的章节和子章节的链接，以帮助读者导航文档。
    local options="--to html --standalone --metadata encoding=gbk --number-sections --css https://chenxiaosong.com/stylesheet.css"
    echo "${options}"
}

# git仓库根目录的上一层目录
# 假设当前脚本的路径是/home/user/code/blog/src/blog-web/common-lib.sh，返回的是/home/user/code/
get_top_path() {
    # 也可以试试把realpath换成readlink -f
    local script_path="$(realpath "${BASH_SOURCE[0]}")" # 当前函数所在的脚本路径
    local git_path="$(git -C $(dirname ${script_path}) rev-parse --show-toplevel)"
    echo $(dirname "${git_path}") # 仓库的上一层目录
    # 以此类推，${BASH_SOURCE[2]}表示下一个调用链
    # echo "current script: ${BASH_SOURCE[0]}"
    # echo "calling script: ${BASH_SOURCE[1]}"
}

replace_with_other_ip() {
    dst_file=$1
    other_ip=$2

    sed -i 's/chenxiaosong.com/'${other_ip}'/g' ${dst_file}
    # 局域网用http，不用https
    sed -i 's/https:\/\/'${other_ip}'/http:\/\/'${other_ip}'/g' ${dst_file}
    # 邮箱替换回来
    sed -i 's/@'${other_ip}'/@chenxiaosong.com/g' ${dst_file}
}

create_sign() {
    local src_file=$1
    local tmp_html_path=$2

    local html_title="签名"
    local dst_file=${tmp_html_path}/sign.html
    local pandoc_options=$(get_pandoc_common_options)
    local from_format="--from markdown"
    pandoc ${src_file} -o ${dst_file} --metadata title="${html_title}" ${from_format} ${pandoc_options}
    # 先去除sign.html文件中其他内容
    sed -i '/<\/header>/,/<\/body>/!d' ${dst_file} # 只保留</header>到</body>的内容
    sed -i '1d;$d' ${dst_file} # 删除第一行和最后一行
}

# 要定义数组array
# 每一行代表:
#    是否生成目录
#    是否添加签名
#    源文件的相对路径，markdown或rst文件相对路径
#    '目的文件'或'源文件路径前缀'，有以下几种情况:
#        1. 相对路径的html文件
#        2. 绝对路径的html文件
#        3. '~'，就代表只和源文件的后缀名不同
#        4. 绝对路径的目录，代表源文件路径前缀，这时目的文件和上面的情况3一样
#    网页标题
create_html() {
    local array=("${!1}") # 使用间接引用来接收数组，调用的地方 create_html array[@] ...
    local src_path=$2
    local tmp_html_path=$3
    local sign_path=$4
    local is_replace_ip=$5
    local other_ip=$6

    # 以下内容如果修改了，还要修改create-csdn-src.sh中的create_csdn_src()
    # blog web shell common begin 1

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

        # blog web shell common end 1
        # 以上内容如果修改了，还要修改create-csdn-src.sh中的create_csdn_src()

        local dst_file=${tmp_html_path}/${ofile} # 拼接生成html文件名
        local dst_dir="$(dirname "${dst_file}")" # html文件所在的文件夹
        if [ ! -d "${dst_dir}" ]; then
            mkdir -p "${dst_dir}" # 文件夹不存在就创建
        fi
        from_format="--from markdown"
        if [[ ${src_file} == *.rst ]]; then
            from_format="--from rst" # rst格式
        fi
        if [[ ${is_toc} == 1 ]]; then
            pandoc_options="${pandoc_options} --toc"
        fi
        echo "create ${ofile}"
        pandoc ${src_file} -o ${dst_file} --metadata title="${html_title}" ${from_format} ${pandoc_options}
        # 局域网的处理
        if [[ ${is_replace_ip} == true ]]; then
            replace_with_other_ip ${dst_file} ${other_ip}
        fi
        if [[ ${is_sign} == 1 ]]; then
            # 在<header之后插入sign.html整个文件
            sed -i -e '/<header/r '${sign_path}'/sign.html' ${dst_file}
        fi

        # cd ${src_path}
        # git log -1 --format=%ad --date=iso ${ifile}
        # cd -
    done
}

change_perm() {
    local html_path=$1

    chown -R www-data:www-data ${html_path}/

    # -type f: 这个选项告诉 find 只搜索普通文件（不包括目录和特殊文件）。
    # -exec chmod 400 {} +: 这个部分告诉 find 对每个找到的文件执行 chmod 400 操作。{} 表示找到的文件的占位符，+ 表示一次处理多个文件以提高效率。
    find ${html_path}/ -type f -exec chmod 400 {} +

    # -type d: 这个选项告诉find只搜索目录（不包括普通文件）。
    find ${html_path}/ -type d -exec chmod 500 {} +
}

# 删除begin和end中间的内容，保留begin和end两行
remove_mid_lines() {
    local begin_str=$1 # 调用的地方要用引号
    local end_str=$2 # 调用的地方要用引号
    local path=$3

    # TODO: 把公共的命令提取成变量
    if [ -f "$path" ]; then
        # 把begin和end之间的内容删除, sed 默认只支持贪婪模式，要支持非贪婪模式要用Perl正则表达式（PCRE）
        # perl -i -pe "s/${begin_str}.*?${end_str}//g" ${path} # 只能在同一行内，必须放在前面
        # 按"行"为单位删除，保留begin和end
        sed -i "/${begin_str}/,/${end_str}/ { /${begin_str}/! { /${end_str}/! d } }" ${path}
    elif [ -d "$path" ]; then
        # 按"行"为单位删除，保留begin和end
        find ${path} -type f -exec sed -i "/${begin_str}/,/${end_str}/ { /${begin_str}/! { /${end_str}/! d } }" {} +
    else
        echo "${path} 既不是文件也不是目录"
    fi
}

# 删除完全匹配的一整行
remove_line() {
    local str=$1 # 调用的地方要用引号
    local path=$2
    # TODO: 把公共的命令提取成变量
    # -0777：使 perl 在处理文件时将整个文件作为一个单一的字符串，而不是逐行处理（即允许跨行匹配）
    if [ -f "${path}" ]; then
        perl -0777 -i -pe "s/\n${str}//g" ${path}
        perl -0777 -i -pe "s/${str}\n//g" ${path}
    elif [ -d "${path}" ]; then
        find ${path} -type f -exec perl -0777 -i -pe "s/\n${str}//g" {} +
        find ${path} -type f -exec perl -0777 -i -pe "s/${str}\n//g" {} +
    else
        echo "${path} 既不是文件也不是目录"
    fi
}

remove_other_comments() {
    local md_path=$1

    # 正在写的内容就先不放上去
    local begin_str='<!-- ing begin -->'
    local end_str='<!-- ing end -->'
    remove_mid_lines "${begin_str}" "${end_str}" ${md_path}
    remove_line "${begin_str}" "${md_path}"
    remove_line "${end_str}" "${md_path}"
    # 把注释全部删除
    find ${md_path} -type f -name '*.md' -exec perl -i -pe 's/<!--.*?-->//g' {} + # 只能在同一行内，必须放在前面
    find ${md_path} -type f -name '*.md' -exec sed -i '/<!--/,/-->/d' {} + # 只能按行为单位删除
}

remove_comment_lines() {
    local md_path=$1
    remove_line '<!-- public begin -->' "${md_path}"
    remove_line '<!-- public end -->' "${md_path}"
    remove_line '<!-- private begin -->' "${md_path}"
    remove_line '<!-- private end -->' "${md_path}"
}

remove_comments() {
    local md_path=$1
    local is_public=$2

    local begin_str='<!-- private begin -->'
    local end_str='<!-- private end -->'
    if [[ ${is_public} == true ]]; then
        begin_str='<!-- public begin -->'
        end_str='<!-- public end -->'
    fi
    remove_mid_lines "${begin_str}" "${end_str}" "${md_path}"
    remove_comment_lines "${md_path}"
    remove_other_comments ${md_path}
}

remove_private() {
    local md_path=$1
    remove_comments "${md_path}" false
}

remove_public() {
    local md_path=$1
    remove_comments "${md_path}" true
}

add_or_sub_header() {
    local input_file=$1
    local output_file=$2
    local is_add=$3 # true有增加，false为减少

    rm ${output_file}

    local is_code=false
    while IFS= read -r line; do
        if [[ $line == '```'* ]]; then
            if [[ $is_code == true ]]; then
                is_code=false
            else
                is_code=true
            fi
        fi

        if [[ $is_code == false && $line == '#'* ]]; then
            if [[ $is_add == false && $line == '# '* ]]; then
                continue # 如果减少的是一级标题，则删除这一行
            fi
            if [[ $is_add == true ]]; then
                echo "#$line" >> ${output_file}
            else
                echo ${line:1} >> ${output_file}
            fi
        else
            echo "$line" >> ${output_file}
        fi
    done < "$input_file"
}

# 将标题增加一级
add_header_sharp() {
    input_file=$1
    output_file=$2
    add_or_sub_header ${input_file} ${output_file} true
}

# 将标题减少一级
sub_header_sharp() {
    input_file=$1
    output_file=$2
    add_or_sub_header ${input_file} ${output_file} false
}

create_src_for_header() {
    input_file=$1

    local is_code=false
    local begin_header=false # 是否开始第一个标题
    local dir_name=${input_file}.dir
    local common_file=${dir_name}/common.md
    local file_name=${common_file}
    mkdir ${dir_name}
    echo "create dir ${dir_name}"
    local header_index=0
    while IFS= read -r line; do
        if [[ ${line} == '```'* ]]; then
            if [[ ${is_code} == true ]]; then
                is_code=false
            else
                is_code=true
            fi
        fi

        local is_header=false # 这一行是否标题
        if [[ ${is_code} == false && ${line} == '#'* ]]; then
            is_header=true # 是标题
        fi
        if [[ ${is_header} == true && ${line} == '# '* ]]; then
            header_index=$((header_index + 1))
            begin_header=true # 开始第一个标题
            file_name=$(echo "${line:2}" | tr -d '[:space:][:punct:]') # 删除空格和标点
            file_name=${dir_name}/${header_index}.${file_name}.txt
            cat ${common_file} >> ${file_name}
            continue
        fi
        if [[ ${is_header} == true ]]; then # 肯定不是第一个标题
            echo ${line:1} >> ${file_name}
        else
            echo "${line}" >> ${file_name}
        fi
    done < "${input_file}"
}

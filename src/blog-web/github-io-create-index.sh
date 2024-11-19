#!/bin/bash

# 检查参数
if [ $# -ne 1 ]; then
    echo "用法: $0 <目录>"
    exit 1
fi

start_dir="$1"

# 递归函数，处理目录
generate_index() {
    local dir="$1"
    local parent_dir="$2"
    local title=${dir/$start_dir/} # 干掉前缀
    title="${title:-top}"
    local html_name

    if [ -n "$parent_dir" ]; then
        html_name="index.html"
    else
        html_name="ls.html"
    fi
    # 生成 index.html 文件
    local index_file="${dir}/${html_name}"
    {
        # 输出文件头
        echo "<html>"
        echo "<head><title>Index of ${title}</title></head>"
        echo "<body>"
        echo "<h1>Index of ${title}</h1><hr><pre>"

        # 输出父目录链接（如果有的话）
        if [ -n "$parent_dir" ]; then
            echo "<a href=\"../\">../</a>"
        fi

        # 遍历目录中的内容，输出每个文件或目录的链接
        for entry in "$dir"/*; do
            local entry_name=$(basename "$entry")
            if [ "$entry_name" = "${html_name}" ]; then
                # 自己还显示个啥呢
                continue
            elif [ -d "$entry" ]; then
                # 目录
                echo "<a href=\"${entry_name}/\">${entry_name}/</a>"
            elif [ -f "$entry" ]; then
                # 文件
                echo "<a href=\"${entry_name}\">${entry_name}</a>"
            fi
        done

        # 输出文件尾
        echo "</pre><hr></body>"
        echo "</html>"
    } > "$index_file"

    # 递归生成子目录的 index.html
    for subdir in "$dir"/*; do
        if [ -d "$subdir" ]; then
            generate_index "$subdir" "$dir"
        fi
    done
}

# 调用函数，从指定目录开始生成 index.html
generate_index "$start_dir"


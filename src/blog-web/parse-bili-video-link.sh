# 保存html文件(网页，全部)，命名为tmp
html_file="tmp.htm"
txt_file="tmp.txt"
output_file="tmp.md"

grep -r "</div></a><a href=\"https://www.bilibili.com/video" "${html_file}" > "${txt_file}"
# 清空输出文件
> "${output_file}"

# 逐行处理输入文件
while IFS= read -r line; do
    # 提取 URL 和标题
    url=$(echo "${line}" | grep -oP '(?<=href=")[^"]+' | tail -n 1) # 取最后一行
    title=$(echo "${line}" | grep -oP '(?<=title=")[^"]+')

    # 如果提取到有效的数据，格式化为 Markdown 并写入输出文件
    if [[ -n ${url} && -n ${title} ]]; then
        echo "- [${title}](${url})" >> "${output_file}"
    fi
done < "${txt_file}"

echo "处理完成，结果已保存到 ${output_file}。"


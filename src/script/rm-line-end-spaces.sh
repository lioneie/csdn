# 删除文件中每行末尾的空格或tab

# 检查参数
if [ $# -ne 1 ]; then
        echo "用法: bash $0 <文件>"
        exit 1
fi
filename=$1

sed -i 's/[[:space:]]*$//' ${filename}

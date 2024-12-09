# 此脚本用于把markdown文件的每个标题生成一个文件
. ~/.top-path

md_file=$1

src_path=${MY_CODE_TOP_PATH}/blog # 替换为你的仓库路径
. ${src_path}/src/blog-web/common-lib.sh

comm_create_src_for_header ${md_file}

# 此脚本用于生成以标题命名的文件和CSDN等博客网站的文件
. ~/.top-path

# 检查参数
if [ $# -ne 1 ]; then
        echo "用法: bash $0 <局域网ip>"
        exit 1
fi
lan_ip=$1

public_src_path=${MY_CODE_TOP_PATH}/blog # 替换为你的仓库路径
title_name_dst_path=${MY_TOP_PATH}/title-name-src
csdn_dst_path=${MY_TOP_PATH}/csdn-src

. ${public_src_path}/src/blog-web/common-lib.sh
. ${public_src_path}/src/blog-web/array.sh

my_init() {
	rm -rf ${title_name_dst_path}
	rm -rf ${csdn_dst_path}
	rm -rf $(comm_tmp_src_path)
	mkdir -p $(comm_tmp_src_path)
	cp -rf ${public_src_path}/* $(comm_tmp_src_path)
	bash ${public_src_path}/course/course.sh
	comm_rm_private $(comm_tmp_src_path)
}

my_exit() {
	# rm -rf $(comm_tmp_src_path) # 为了方便对比，不删除
	comm_rm_other_comments ${title_name_dst_path}
	# comm_rm_other_comments ${csdn_dst_path} # 注释保留
}

create_title_name_src() {
	local array=("${!1}")
	local src_path=$2
	local dst_path=$3

	comm_iterate_array __comm_create_title_name_src array[@] "${src_path}"	\
		"${dst_path}"	\
		"https://chenxiaosong.com"	\
		"${public_src_path}/src/blog-web/sign.md"

}

__create_csdn_src() {
	comm_create_full_src "$@"

	local is_toc=$1
	shift; local is_sign=$1
	shift; local ifile=$1
	shift; local ofile=$1
	shift; local html_title=$1
	shift; local src_file=$1
	shift; local src_path=$1

	shift; local dst_path=$1

	local dst_file=${dst_path}/${ifile} # 输出文件
	comm_create_src_for_header ${dst_file}
}

create_csdn_src() {
	local array=("${!1}")
	local src_path=$2
	local dst_path=$3

	comm_iterate_array __create_csdn_src array[@] "${src_path}"	\
		"${dst_path}"	\
		"https://chenxiaosong.com"	\
		"${public_src_path}/src/blog-web/sign.md"
}

my_init
create_title_name_src comm_array[@] ${public_src_path} ${title_name_dst_path}
create_csdn_src comm_array[@] ${public_src_path} ${csdn_dst_path}
my_exit
. ${public_src_path}/../private-blog/script/create-full-src.sh ${lan_ip}

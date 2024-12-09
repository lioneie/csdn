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

BLOG_URL="https://chenxiaosong.com"
SIGN_MD_FILE=${public_src_path}/src/blog-web/sign.md

my_init() {
	rm -rf ${title_name_dst_path}
	rm -rf ${csdn_dst_path}
	rm -rf ${tmp_src_path}
	mkdir -p ${tmp_src_path}
	bash ${public_src_path}/courses/courses.sh ${tmp_src_path}
	comm_rm_private ${tmp_src_path}
}

my_exit() {
	# rm -rf ${tmp_src_path} # 为了方便对比，不删除
	comm_rm_other_comments ${title_name_dst_path}
	# comm_rm_other_comments ${csdn_dst_path} # 注释保留
}

change_private_perm() {
	chown -R sonvhi:sonvhi ${title_name_dst_path}
	chmod -R 770 ${title_name_dst_path}
	chown -R sonvhi:sonvhi ${csdn_dst_path}
	chmod -R 770 ${csdn_dst_path}
}

create_full_src() {
	local is_toc=$1
	shift; local is_sign=$1
	shift; local ifile=$1
	shift; local ofile=$1
	shift; local html_title=$1
	shift; local src_file=$1
	shift; local src_path=$1

	shift; local dst_path=$1

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

	echo '[建议点击这里查看个人主页上的最新原文]('${BLOG_URL}'/'${ofile}')' >> ${dst_file}
	echo >> ${dst_file}
	cat ${SIGN_MD_FILE} >> ${dst_file}
	echo >> ${dst_file}
	cat ${src_file} >> ${dst_file}
}

get_title_filename() {
	local dst_file=$1
	local html_title=$2

	# 提取文件的目录路径
	local dir_path=$(dirname "${dst_file}")
	# 提取文件的扩展名
	local extension="${dst_file##*.}" # TODO: 多个点号时
	# 除下划线外，所有标点和空格替换为减号
	html_title=$(echo "${html_title}" | sed 's/_/underscore/g' | sed 's/[[:punct:][:space:]]/-/g' | sed 's/underscore/_/g')

	echo "${dir_path}/${html_title}.${extension}"
}

__create_title_name_src() {
	create_full_src "$@"

	local is_toc=$1
	shift; local is_sign=$1
	shift; local ifile=$1
	shift; local ofile=$1
	shift; local html_title=$1
	shift; local src_file=$1
	shift; local src_path=$1

	shift; local dst_path=$1

	local dst_file=${dst_path}/${ifile} # 输出文件
	local title_filename=$(get_title_filename "${dst_file}" "${html_title}")
	mv "${dst_file}" "${title_filename}"
}

create_title_name_src() {
	local array=("${!1}")
	local src_path=$2
	local dst_path=$3

	comm_iterate_array __create_title_name_src array[@] "${src_path}"	\
		"${dst_path}"
}

__create_csdn_src() {
	create_full_src "$@"

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
		"${dst_path}"
}

my_init
create_title_name_src array[@] ${public_src_path} ${title_name_dst_path}
create_csdn_src array[@] ${public_src_path} ${csdn_dst_path}
change_private_perm
my_exit
. ${public_src_path}/../private-blog/scripts/create-full-src.sh ${lan_ip}

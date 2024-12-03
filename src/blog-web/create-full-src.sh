# 此脚本用于生成以标题命名的文件和CSDN等博客网站的文件
. ~/.top-path

src_path=${MY_CODE_TOP_PATH}/blog # 替换为你的仓库路径
title_name_dst_path=${MY_TOP_PATH}/title-name-src
csdn_dst_path=${MY_TOP_PATH}/csdn-src

. ${src_path}/src/blog-web/common-lib.sh
. ${src_path}/src/blog-web/array.sh

my_init() {
	rm -rf ${title_name_dst_path}
	rm -rf ${csdn_dst_path}
	rm -rf ${tmp_src_path}
	mkdir -p ${tmp_src_path}
	bash ${src_path}/courses/courses.sh ${tmp_src_path}
	remove_private ${tmp_src_path}
}

my_exit() {
	# rm -rf ${tmp_src_path} # 为了方便对比，不删除
	remove_other_comments ${title_name_dst_path}
	# remove_other_comments ${csdn_dst_path} # 注释保留
}

change_private_perm() {
	chown -R sonvhi:sonvhi ${title_name_dst_path}
	chmod -R 770 ${title_name_dst_path}
	chown -R sonvhi:sonvhi ${csdn_dst_path}
	chmod -R 770 ${csdn_dst_path}
}

__create_title_name_src() {
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

	echo '[建议点击这里查看个人主页上的最新原文](https://chenxiaosong.com/'${ofile}')' >> ${dst_file}
	echo >> ${dst_file}
	cat ${src_path}/src/blog-web/sign.md >> ${dst_file}
	echo >> ${dst_file}
	cat ${src_file} >> ${dst_file}

	# 提取文件的目录路径
	local dir_path=$(dirname "${dst_file}")
	# 提取文件的扩展名
	local extension="${dst_file##*.}" # TODO: 多个点号时
	# 除下划线外，所有标点和空格替换为减号
	html_title=$(echo "${html_title}" | sed 's/_/underscore/g' | sed 's/[[:punct:][:space:]]/-/g' | sed 's/underscore/_/g')
	mv ${dst_file} ${dir_path}/${html_title}.${extension}
}

create_title_name_src() {
	local array=("${!1}")
	local src_path=$2
	local dst_path=$3

	iterate_array __create_title_name_src array[@] "${src_path}"	\
		"${dst_path}"
}

__create_csdn_src() {
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

	echo '[建议点击这里查看个人主页上的最新原文](https://chenxiaosong.com/'${ofile}')' >> ${dst_file}
	echo >> ${dst_file}
	cat ${src_path}/src/blog-web/sign.md >> ${dst_file}
	echo >> ${dst_file}
	cat ${src_file} >> ${dst_file}

	create_src_for_header ${dst_file}
}

create_csdn_src() {
	local array=("${!1}")
	local src_path=$2
	local dst_path=$3

	iterate_array __create_csdn_src array[@] "${src_path}"	\
		"${dst_path}"
}

my_init
create_title_name_src array[@] ${src_path} ${title_name_dst_path}
create_csdn_src array[@] ${src_path} ${csdn_dst_path}
change_private_perm
my_exit

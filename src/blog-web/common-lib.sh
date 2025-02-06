comm_tmp_src_path() {
	echo "/tmp/blog-src-tmp"
}

comm_green_color() {
	echo '\033[0;32m'
}

comm_yellow_color() {
	echo '\033[1;33m'
}

comm_red_color() {
	echo '\033[1;31m'
}

comm_no_color() {
	echo '\033[0m'
}

# ceil(numerator/denominator)
comm_ceil_divide() {
	local numerator=$1 # 被除数
	local denominator=$2 # 除数

	local result=$(( (numerator + denominator - 1) / denominator ))
	echo "${result}"
}

# 要定义MY_ECHO_DEBUG变量
comm_echo() {
	if [ "${MY_ECHO_DEBUG}" -eq 1 ]; then
		echo "$@"
	fi
}

comm_get_pandoc_options() {
	# --standalone: 此选项指示 pandoc 生成一个完全独立的输出文件，包括文档标题、样式表和其他元数据，使输出文件成为一个完整的文档。
	# --metadata encoding=gbk: 这个选项允许您添加元数据。在这种情况下，您将 encoding 设置为 gbk，指定输出 HTML 文档的字符编码为 GBK。这对于确保生成的文档以正确的字符编码进行保存非常重要。
	# --toc: 这个选项指示 pandoc 生成一个包含文档目录（Table of Contents，目录）的 HTML 输出。TOC 将包括文档中的章节和子章节的链接，以帮助读者导航文档。
	local options="--to html --standalone --metadata encoding=gbk --number-sections --css https://chenxiaosong.com/stylesheet.css"
	echo "${options}"
}

# git仓库根目录的上一层目录
# 假设当前脚本的路径是/home/user/code/blog/src/blog-web/common-lib.sh，返回的是/home/user/code/
comm_get_top_path() {
	# 也可以试试把realpath换成readlink -f
	local script_path="$(realpath "${BASH_SOURCE[0]}")" # 当前函数所在的脚本路径
	local git_path="$(git -C $(dirname ${script_path}) rev-parse --show-toplevel)"
	echo $(dirname "${git_path}") # 仓库的上一层目录
	# 以此类推，${BASH_SOURCE[2]}表示下一个调用链
	# echo "current script: ${BASH_SOURCE[0]}"
	# echo "calling script: ${BASH_SOURCE[1]}"
}

comm_file_replace_ip() {
	local dst_file=$1
	local other_ip=$2

	sed -i 's/chenxiaosong.com/'${other_ip}'/g' "${dst_file}"
	# 局域网用http，不用https
	sed -i 's/https:\/\/'${other_ip}'/http:\/\/'${other_ip}'/g' "${dst_file}"
	# 邮箱替换回来
	sed -i 's/@'${other_ip}'/@chenxiaosong.com/g' "${dst_file}"
}

comm_str_replace_ip() {
	local str=$1
	local other_ip=$2

	str=$(echo "${str}" | sed 's/chenxiaosong.com/'${other_ip}'/')
	# 局域网用http，不用https
	str=$(echo "${str}" | sed 's/https:\/\/'${other_ip}'/http:\/\/'${other_ip}'/')
	# 邮箱替换回来
	str=$(echo "${str}" | sed 's/@'${other_ip}'/@chenxiaosong.com/')

	echo "${str}"
}

comm_create_sign() {
	local src_file=$1
	local dst_file=$2

	local html_title="签名"
	local pandoc_options=$(comm_get_pandoc_options)
	local from_format="--from markdown"
	pandoc ${src_file} -o ${dst_file} --metadata title="${html_title}" ${from_format} ${pandoc_options}
	# 先去除sign.html文件中其他内容
	sed -i '/<\/header>/,/<\/body>/!d' ${dst_file} # 只保留</header>到</body>的内容
	sed -i '1d;$d' ${dst_file} # 删除第一行和最后一行
}

# 要定义数组array
# 每一行代表:
#	是否生成目录
#	是否添加签名
#	源文件的相对路径，markdown或rst文件相对路径
#	'目的文件'或'源文件路径前缀'，有以下几种情况:
#		1. 相对路径的html文件
#		2. 绝对路径的html文件
#		3. '~'，就代表只和源文件的后缀名不同
#		4. 绝对路径的目录，代表源文件路径前缀，这时目的文件和上面的情况3一样
#	网页标题
comm_iterate_array() {
	local function=$1 # 调用的地方 comm_iterate_array ... function ...
	local array=("${!2}") # 使用间接引用来接收数组，调用的地方 comm_iterate_array array[@] ...
	local src_path=$3
	shift 3 # "$@"移除前面的参数

	local element_count="${#array[@]}" # 总个数
	local count_per_line=5
	for ((index=0; index<${element_count}; index=$((index + ${count_per_line})))); do
		local is_toc=${array[${index}]}
		local is_sign=${array[${index}+1]}
		local ifile=${array[${index}+2]}
		local ofile_or_ipathprefix=${array[${index}+3]}
		local html_title=${array[${index}+4]}

		local src_file=${src_path}/${ifile} # 源路径拼接
		local ofile=${ofile_or_ipathprefix}

		local ipath_prefix
		if [[ ${ofile_or_ipathprefix} == ~ ]]; then
			ofile="${ifile%.*}.html" # 使用参数扩展去除文件名的后缀，再加.html
		elif [ -d "${ofile_or_ipathprefix}" ]; then # ofile_or_ipathprefix是目录绝对路径, 代表源文件路径前缀
			ipath_prefix=${ofile_or_ipathprefix}
			src_file=${ipath_prefix}/${ifile}
			ofile="${ifile%.*}.html" # 使用参数扩展去除文件名的后缀，再加.html
		fi

		${function} \
			"${is_toc}"	\
			"${is_sign}"	\
			"${ifile}"	\
			"${ofile}"	\
			"${html_title}"	\
			"${src_file}"	\
			"${src_path}"	\
			"$@" # 剩下的参数
	done
}

__comm_create_html() {
	local is_toc=$1
	shift; local is_sign=$1
	shift; local ifile=$1
	shift; local ofile=$1
	shift; local html_title=$1
	shift; local src_file=$1
	shift; local src_path=$1

	shift; local tmp_html_path=$1
	shift; local sign_html=$1
	shift; local is_replace_ip=$1
	shift; local other_ip=$1

	local dst_file=${tmp_html_path}/${ofile} # 拼接生成html文件名
	local dst_dir="$(dirname "${dst_file}")" # html文件所在的文件夹
	if [ ! -d "${dst_dir}" ]; then
		mkdir -p "${dst_dir}" # 文件夹不存在就创建
	fi
	local from_format="--from markdown"
	if [[ ${src_file} == *.rst ]]; then
		from_format="--from rst" # rst格式
	fi
	local pandoc_options=$(comm_get_pandoc_options)
	if [[ ${is_toc} == 1 ]]; then
		pandoc_options="${pandoc_options} --toc"
	fi
	echo "create ${ofile}"
	pandoc ${src_file} -o ${dst_file} --metadata title="${html_title}" ${from_format} ${pandoc_options}
	# 局域网的处理
	if [[ ${is_replace_ip} == true ]]; then
		comm_file_replace_ip ${dst_file} ${other_ip}
	fi
	if [[ ${is_sign} == 1 ]]; then
		# 在'<header'之后插入整个签名文件
		sed -i -e '/<header/r '${sign_html} ${dst_file}
	fi

	# cd ${src_path}
	# git log -1 --format=%ad --date=iso ${ifile}
	# cd -
}

comm_create_html() {
	local array=("${!1}") # 使用间接引用来接收数组，调用的地方 comm_create_html array[@] ...
	shift; local src_path=$1
	shift; local tmp_html_path=$1
	shift; local sign_html=$1
	shift; local is_replace_ip=$1
	shift; local other_ip=$1

	comm_iterate_array __comm_create_html array[@] "${src_path}" \
		"${tmp_html_path}"	\
		"${sign_html}"		\
		"${is_replace_ip}"	\
		"${other_ip}"
}

comm_change_nginx_perm() {
	local html_path=$1

	chown -R www-data:www-data ${html_path}/

	# -type f: 这个选项告诉 find 只搜索普通文件（不包括目录和特殊文件）。
	# -exec chmod 400 {} +: 这个部分告诉 find 对每个找到的文件执行 chmod 400 操作。{} 表示找到的文件的占位符，+ 表示一次处理多个文件以提高效率。
	find ${html_path}/ -type f -exec chmod 400 {} +

	# -type d: 这个选项告诉find只搜索目录（不包括普通文件）。
	find ${html_path}/ -type d -exec chmod 500 {} +
}

# 删除begin和end中间的内容，保留begin和end两行
comm_rm_mid_lines() {
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
comm_rm_line() {
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

comm_rm_other_comments() {
	local md_path=$1

	# 正在写的内容就先不放上去
	local begin_str='<!-- ing begin -->'
	local end_str='<!-- ing end -->'
	comm_rm_mid_lines "${begin_str}" "${end_str}" ${md_path}
	comm_rm_line "${begin_str}" "${md_path}"
	comm_rm_line "${end_str}" "${md_path}"
	# 把注释全部删除
	find ${md_path} -type f -exec perl -i -pe 's/<!--.*?-->//g' {} + # 只能在同一行内，必须放在前面
	find ${md_path} -type f -exec sed -i '/<!--/,/-->/d' {} + # 只能按行为单位删除
}

comm_rm_comment_lines() {
	local md_path=$1
	comm_rm_line '<!-- public begin -->' "${md_path}"
	comm_rm_line '<!-- public end -->' "${md_path}"
	comm_rm_line '<!-- private begin -->' "${md_path}"
	comm_rm_line '<!-- private end -->' "${md_path}"
}

comm_rm_comments() {
	local md_path=$1
	local is_public=$2

	local begin_str='<!-- private begin -->'
	local end_str='<!-- private end -->'
	if [[ ${is_public} == true ]]; then
		begin_str='<!-- public begin -->'
		end_str='<!-- public end -->'
	fi
	comm_rm_mid_lines "${begin_str}" "${end_str}" "${md_path}"
	comm_rm_comment_lines "${md_path}"
	comm_rm_other_comments ${md_path}
}

comm_rm_private() {
	local md_path=$1
	comm_rm_comments "${md_path}" false
}

comm_rm_public() {
	local md_path=$1
	comm_rm_comments "${md_path}" true
}

comm_add_or_sub_header() {
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
comm_add_header_sharp() {
	input_file=$1
	output_file=$2
	comm_add_or_sub_header ${input_file} ${output_file} true
}

# 将标题减少一级
comm_sub_header_sharp() {
	input_file=$1
	output_file=$2
	comm_add_or_sub_header ${input_file} ${output_file} false
}

comm_create_src_for_header() {
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

# 递归生成index.html，最顶层目录生成ls.html
comm_generate_index() {
	local dir="$1"
	local parent_dir="$2"
	local start_dir="$3"

	local title=${dir/$start_dir/} # 干掉前缀
	title="${title:-top}"
	local html_name

	if [ -n "${parent_dir}" ]; then
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
		if [ -n "${parent_dir}" ]; then
			echo "<a href=\"../\">../</a>"
		fi

		# 遍历目录中的内容，输出每个文件或目录的链接
		for entry in "${dir}"/*; do
			local entry_name=$(basename "$entry")
			if [ "${entry_name}" = "${html_name}" ]; then
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
	} > "${index_file}"

	# 递归生成子目录的 index.html
	for subdir in "${dir}"/*; do
		if [ -d "${subdir}" ]; then
			comm_generate_index "${subdir}" "${dir}" "${start_dir}"
		fi
	done
}

# 确认git仓库要采取的操作
#   return 0: 要手动处理
#   return 1: git pull (调用的地方要保证不会冲突)
#   return 2: git push
comm_check_pull_push() {
	local origin_commit=$(git rev-parse origin/master)
	local master_commit=$(git rev-parse master)
	local contains_origin=$(git branch -a --contains "${origin_commit}")
	local contains_master=$(git branch -a --contains "${master_commit}")
	local remote_contain_origin=false
	local local_contain_origin=false
	local remote_contain_master=false
	local local_contain_master=false

	comm_echo "${contains_origin}"
	if echo "${contains_origin}" | grep -q "^  remotes/origin/master"; then
		comm_echo "origin/master commit is contained in remote branch"
		remote_contain_origin=true
	fi
	if echo "${contains_origin}" | grep -q "^* master"; then
		comm_echo "origin/master commit is contained in local branch"
		local_contain_origin=true
	fi

	comm_echo "${contains_master}"
	if echo "${contains_master}" | grep -q "^  remotes/origin/master"; then
		comm_echo "master commit is contained in remote branch"
		remote_contain_master=true
	fi
	if echo "${contains_master}" | grep -q "^* master"; then
		comm_echo "master commit is contained in local branch"
		local_contain_master=true
	fi

	if [[ "${remote_contain_origin}" == "true" && "${local_contain_origin}" == "false" && \
	      "${remote_contain_master}" == "true" && "${local_contain_master}" == "true" ]]; then
		comm_echo "should pull"
		return 1
	elif [[ "${remote_contain_origin}" == "true" && "${local_contain_origin}" == "true" && \
	      "${remote_contain_master}" == "false" && "${local_contain_master}" == "true" ]]; then
		comm_echo "should push"
		return 2
	fi

	return 0
}

comm_check_repo() {
	local path=$1
	local -n not_exist_repos_ref=$2
	local -n not_clean_repos_ref=$3
	local -n not_sync_repos_ref=$4
	local -n ok_repos_ref=$5

	local -n tmp_repos_ref
	local cmd_res=""
	local repo=$(basename "${path}")

	if [ ! -d "${path}" ]; then
		comm_echo "${repo}目录不存在"
		not_exist_repos_ref+=(${repo})
		return
	fi

	cd ${path}
	local status=$(git status -s) # git status -s --untracked-files=no

	local is_repo_clean=true
	if [ ! -z "${status}" ]; then
		echo -e "$(comm_red_color)${repo}$(comm_no_color) 有未提交的更改:"
		git status -s
		not_clean_repos_ref+=(${repo})
		is_repo_clean=false
	fi

	git fetch origin
	if [ $? -ne 0 ]; then
		echo "!!! ${repo} fetch fail !!!"
		exit
	fi
	local origin_commit=$(git rev-parse origin/master)
	local master_commit=$(git rev-parse master)
	comm_echo "${repo} origin_commit: ${origin_commit}"
	comm_echo "${repo} master_commit: ${master_commit}"

	if [ "${origin_commit}" == "${master_commit}" ]; then
		comm_echo "${repo}不用push/pull"
		tmp_repos_ref=ok_repos_ref
	else
		comm_echo "${repo}未push/pull"
		comm_check_pull_push
		cmd_res=$?
		if [[ "${cmd_res}" == 1 ]]; then
			git pull origin master
			comm_echo "${repo} pull完成"
			tmp_repos_ref=ok_repos_ref
		elif [[ "${cmd_res}" == 2 ]]; then
			git push origin master
			comm_echo "${repo} push完成"
			tmp_repos_ref=ok_repos_ref
		else
			comm_echo "${repo}未push/pull，要手动处理"
			tmp_repos_ref=not_sync_repos_ref
		fi
	fi
	if [[ "${is_repo_clean}" == "true" ]]; then
		comm_echo "${repo}仓库是干净的"
		tmp_repos_ref+=(${repo})
	fi
}

comm_print_array() {
	local array=("${!1}")
	local descriptions=("${@:2}")

	local len="${#array[@]}"
	if [ "${len}" -ne 0 ]; then
		echo -e "${descriptions[@]}"
	fi
}

comm_get_title_filename() {
	local dst_file=$1
	local html_title=$2

	# 提取文件的目录路径
	local dir_path=$(dirname "${dst_file}")
	# 提取文件的扩展名
	local extension="${dst_file##*.}" # 最后一个点号后面的部分
	# 除下划线外，所有标点和空格替换为减号
	# html_title=$(echo "${html_title}" | sed 's/_/underscore/g' | sed 's/[[:punct:][:space:]]/-/g' | sed 's/underscore/_/g')
	# 替换/
	html_title=$(echo "${html_title}" | sed 's|/|-|g')

	echo "${dir_path}/${html_title}.${extension}"
}

__comm_create_title_name_src() {
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
	local title_filename=$(comm_get_title_filename "${dst_file}" "${html_title}")
	mv "${dst_file}" "${title_filename}"
}

comm_create_full_src() {
	local is_toc=$1
	shift; local is_sign=$1
	shift; local ifile=$1
	shift; local ofile=$1
	shift; local html_title=$1
	shift; local src_file=$1
	shift; local src_path=$1

	shift; local dst_path=$1
	shift; local blog_url=$1
	shift; local sign_md_file=$1

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

	echo '[建议点击这里查看个人主页上的最新原文]('${blog_url}'/'${ofile}')' >> ${dst_file}
	echo >> ${dst_file}
	cat ${sign_md_file} >> ${dst_file}
	echo >> ${dst_file}
	cat ${src_file} >> ${dst_file}
}

# 0: 已存在数组中，1: 不存在数组中
comm_is_in_array() {
	local array=("${!1}")
	local target_item=$2

	for item in "${array[@]}"; do
		if [[ "$item" == "${target_item}" ]]; then
			return 0
		fi
	done
	return 1
}

comm_normalize_path() {
	local path="$1"
	# 删除连续的斜杠
	path=$(echo "$path" | sed -e 's#/\+#/#g')
	# 如果是目录，确保以 / 结尾
	if [[ -d "$path" && "$path" != */ ]]; then
		path="$path/"
	fi
	echo "$path"
}


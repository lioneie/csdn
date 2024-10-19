to_types=('maintainer' 'reviewer' 'supporter' 'commit_signer')
cc_types=('open list' 'moderated list')

to_emails=()
cc_emails=()
unknown_emails=()

# 0: 已存在数组中，1: 不存在数组中
is_exist() {
	local -n array=$1
	local target_item=$2

	for item in "${array[@]}"; do
		if [[ "$item" == "${target_item}" ]]; then
			return 0
		fi
	done
	return 1
}

iter_types() {
	local -n types_array=$1
	local -n emails_array=$2
	local str=$3
	# echo ${types_array[@]}
	echo ${str}
	local email=$(echo ${str} | awk '{print $1}')
	for type_name in "${types_array[@]}"; do
		echo ${str} | grep -E ${type_name} > /dev/null 2>&1
		if [[ $? == 0 ]]; then
			is_exist emails_array ${email}
			if [[ $? == 0 ]]; then
				return 0
			fi
			echo "${type_name}: ${email}"
			# emails_array+=(${email})
			return 0
		fi
	done
	echo "unknown: ${email}"
}

parse_emails() {
	local str=$1
	iter_types to_types to_emails "${str}"
}

pattern=$1
echo "pattern: $pattern"

for file in $pattern; do
	if [[ ${file} == '0000-cover-letter.patch' ]]; then
		continue
	fi
	cmd="./scripts/get_maintainer.pl ${file}"
	output_str=$(${cmd})
	echo ${cmd}
	# echo "${output_str}"
	echo "${output_str}" | while IFS= read -r line; do
		line=$(echo ${line} | sed 's/.* <//') # ' <'之前的部分删除
		line=$(echo ${line} | sed 's/>//g') # 删除'>'字符
		# echo "line: ${line}"
		parse_emails "${line}"
	done
done

# echo "git send-email --to=${to_emails[@]}"


# 用法:
#   1. get-maintainer-email.sh 000\*
#   2. get-maintainer-email.sh '000*'
#   3. get-maintainer-email.sh "000*"

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

# 0: 已存在某个数组中，1: 不存在任何数组中
is_email_exist() {
	local email=$1
	is_exist to_emails ${email}
	if [[ $? == 0 ]]; then
		return 0
	fi
	is_exist cc_emails ${email}
	if [[ $? == 0 ]]; then
		return 0
	fi
	is_exist unknown_emails ${email}
	if [[ $? == 0 ]]; then
		return 0
	fi
	return 1
}

# 0: 成功添加到邮件数组中或已存在某个数组中，1: 未添加到数组中
iter_types() {
	local -n types_array=$1
	local -n emails_array=$2

	local emails_array_name=$2
	local str=$3
	# echo ${types_array[@]}
	# echo ${str}
	local email=$(echo ${str} | awk '{print $1}') # 提取邮箱
	for type_name in "${types_array[@]}"; do
		echo ${str} | grep -E ${type_name} > /dev/null 2>&1
		if [[ $? == 0 ]]; then
			is_email_exist ${email}
			if [[ $? == 0 ]]; then
				echo "${email} already exist"
				return 0
			fi
			echo "${type_name}: ${email}"
			emails_array+=(${email})
			# echo "${emails_array_name}: ${emails_array[@]}"
			return 0
		fi
	done
	return 1
}

# 传入的字符串格式: corbet@lwn.net (maintainer:DOCUMENTATION)
parse_emails() {
	local str=$1
	local email=$(echo ${str} | awk '{print $1}') # 提取邮箱
	iter_types to_types to_emails "${str}"
	if [[ $? != 0 ]]; then
		echo "unknown: ${email}"
		unknown_emails+=(${email})
	fi
}

iter_str() {
	local output_str=$1
	echo "${output_str}" | while IFS= read -r line; do
		local line=$(echo ${line} | sed 's/.* <//') # ' <'之前的部分删除
		line=$(echo ${line} | sed 's/>//g') # 删除'>'字符
		# echo "line: ${line}"
		parse_emails "${line}"
	done
	echo "debug to_emails: ${to_emails[@]}"
}

parse_pattern() {
	local pattern=$1
	echo "pattern: $pattern"
	for file in $pattern; do
		if [[ ${file} == '0000-cover-letter.patch' ]]; then
			continue
		fi
		local cmd="./scripts/get_maintainer.pl ${file}"
		local output_str=$(${cmd})
		echo ${cmd}
		# echo "${output_str}"
		iter_str "${output_str}"
	done
}

test_str=$(cat <<EOF
Steve French <sfrench@samba.org> (supporter:COMMON INTERNET FILE SYSTEM CLIENT (CIFS and SMB3))
Paulo Alcantara <pc@manguebit.com> (reviewer:COMMON INTERNET FILE SYSTEM CLIENT (CIFS and SMB3))
Ronnie Sahlberg <ronniesahlberg@gmail.com> (reviewer:COMMON INTERNET FILE SYSTEM CLIENT (CIFS and SMB3))
Shyam Prasad N <sprasad@microsoft.com> (reviewer:COMMON INTERNET FILE SYSTEM CLIENT (CIFS and SMB3))
Tom Talpey <tom@talpey.com> (reviewer:COMMON INTERNET FILE SYSTEM CLIENT (CIFS and SMB3))
Bharath SM <bharathsm@microsoft.com> (reviewer:COMMON INTERNET FILE SYSTEM CLIENT (CIFS and SMB3))
linux-cifs@vger.kernel.org (open list:COMMON INTERNET FILE SYSTEM CLIENT (CIFS and SMB3))
samba-technical@lists.samba.org (moderated list:COMMON INTERNET FILE SYSTEM CLIENT (CIFS and SMB3))
linux-kernel@vger.kernel.org (open list)
EOF
)

test() {
	local output_str=${test_str}
	# echo "${output_str}"
	iter_str "${output_str}"
}

pattern=$1
# parse_pattern "$pattern"
test

echo "git send-email --to=${to_emails[@]}"


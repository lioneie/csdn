# 检查参数
if [ $# -ne 2 ]; then
	echo "用法: bash $0 <commit_id> <mainline/stable>"
	exit 1
fi

commit_id=$1
inclusion=$2
repo=""

case "${inclusion}" in
"stable")
	repo="stable"
	;;
"mainline")
	repo="torvalds"
	;;
*)
	echo "inclusion is wrong"
	exit
	;;
esac

subject=$(git log -1 --pretty=format:"%s" ${commit_id})
full_commit_id=$(git rev-parse ${commit_id})
name_rev=$(git name-rev ${commit_id})
version=$(echo ${name_rev} | awk -F'tags/' '{print $2}' | awk -F'~' '{print $1}')

echo "${inclusion} inclusion"
echo "from ${inclusion}-${version}"
echo "commit ${full_commit_id}"
echo "category: bugfix"
echo "bugzilla: "
echo "CVE: NA"
echo
echo "Reference: https://git.kernel.org/pub/scm/linux/kernel/git/${repo}/linux.git/commit/?id=${full_commit_id}"
echo
echo "--------------------------------"
echo
echo "Conflicts:"
echo

# 例子
# mainline inclusion
# from mainline-v6.11-rc5
# commit 4e8771a3666c8f216eefd6bd2fd50121c6c437db
# category: bugfix
# bugzilla: https://gitee.com/src-openeuler/kernel/issues/IARWV6
# CVE: CVE-2024-46742
# 
# Reference: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=4e8771a3666c8f216eefd6bd2fd50121c6c437db
# 
# --------------------------------

. ~/.top-path
code_path=${MY_CODE_TOP_PATH}
user_name=chenxiaosonggithub
github_io_repo=${code_path}/${user_name}.github.io/
# 导入其他脚本
. ${code_path}/blog/src/blog-web/common-lib.sh

git pull github master
git push github master

bash ${code_path}/blog/src/blog-web/create-html.sh false this-arg-is-useless ${github_io_repo}
cp ${code_path}/blog/src/blog-web/github-io-404.html ${github_io_repo}/404.html
cp ${code_path}/blog/src/blog-web/github-io-README.md ${github_io_repo}/README.md
echo "chenxiaosong.com" > ${github_io_repo}/CNAME
comm_generate_index "${github_io_repo}" "" "${github_io_repo}"

cd ${github_io_repo}
git init
git remote add origin git@github.com:${user_name}/${user_name}.github.io.git
git add .
git commit -s -m "chenxiaosong.com"
git branch -m master # 确保分支名为master
git push origin master -f

# others blog
bash ${code_path}/private-blog/others-blog/push-github.sh

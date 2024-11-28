. ~/.top-path
code_path=${MY_CODE_TOP_PATH}
user_name=chenxiaosonggithub

git pull origin master
git push origin master
git pull github master
git push github master

bash ${code_path}/blog/src/blog-web/create-html.sh false this-arg-is-useless ${code_path}/${user_name}.github.io/
cp ${code_path}/blog/src/blog-web/github-io-404.html ${code_path}/${user_name}.github.io/404.html
cp ${code_path}/blog/src/blog-web/github-io-README.md ${code_path}/${user_name}.github.io/README.md
echo "chenxiaosong.com" > ${code_path}/${user_name}.github.io/CNAME
bash ${code_path}/blog/src/blog-web/github-io-create-index.sh ${code_path}/${user_name}.github.io/

cd ${code_path}/${user_name}.github.io/
git init
git remote add origin git@github.com:${user_name}/${user_name}.github.io.git
git add .
git commit -s -m "chenxiaosong.com"
git branch -m master # 确保分支名为master
git push origin master -f

# others blog
bash ${code_path}/private-blog/others-blog/push-git.sh true

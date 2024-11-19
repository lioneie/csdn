code_path=/home/sonvhi/chenxiaosong/code/
user_name=chenxiaosonggithub

git pull origin master
git push origin master
git pull github master
git push github master

bash ${code_path}/blog/src/blog-web/create-html.sh false this-arg-is-useless ${code_path}/${user_name}.github.io/
cp ${code_path}/blog/src/blog-web/404-github-io.html ${code_path}/${user_name}.github.io/404.html
cp ${code_path}/blog/src/blog-web/README-github-io.md ${code_path}/${user_name}.github.io/README.md

cd ${code_path}/${user_name}.github.io/
echo "chenxiaosong.com" > CNAME
git init
git remote add origin git@github.com:${user_name}/${user_name}.github.io.git
git add .
git commit -s -m "chenxiaosong.com"
git push origin master -f

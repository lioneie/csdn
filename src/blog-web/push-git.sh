code_path=/home/sonvhi/chenxiaosong/code/
github_io=chenxiaosonggithub.github.io

git pull origin master
git push origin master
git pull github master
git push github master

bash ${code_path}/blog/src/blog-web/create-html.sh false this-arg-is-useless ${code_path}/${github_io}/
cp ${code_path}/blog/src/blog-web/404.html ${code_path}/${github_io}/

cd ${code_path}/${github_io}/
echo "chenxiaosong.com" > CNAME
git init
git remote add origin git@github.com:chenxiaosonggithub/${github_io}.git
git add .
git commit -s -m "chenxiaosong.com"
git push origin master -f

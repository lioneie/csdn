code_path=/home/sonvhi/chenxiaosong/code/

bash ${code_path}/blog/src/blog-web/create-html.sh false this-arg-is-useless ${code_path}/chenxiaosonggithub.github.io/
cp ${code_path}/blog/src/blog-web/404.html ${code_path}/chenxiaosonggithub.github.io/

cd ${code_path}/chenxiaosonggithub.github.io/
git init
git remote add origin git@github.com:chenxiaosonggithub/chenxiaosonggithub.github.io.git
git add .
git commit -s -m "chenxiaosong.com"
git push origin master -f

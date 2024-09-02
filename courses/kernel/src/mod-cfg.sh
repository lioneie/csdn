if [ $# -ne 1 ]; then
    echo "Usage: $0 \${repo_name}"
    exit 1
fi

mnt_point=/tmp/9p
knl_base_dir=${mnt_point}/code/$1 # 修改成内核代码目录
mkdir $mnt_point
mkdir /lib/modules -p
mount -t 9p -o trans=virtio 9p $mnt_point
knl_vers=$(uname -r)
target=${knl_base_dir}/build/mod/lib/modules/${knl_vers}
link_name=/lib/modules/${knl_vers}
rm ${link_name} -rf
ln -s ${target} ${link_name}
# 重新链接build目录
rm /lib/modules/${knl_vers}/build
ln -s ${knl_base_dir}/build/ /lib/modules/${knl_vers}/build
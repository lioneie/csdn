docker_name=workspace-ubuntu2204
image_repository=workspace-ubuntu
image_tag=22.04
docker ps -a # 查看容器
docker stop ${docker_name} # 停止容器
mv ${docker_name}.tar ${docker_name}.tar.bak # 重命名备份
docker export ${docker_name} > ${docker_name}.tar # 导出容器
docker rm ${docker_name} # 删除容器
docker ps -a # 查看容器是否删除成功
docker image rm ${image_repository}:${image_tag} # 删除镜像
docker image ls # 查看镜像是否删除成功
cat ${docker_name}.tar | docker import - ${image_repository}:${image_tag} # 导入镜像
docker image ls # 查看镜像是否导入成功

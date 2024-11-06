docker_name=workspace-ubuntu2204
image_repository=workspace-ubuntu
image_tag=22.04
host_dir=/home/sonvhi/chenxiaosong
container_dir=/home/sonvhi/chenxiaosong

docker run --name ${docker_name} --hostname ${docker_name} --privileged -itd -v ${host_dir}:${container_dir} -w ${container_dir} ${image_repository}:${image_tag} bash
# docker exec -it ${docker_name} bash

dir_name=enfs-patchset

patch_file_1='0001-nfs_add_api_to_support_enfs_registe_and_handle_mount_option.patch'
header_str_1=$(cat <<EOF
Subject: nfs: add api to support enfs registe and handle mount option

At the NFS layer, the eNFS registration function is called back when
the mount command parses parameters. The eNFS parses and saves the IP
address list entered by users.
EOF
)

patch_file_2='0002-sunrpc_add_api_to_support_enfs_registe_and_create_multipath_then_dispatch_IO.patch'
header_str_2=$(cat <<EOF
Subject: sunrpc: add api to support enfs registe and create multipath then dispatch IO

At the sunrpc layer, the eNFS registration function is called back When
the NFS uses sunrpc to create rpc_clnt, the eNFS combines the IP address
list entered for mount to generate multiple xprts. When the I/O times
out, the callback function of the eNFS is called back so that the eNFS
switches to an available link for retry.
EOF
)

patch_file_3='0003-add_enfs_module_for_nfs_mount_option.patch'
header_str_3=$(cat <<EOF
Subject: nfs: add enfs module for nfs mount option

The eNFS module registers the interface for parsing the mount command.
During the mount process, the NFS invokes the eNFS interface to enable
the eNFS to parse the mounting parameters of UltraPath. The eNFS module
saves the mounting parameters to the context of nfs_client.
EOF
)

patch_file_4='0004-add_enfs_module_for_sunrpc_multipatch.patch'
header_str_4=$(cat <<EOF
Subject: nfs: add enfs module for sunrpc multipatch

When the NFS invokes the SunRPC to create rpc_clnt, the eNFS interface
is called back. The eNFS creates multiple xprts based on the output IP
address list. When NFS V3 I/Os are delivered, eNFS distributes I/Os to
available links based on the link status, improving performance through
load balancing.
EOF
)

patch_file_5='0005-add_enfs_module_for_sunrpc_failover_and_configure.patch'
header_str_5=$(cat <<EOF
Subject: nfs: add enfs module for sunrpc failover and configure

When sending I/Os from the SunRPC module to the NFS server times out,
the SunRPC module calls back the eNFS module to reselect a link. The
eNFS module distributes I/Os to other available links, preventing
service interruption caused by a single link failure.
EOF
)

patch_file_6='0006-add_enfs_compile_option.patch'
header_str_6=$(cat <<EOF
Subject: nfs, sunrpc: add enfs compile option

The eNFS compilation option and makefile are added. By default, the eNFS
compilation is performed.
EOF
)

create_full_patch() {
	local -n patch_file=patch_file_$1
	local -n header_str=header_str_$1

	{
		echo "From: mingqian218472 <zhangmingqian.zhang@huawei.com>"
		echo "$header_str"
		echo -e "\nSigned-off-by: mingqian218472 <zhangmingqian.zhang@huawei.com>"
		curl https://gitee.com/src-openeuler/kernel/raw/openEuler-20.03-LTS-SP4/${patch_file}
	} > ${dir_name}/temp_filename && mv ${dir_name}/temp_filename ${dir_name}/${patch_file}
}

mkdir ${dir_name}
for ((index=1; index<=6; index=$((index + 1)))); do
	create_full_patch ${index}
done

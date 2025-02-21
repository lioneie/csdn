mkfs.ext4 -b 4096 -F /dev/sda
mkfs.ext4 -b 4096 -F /dev/sdb

mkdir /tmp/s_test
mkdir /tmp/s_scratch

mount -t ext4 /dev/sda /tmp/s_test
mount -t ext4 /dev/sdb /tmp/s_scratch

systemctl stop firewalld
setenforce 0

systemctl restart smbd.service # debian
systemctl restart smb.service # fedora

chmod 777 /tmp/s_test
chmod 777 /tmp/s_scratch

mkdir /tmp/test
mkdir /tmp/scratch

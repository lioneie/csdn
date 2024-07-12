config_file=/usr/local/etc/v2ray/config.json
target_line="            \"port\": "

port=${1}
if [ -z "${port}" ]
then
        echo "Please specify port!!!"
        return 1
fi

sed -i "s/^${target_line}.*$/${target_line}${port},/" ${config_file}

sudo systemctl restart v2ray

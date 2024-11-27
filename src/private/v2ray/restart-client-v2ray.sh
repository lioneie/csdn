. ~/.top-path
config_file=${MY_TOP_PATH}/sw/v2ray-linux-64/config.json
port_line="                        \"port\": "
country_line="                        \"address\": "

port=${1}
country=${2}
if [ -z "${port}" -o -z "${country}" ]
then
	echo "Usage:"
	echo "  . restart-client-v2ray.sh \${port} \${country}"
	exit 1
fi

sed -i "s/^${port_line}.*$/${port_line}${port},/" ${config_file}
sed -i "s/^${country_line}.*$/${country_line}\"${country}.chenxiaosong.com\",/" ${config_file}

sudo systemctl restart v2ray

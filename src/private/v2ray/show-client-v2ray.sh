. ~/.top-path
config_file=${MY_TOP_PATH}/sw/v2ray-linux-64/config.json
port_line="                        \"port\": "
country_line="                        \"address\": "

cat ${config_file} | grep "${port_line}"
cat ${config_file} | grep "${country_line}"

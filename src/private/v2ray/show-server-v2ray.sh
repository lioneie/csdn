config_file=/usr/local/etc/v2ray/config.json
target_line="            \"port\": "


cat ${config_file} | grep "${target_line}"

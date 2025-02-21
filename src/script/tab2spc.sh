#!/bin/bash

# 检查参数
if [ $# -ne 1 ]; then
	echo "用法: $0 <文件名>"
	exit 1
fi

# 检查文件是否存在
if [ ! -f "$1" ]; then
	echo "文件 '$1' 不存在."
	exit 1
fi

# 替换Tab为8个空格并且Tab结尾处对齐到8的倍数
expand -t 8 "$1" > "$1.tmp"
mv "$1.tmp" "$1"

echo "Tab已成功替换为8个空格，并且Tab结尾处已对齐到8的倍数。"

CC = gcc
CFLAGS = -Wall

# 查找所有的 .c 文件
SOURCES = $(shell find . -type f -name "*.c")
# 生成对应的可执行文件名
EXECUTABLES = $(SOURCES:.c=)

all: $(EXECUTABLES)

%: %.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f $(EXECUTABLES)

# 我写的补丁

[点击查看kernel.org网站上我的Linux内核邮件列表](https://lore.kernel.org/all/?q=chenxiaosong)

[点击查看kernel.org网站上我的Linux内核仓库提交记录](https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/log/?qt=grep&q=chenxiaosong)（加载需要一丢丢时间哈）

[CVE-2024-46742: `4e8771a3666c8 smb/server: fix potential null-ptr-deref of lease_ctx_info in smb2_open()`](https://chenxiaosong.com/course/smb/patch/CVE-2024-46742.html)

[`542228db2f28f cifs: fix use-after-free on the link name`](https://patchwork.kernel.org/project/cifs-client/patch/20221104074441.634677-1-chenxiaosong2@huawei.com/)

[`502487847743 cifs: fix missing unlock in cifs_file_copychunk_range()`](https://patchwork.kernel.org/project/cifs-client/patch/20221119045159.1400244-1-chenxiaosong2@huawei.com/)

[`2624b445544f ksmbd: fix possible refcount leak in smb2_open()`](https://patchwork.kernel.org/project/cifs-client/patch/20230302135804.2583061-1-chenxiaosong2@huawei.com/)

[`2186a116538a7 smb/server: fix return value of smb2_open()`](https://lore.kernel.org/all/20240822082101.391272-2-chenxiaosong@chenxiaosong.com/)

[`2b058acecf56f cifs: return the more nuanced writeback error on close()`](https://lore.kernel.org/all/20220518145649.2487377-1-chenxiaosong2@huawei.com/)

补丁集: [`[PATCH v2 00/12] smb: fix some bugs, move duplicate definitions to common header file, and some small cleanups`](https://lore.kernel.org/all/20240822082101.391272-1-chenxiaosong@chenxiaosong.com/)

# 我写的补丁

[点击查看kernel.org网站上我的Linux内核邮件列表](https://lore.kernel.org/all/?q=chenxiaosong)

[点击查看kernel.org网站上我的Linux内核仓库提交记录](https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/log/?qt=grep&q=chenxiaosong)（加载需要一丢丢时间哈）

<!--
[`542228db2f28f cifs: fix use-after-free on the link name`](https://chenxiaosong.com/courses/smb/patches/cifs-fix-use-after-free-on-the-link-name.html)
-->

[`502487847743 cifs: fix missing unlock in cifs_file_copychunk_range()`](https://patchwork.kernel.org/project/cifs-client/patch/20221119045159.1400244-1-chenxiaosong2@huawei.com/)

[`2624b445544f ksmbd: fix possible refcount leak in smb2_open()`](https://patchwork.kernel.org/project/cifs-client/patch/20230302135804.2583061-1-chenxiaosong2@huawei.com/)

[`2186a116538a7 smb/server: fix return value of smb2_open()`](https://lore.kernel.org/all/20240822082101.391272-2-chenxiaosong@chenxiaosong.com/)

[CVE-2024-46742](https://nvd.nist.gov/vuln/detail/CVE-2024-46742): [`4e8771a3666c8 smb/server: fix potential null-ptr-deref of lease_ctx_info in smb2_open()`](https://lore.kernel.org/all/20240822082101.391272-3-chenxiaosong@chenxiaosong.com/)

[`2b058acecf56f cifs: return the more nuanced writeback error on close()`](https://lore.kernel.org/all/20220518145649.2487377-1-chenxiaosong2@huawei.com/)

补丁集: [`[PATCH v2 00/12] smb: fix some bugs, move duplicate definitions to common header file, and some small cleanups`](https://lore.kernel.org/all/20240822082101.391272-1-chenxiaosong@chenxiaosong.com/)

# 其他人的补丁

<!--
[`7de0394801da cifs: Fix in error types returned for out-of-credit situations.`](https://chenxiaosong.com/courses/smb/patches/cifs-Fix-in-error-types-returned-for-out-of-credit-s.html)

[`d328c09ee9f1 smb: client: fix use-after-free bug in cifs_debug_data_proc_show()`](https://chenxiaosong.com/courses/smb/patches/cve-smb-client-fix-use-after-free-bug-in-cifs_debug_data.html)

[`87f93d82e0952 smb3: fix problem with null cifs super block with previous patch`](https://chenxiaosong.com/courses/smb/patches/smb3-fix-problem-with-null-cifs-super-block-with-pre.html)
-->

[`69ccf040acdd smb: client: fix potential UAF in is_valid_oplock_break()`](https://chenxiaosong.com/courses/smb/patches/cve-smb-client-fix-potential-UAF-in-is_valid_oplock_brea.html)

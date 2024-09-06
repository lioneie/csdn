[OpenHarmony](https://www.openharmony.cn/mainPlay)是华为“鸿蒙操作系统”的底座，包含: 华为捐献的“鸿蒙操作系统”的基础能力 和 其他参与者的贡献。

华为的HarmonyOS（鸿蒙操作系统）与OpenHarmony的关系，相当于谷歌的Android（安卓系统）与AOSP(Android Open Source Project)的关系。

主要从事开发**端云协同**功能，也就是端设备（如手机、智能设备等）与云端（云服务、云计算资源）之间的协同工作和通信，工作内容有 **内核hmdfs（鸿蒙分布式文件系统）** 、 **fuse（用户态文件系统）** 和 **媒体库** 等开发。

OpenHarmony的代码托管在gitee上，gitee的功能挺完善，但在尊重开源方面以及一些细节方面有待加强，曾经我公开给gitee提过这一问题，具体请查看[《gitee的搜索功能真的很有问题》](https://gitee.com/oschina/git-osc/issues/I76RNI)。

# 内核

基于社区LTS 5.10版本，自研hmdfs（鸿蒙分布式文件系统）等特性。

[动态加载端云场景的dentryfile，读云端文件](https://gitee.com/openharmony/kernel_linux_5.10/pulls/791/commits)

[hmdfs: fix compile warning in hmdfs_file_open_cloud()](https://gitee.com/openharmony/kernel_linux_5.10/pulls/775/commits)

[hmdfs: use 'vfs_iter_read' instead of 'vfs_read' in 'hmdfs_file_read_iter_cloud()](https://gitee.com/openharmony/kernel_linux_5.10/commit/75a864d47e45457de395456c593964b0129f0c5e)（可能需要注册登录才能查看）

[hmdfs: implement 'mmap' interface of 'hmdfs_dev_file_fops_cloud'](https://gitee.com/openharmony/kernel_linux_5.10/pulls/900/commits)

[hmdfs: prohibit renaming cross-view for cloud merge](https://gitee.com/openharmony/kernel_linux_5.10/pulls/917/commits)

[hmdfs: fix possible use-after-free in hmdfs lookup()](https://gitee.com/openharmony/kernel_linux_5.10/pulls/910/commits )

[hmdfs: fix attribute error when mkdir in cloud_merge_view/merge_view](https://gitee.com/openharmony/kernel_linux_5.10/pulls/927/commits)

[hmdfs: fix braces coding style](https://gitee.com/openharmony/kernel_linux_5.10/pulls/940/commits)

[hmdfs: sync lookup cloud merge view](https://gitee.com/openharmony/kernel_linux_5.10/pulls/967/commits)

[hmdfs: implement 'unlink' interface for 'hmdfs_dev_dir_inode_ops_cloud'](https://gitee.com/openharmony/kernel_linux_5.10/pulls/991/commits)

[hmdfs: make hmdfs_unlink_cloud() always succeed](https://gitee.com/openharmony/kernel_linux_5.10/pulls/1012/commits)

# 分布式文件系统

分布式文件系统用户态服务，功能主要包括挂载/卸载hmdfs，在设备间已组网的前提下，通过分布式软总线建立通信链路，供内核hmdfs使用。

[dfs: fuse read cloud file](https://gitee.com/openharmony/filemanagement_dfs_service/pulls/258/commits)

[dfs: always read from dentryfile instead from cache when lookup](https://gitee.com/openharmony/filemanagement_dfs_service/pulls/362/commits)

[dfs: clean up build warnings](https://gitee.com/openharmony/filemanagement_dfs_service/pulls/220/commits)

[dfs: fix 'user_data_rw' user open fuse mountpoint fail](https://gitee.com/openharmony/filemanagement_dfs_service/pulls/407/commits)

[dfs: save thumbnail/lcd pictures locally after read done](https://gitee.com/openharmony/filemanagement_dfs_service/pulls/480/commits)

[dfs: fix failure to remove from dentryfile when thumbnail/lcd reading is done](https://gitee.com/openharmony/filemanagement_dfs_service/pulls/486/commits)

[dfs: fix use-after-free in CloudRelease()](https://gitee.com/openharmony/filemanagement_dfs_service/pulls/529/commits)

[cloudfiledaemon: delete file of cloud merge view to update kernel dentry cache](https://gitee.com/openharmony/filemanagement_dfs_service/pulls/547/commits)

[cloudfiledaemon/cloudsyncservice: rename from temp path to local path after downloading is complete](https://gitee.com/openharmony/filemanagement_dfs_service/pulls/558/commits)

[cloudsyncservice: implement stop download](https://gitee.com/openharmony/filemanagement_dfs_service/pulls/608/commits)

[cloudsyncservice: fix stop download](https://gitee.com/openharmony/filemanagement_dfs_service/pulls/628/commits)

# 存储管理部件

存储管理部件提供外置存储卡挂载管理、文件加解密、磁盘和卷的查询与管理、用户目录管理和空间统计等功能，为系统和应用提供基础的存储查询、管理能力。

[add hmdfs mount option 'cloud_dir'](https://gitee.com/openharmony/filemanagement_storage_service/pulls/526/commits)

[storagedaemon: create directory '/data/service/el2/{userid}/hmdfs/fuse'](https://gitee.com/openharmony/filemanagement_storage_service/pulls/530/commits)

[storagedaemon: add fuse umount](https://gitee.com/openharmony/filemanagement_storage_service/pulls/534/commits)

[storagedaemon: pass user id to clouddaemon when mount fuse](https://gitee.com/openharmony/filemanagement_storage_service/pulls/551/commits)

[storagedaemon: mount fuse when cloudfiledaemon is ready](https://gitee.com/openharmony/filemanagement_storage_service/pulls/558/commits)

[storage_daemon: change fuse mountpoint from '/mnt/hmdfs/{userid}/cloud' to '/mnt/data/{userid}/cloud'](https://gitee.com/openharmony/filemanagement_storage_service/pulls/613/commits)

# 媒体库

数据库管理，文件管理，为提供用户态程序提供napi调用接口。

[Add 'position' column to medialibrary database](https://gitee.com/openharmony/multimedia_medialibrary_standard/pulls/1551/commits)

[declare napi property 'enum PositionType'](https://gitee.com/openharmony/multimedia_medialibrary_standard/pulls/1623/commits)

# selinux

让设备更安全。

[Add storage_daemon umount fuse selinux policy](https://gitee.com/openharmony/security_selinux_adapter/pulls/2325/commits)

# 应用孵化模块

[appdata-sandbox.json: add medialibrary sandbox-path '/mnt/data/<currentUserId>'](https://gitee.com/openharmony/startup_appspawn/pulls/768/commits)

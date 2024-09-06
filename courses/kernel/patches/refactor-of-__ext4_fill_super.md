Jason Yan <yanaijie@huawei.com>的ext4重构补丁集，`ext4_fill_super()`函数重构前有1093行。

# [`[v3,00/16] some refactor of __ext4_fill_super()`](https://patchwork.ozlabs.org/project/linux-ext4/cover/20220916141527.1012715-1-yanaijie@huawei.com/)

```
这个函数可能是我在内核中见过的最长的函数，它有一千多行。这使得阅读和理解代码变得困难。因此，我进行了些许重构。前两个补丁做了一些准备工作，为了方便我们将一些函数提取出来。

经过这次重构，这个函数减少了大约500行。我没有继续进行，因为我不确定大家是否喜欢这种修改。如果有任何不良副作用，请告知我。如果您强烈不喜欢这种改动，我可以停止这次重构。

v2->v3:
补丁 #7 在未启用 CONFIG_UNICODE 时定义了一个空函数。
添加补丁 #14~16 以统一超级块加载，并将 DIOREAD_NOLOCK 设置移到 ext4_set_def_opts()。
添加了 Ritesh 的一些 reviewed-by 标签。

v1->v2:
根据 Jan Kara 的建议进行了一些代码改进，并添加了审核标签。
```

## [`[v3,01/16] ext4: goto right label 'failed_mount3a'`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-2-yanaijie@huawei.com/)

```
在这两个分支之前，既没有加载日志也没有创建 xattr 缓存。因此，正确的跳转标签应该是 'failed_mount3a'。虽然这没有造成任何问题，因为错误处理程序验证了指针是否为空，但在阅读代码时仍然让我感到困惑。因此，还是值得修改以跳转到正确的标签。
```

## [`[v3,02/16] ext4: remove cantfind_ext4 error handler`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-3-yanaijie@huawei.com/)

```
'cantfind_ext4' 错误处理程序只是打印错误信息，然后跳转到 failed_mount。这种两级跳转使代码变得复杂，不容易阅读。唯一的好处是节省了一点代码。然而，有些分支可以合并，有些分支甚至不需要它。因此，进行一些重构并删除它。
```

## [`[v3,03/16] ext4: factor out ext4_set_def_opts()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-4-yanaijie@huawei.com/)

```
将 ext4_set_def_opts() 提取出来。功能没有变化。
```

## [`[v3,04/16] ext4: factor out ext4_handle_clustersize()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-5-yanaijie@huawei.com/)

```
将 ext4_handle_clustersize() 提取出来。功能没有变化。
```

## [`[v3,05/16] ext4: factor out ext4_fast_commit_init()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-6-yanaijie@huawei.com/)

```
将 ext4_fast_commit_init() 提取出来。功能没有变化。
```

## [`[v3,06/16] ext4: factor out ext4_inode_info_init()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-7-yanaijie@huawei.com/)

```
将 ext4_inode_info_init() 提取出来。功能没有变化。
```

## [`[v3,07/16] ext4: factor out ext4_encoding_init()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-8-yanaijie@huawei.com/)

```
将 ext4_encoding_init() 提取出来。功能没有变化。
```

## [`[v3,08/16] ext4: factor out ext4_init_metadata_csum()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-9-yanaijie@huawei.com/)

```
将 ext4_init_metadata_csum() 提取出来。功能没有变化。
```

## [`[v3,09/16] ext4: factor out ext4_check_feature_compatibility()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-10-yanaijie@huawei.com/)

```
将 ext4_check_feature_compatibility() 提取出来。功能没有变化。
```

## [`[v3,10/16] ext4: factor out ext4_geometry_check()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-11-yanaijie@huawei.com/)

```
将 ext4_geometry_check() 提取出来。功能没有变化。
```

## [`[v3,11/16] ext4: factor out ext4_group_desc_init() and ext4_group_desc_free()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-12-yanaijie@huawei.com/)

```
将 ext4_group_desc_init() 和 ext4_group_desc_free() 提取出来。功能没有变化。
```

## [`[v3,12/16] ext4: factor out ext4_load_and_init_journal()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-13-yanaijie@huawei.com/)

```
将 ext4_load_and_init_journal() 提取出来。功能没有变化。
```

## [`[v3,13/16] ext4: factor out ext4_journal_data_mode_check()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-14-yanaijie@huawei.com/)

```
将 ext4_journal_data_mode_check() 提取出来。功能没有变化。
```

## [`[v3,14/16] ext4: unify the ext4 super block loading operation`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-15-yanaijie@huawei.com/)

```
我们从磁盘加载超级块分为两个步骤。首先，我们使用默认的块大小（EXT4_MIN_BLOCK_SIZE）加载超级块。然后，我们使用实际的块大小加载超级块。第二个步骤距离第一个步骤有点远。这个补丁将这两个步骤合并到一个新函数中。
```

## [`[v3,15/16] ext4: remove useless local variable 'blocksize'`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-16-yanaijie@huawei.com/)

```
由于 sb->s_blocksize 现在在一开始就被初始化了，所以在 __ext4_fill_super() 中的局部变量 blocksize 现在不再需要。删除它并改用 sb->s_blocksize。
```

## [`[v3,16/16] ext4: move DIOREAD_NOLOCK setting to ext4_set_def_opts()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220916141527.1012715-17-yanaijie@huawei.com/)

```
现在，既然所有准备工作都已完成，我们可以将 DIOREAD_NOLOCK 设置移到 ext4_set_def_opts() 中。
```

# [`[0/8] some refactor of __ext4_fill_super(), part 2.`](https://patchwork.ozlabs.org/project/linux-ext4/cover/20230323140517.1070239-1-yanaijie@huawei.com/)

```
这是一个持续的努力，旨在使 __ext4_fill_super() 更简短和更易读。之前的工作可以在这里找到[1]。由于我利用业余时间进行这项工作，所以在之前的系列之后有点晚了。

[1] http://patchwork.ozlabs.org/project/linux-ext4/cover/20220916141527.1012715-1-yanaijie@huawei.com/
```

## [`[1/8] ext4: factor out ext4_hash_info_init()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20230323140517.1070239-2-yanaijie@huawei.com/)

```
将 ext4_hash_info_init() 提取出来。功能没有变化。
```

## [`[2/8] ext4: factor out ext4_percpu_param_init() and ext4_percpu_param_destroy()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20230323140517.1070239-3-yanaijie@huawei.com/)

```
将 ext4_percpu_param_init() 和 ext4_percpu_param_destroy() 提取出来。同时，在 ext4_put_super() 中使用 ext4_percpu_param_destroy() 以避免重复代码。没有功能上的改变。
```

## [`[3/8] ext4: use ext4_group_desc_free() in ext4_put_super() to save some duplicated code`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20230323140517.1070239-4-yanaijie@huawei.com/)

```
这里唯一的区别是 ->s_group_desc 和 ->s_flex_groups 在这里共享了相同的 RCU 读取锁，但这并不必要。在其他地方，它们根本不共享锁。
```

## [`[4/8] ext4: factor out ext4_flex_groups_free()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20230323140517.1070239-5-yanaijie@huawei.com/)

```
提取 ext4_flex_groups_free()，使其可以在 __ext4_fill_super() 和 ext4_put_super() 中使用。
```

## [`[5/8] ext4: rename two functions with 'check'`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20230323140517.1070239-6-yanaijie@huawei.com/)

```
统一函数命名风格是一项良好的代码维护实践。你可以将所有函数命名风格调整为一致的形式，比如将以下风格统一为一种:

ext4_check_quota_consistency
ext4_check_test_dummy_encryption
ext4_check_opt_consistency
ext4_check_descriptors
ext4_check_feature_compatibility
或者:

ext4_geometry_check
ext4_journal_data_mode_check
选择一种风格并在所有相关函数中应用，可以提高代码的一致性和可读性。
```

## [`[6/8] ext4: move s_reserved_gdt_blocks and addressable checking into ext4_check_geometry()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20230323140517.1070239-7-yanaijie@huawei.com/)

```
这两个检查更适合放在 ext4_check_geometry() 中，而不是分散在外面。
```

## [`[7/8] ext4: factor out ext4_block_group_meta_init()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20230323140517.1070239-8-yanaijie@huawei.com/)

```
将 ext4_block_group_meta_init() 提取出来。功能没有变化。
```

## [`[8/8] ext4: move dax and encrypt checking into ext4_check_feature_compatibility()`](https://patchwork.ozlabs.org/project/linux-ext4/patch/20230323140517.1070239-9-yanaijie@huawei.com/)

```
这些检查也与功能兼容性检查相关。因此，将它们移动到 ext4_check_feature_compatibility() 中。没有功能上的改变。
```
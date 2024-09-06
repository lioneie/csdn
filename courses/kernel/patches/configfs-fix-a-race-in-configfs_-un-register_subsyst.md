这篇文章分析一下补丁[`84ec758fb2da configfs: fix a race in configfs_{,un}register_subsystem()`](https://lore.kernel.org/all/20220215071030.3067982-1-chenxiaosong2@huawei.com/)

假设现在循环链表中有4个元素:
```sh
D --> A --> B --> C --> D --> A
D <-- A <-- B <-- C <-- D <-- A
```

同时删除B和C时:
```c
     delete list_head *B        |      delete list_head *C
--------------------------------|-----------------------------------
configfs_unregister_subsystem   |   configfs_unregister_subsystem
  unlink_group                  |     unlink_group
    unlink_obj                  |       unlink_obj
      list_del_init             |         list_del_init
        __list_del_entry        |           __list_del_entry
          __list_del            |             __list_del
            // prev == A        |               // prev == B
            // next == C        |               // next == D
--------------------------------|-----------------------------------
            // C->prev = A      |
            next->prev = prev   |
--------------------------------|-----------------------------------
                                |               // D->prev = B
                                |               next->prev = prev
--------------------------------|-----------------------------------
            // A->next = C      |
            prev->next = next   |
--------------------------------|-----------------------------------
                                |               // B->next = D
                                |               prev->next = next
--------------------------------|-----------------------------------
// module_exit done             |   // module_exit done
// free config_item->ci_entry   |   // free config_item->ci_entry
```

当没有并发，一前一后发生时，循环链表中预期只剩下A和D两个元素。

但并发删除，这时链表就变成以下这个鬼样子，但B和C已经被释放了:
```sh
            +-----------+
            |           |
            |           v
D --> A    (B)-->(C) --> D --> A
      |           ^
      |           |
      +-----------+


            +-----------+
            |           |
            v           |
D <-- A <--(B)   (C)<-- D <-- A
      ^           |
      |           |
      +-----------+
```

如果这时再删除A，就会发生use-after-free :
```c
configfs_unregister_subsystem
  unlink_group
    unlink_obj
      list_del_init
        __list_del_entry(A)
          __list_del(prev = A->prev == D, next = A->next == C)
            prev == D
            next == C
            next->prev = C->prev = D // C已被释放，发生use-after-free
```
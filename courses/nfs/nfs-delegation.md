
`echo something > /mnt/file; echo 3 > /proc/sys/vm/drop_caches; cat > /mnt/file`:
```c
nfsd4_open
  nfsd4_process_open2
    nfs4_open_delegation
      nfs4_set_delegation
        alloc_init_deleg
          nfs4_alloc_stid
      nfs4_put_stid(&dp->dl_stid)
```

`echo 3 > /proc/sys/vm/drop_caches`:
```c
nfsd4_delegreturn
  destroy_delegation
    destroy_unhashed_deleg
      nfs4_put_stid
  nfs4_put_stid
```
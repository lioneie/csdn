# `df`命令

client会发送两个`GETATTR`请求，第一个`GETATTR`请求以下内容:

- `Attr mask[0]: 0x0010011a (Type, Change, Size, FSID, FileId)`
- `Attr mask[1]: 0x00b0a23a (Mode, NumLinks, Owner, Owner_Group, RawDev, Space_Used, Time_Access, Time_Metadata, Time_Modify, Mounted_on_FileId)`

第二个`GETATTR`请求以下内容:

- `Attr mask[0]: 0x00e00000 (Files_Avail, Files_Free, Files_Total)`
- `Attr mask[1]: 0x00001c00 (Space_Avail, Space_Free, Space_Total)`

# 网络超时

```sh
systemctl stop nfs-server
stat /mnt/file

[100196.619028] nfs: server localhost not responding, still trying
[100216.521372] nfs: server localhost not responding, timed out
```

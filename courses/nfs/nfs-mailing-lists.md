nfs client是我相对比较熟悉的模块，但nfs client maintainer很不友好，所以不准备再贡献nfs client。nfs server maintainer友好，就想多看看社区补丁学习一下。

- [邮件列表](https://lore.kernel.org/linux-nfs/)
- [patchwork](https://patchwork.kernel.org/project/linux-nfs/list/)

# 社区

- nfs client maintainer: Trond Myklebust <trondmy@kernel.org>，Anna Schumaker <anna@kernel.org>。
- nfs server maintainer(supporter): Chuck Lever <chuck.lever@oracle.com>（友好），Jeff Layton <jlayton@kernel.org>。
- sunrpc maintainer: Trond Myklebust <trondmy@kernel.org>，Anna Schumaker <anna@kernel.org>。
- [邮件列表](https://lore.kernel.org/linux-nfs/)
- [patchwork](https://patchwork.kernel.org/project/linux-nfs/list/)

获取supporter、reviewer、maintainer、open list的邮箱:
```sh
./scripts/get_maintainer.pl net/sunrpc/
./scripts/get_maintainer.pl fs/nfs/
./scripts/get_maintainer.pl fs/nfs_common/
./scripts/get_maintainer.pl fs/nfsd/
```

sunrpc模块发送补丁:
```sh
git send-email --to=trondmy@kernel.org,trond.myklebust@hammerspace.com,anna@kernel.org,chuck.lever@oracle.com,jlayton@kernel.org,neilb@suse.de,kolga@netapp.com,Dai.Ngo@oracle.com,tom@talpey.com,davem@davemloft.net,edumazet@google.com,kuba@kernel.org,pabeni@redhat.com --cc=linux-nfs@vger.kernel.org,netdev@vger.kernel.org,linux-kernel@vger.kernel.org 00*
```

nfs模块发送补丁:
```sh
git send-email --to=chuck.lever@oracle.com,trondmy@kernel.org,anna@kernel.org,trond.myklebust@hammerspace.com,jlayton@kernel.org,neilb@suse.de,kolga@netapp.com,Dai.Ngo@oracle.com,tom@talpey.com --cc=linux-nfs@vger.kernel.org,linux-kernel@vger.kernel.org 00*
```

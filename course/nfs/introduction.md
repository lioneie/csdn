<!--
client和server要有相同的账号

server端口2049

rpc最主要功能指定每个功能对应的端口，固定111端口监听client需求并回复正确的端口

`rpc.nfsd`, `rpc.mountd`, `rpc.lockd`, `rpc.statd`
-->
# sunrpc和nfs

client端通过nfs操作存储设备经过的路径如下图所示:
```sh
     client                      server
 +------------+              +------------+
 |   client   |              |   storage  |
 |     app    |              |    device  |
 +------------+              +------------+
     1.| ^                     11.| ^ 
       | |                        | |
       v |20.                     v |10. 
 +------------+              +------------+
 |    nfs     |              |    nfsd    |
 |            |              |(nfs server)|
 +------------+              +------------+
     2.| ^                     12.| ^ 
       v |19.                     v |9.    
 +------------+              +------------+
 |   sunrpc   |              |   sunrpc   |
 +------------+              +------------+
     3.| ^                     13.| ^ 
       v |18.                     v |8. 
 +------------+              +------------+
 |    tcp     |              |    tcp     |
 +------------+              +------------+
     4.| ^                     14.| ^ 
       v |17.                     v |7.     
 +------------+              +------------+
 |     ip     |              |     ip     |
 +------------+              +------------+
     5.| ^                     15.| ^
       | |                        | |
       | |  16.+------------+     | |      
       | +-----|  network   |<----+ | 
       +------>|            |-------+
               +------------+ 6.            
```

我们再来看一下OSI七层模型和TCP/IP四层模型中SunRPC的位置:
```sh
      OSI                TCP/IP
  +------------+      +------------+
 7|application |      |            |
  |   layer    |      |            |
  +------------+      |            |
 6|presentation|     4|application | sunrpc
  |   layer    |      |    layer   |
  +------------+      |            |
 5|   session  |      |            |
  |   layer    |      |            |
  +------------+      +------------+
 4| transport  |     3| transport  | tcp
  |   layer    |      |   layer    |
  +------------+      +------------+
 3|  network   |     2| internet   | ip
  |   layer    |      |   layer    |
  +------------+      +------------+
 2|  data link |     1|  network   |
  |   layer    |      |  access    |
  +------------+      |   layer    |
 1|  physical  |      |(link layer)|
  |  layer     |      |            |
  +------------+      +------------+
```

sunrpc之下的tcp层和ip层已经大概率的保证了数据的可靠性，sunrpc不会对数据的可靠性进行校验。但在我曾经定位过的问题中，遇到过一个问题，tcp的校验通过了，但数据还是错误的，概率非常低，所以最终数据的可靠性还要在用户态对文件进行校验。

# rfc协议

[pdf文档翻译请查看百度网盘](https://chenxiaosong.com/baidunetdisk)。

SunRPC有以下几个版本，你们一定和我一样在心里骂制定标准的人，为什么会有3个version 2，就不能命名成version 3和4？我们查阅时只需要选择[最新版本rfc5531](https://www.rfc-editor.org/rfc/rfc5531):

- [rfc1050, April 1988,  RPC: Remote Procedure Call Protocol Specification](https://www.rfc-editor.org/rfc/rfc1050)
- [rfc1057, June 1988,   RPC: Remote Procedure Call Protocol Specification Version 2](https://www.rfc-editor.org/rfc/rfc1057)
- [rfc1831, August 1995, RPC: Remote Procedure Call Protocol Specification Version 2](https://www.rfc-editor.org/rfc/rfc1831)
- [rfc5531, May 2009,    RPC: Remote Procedure Call Protocol Specification Version 2](https://www.rfc-editor.org/rfc/rfc5531)

nfs的rfc协议文档有以下几个版本:

- [rfc1094, March 1989,    NFS: Network File System Protocol Specification](https://www.rfc-editor.org/rfc/rfc1094)
- [rfc1813, June 1995,     NFS Version 3 Protocol Specification](https://www.rfc-editor.org/rfc/rfc1813)
- [rfc7530, March 2015,    Network File System (NFS) Version 4 Protocol](https://www.rfc-editor.org/rfc/rfc7530)
- [rfc8881, August 2020,   Network File System (NFS) Version 4 Minor Version 1 Protocol](https://www.rfc-editor.org/rfc/rfc8881)
- [rfc7862, November 2016, Network File System (NFS) Version 4 Minor Version 2 Protocol](https://www.rfc-editor.org/rfc/rfc7862)

现在很多的发行版已经不支持nfsv2，所以我们的教程只讲解nfsv3和nfsv4相关的代码。

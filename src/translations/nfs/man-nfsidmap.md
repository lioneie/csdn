fedora40上nfs idmap相关的一些命令。

# `man nfsidmap`

```
nfsidmap(8)       系统管理手册      nfsidmap(8)

名称
       nfsidmap - NFS idmapper 上调用程序

语法
       nfsidmap [-v] [-t timeout] key desc
       nfsidmap [-v] [-c]
       nfsidmap [-v] [-u|-g|-r user]
       nfsidmap -d
       nfsidmap -l
       nfsidmap -h

描述
       NFSv4 协议将本地系统的 UID 和 GID 值表示为 user@domain 形式的字符串。 从 UID 到字符串和从字符串到 UID 的转换过程称为“ID 映射”。

       系统通过执行密码或组查找来推导字符串的用户部分。 查找机制在 /etc/idmapd.conf 中配置。

       默认情况下，字符串的域部分是系统的 DNS 域名。 如果系统是多宿主机，或者系统的 DNS 域名与系统的 Kerberos 领域名称不匹配，也可以在 /etc/idmapd.conf 中指定。

       当在 /etc/idmapd.conf 中未指定域时，将查询本地 DNS 服务器以获取 _nfsv4idmapdomain 文本记录。 如果记录存在，则将其用作域。 当记录不存在时，将使用 DNS 域的域部分。

       /usr/sbin/nfsidmap 程序代表内核执行转换。 内核使用请求密钥机制执行上调用。 /usr/sbin/nfsidmap 由 /sbin/request-key 调用，执行转换并使用结果信息初始化一个密钥。 然后，内核将转换结果缓存到密钥中。

       nfsidmap 还可以清除内核中的缓存 ID 映射结果，或撤销某个特定密钥。 错误的缓存密钥可能导致 NFSv4 挂载点上的文件和目录所有权恢复为“nobody”。

       此外，-d 和 -l 选项可用于帮助诊断错误配置。 它们对包含 ID 映射结果的密钥环没有影响。

选项
       -c     清除所有密钥的密钥环。

       -d     在标准输出上显示系统的有效 NFSv4 域名。

       -g user
              撤销给定用户的 gid 密钥。

       -h     显示使用信息。

       -l     在标准输出上显示当前密钥环中用于缓存 ID 映射结果的所有密钥。 这些密钥仅对超级用户可见。

       -r user
              撤销给定用户的 uid 和 gid 密钥。

       -t timeout
              设置密钥的过期计时器，以秒为单位。 默认值为 600 秒（10 分钟）。

       -u user
              撤销给定用户的 uid 密钥。

       -v     增加输出到 syslog 的详细程度（可以多次指定）。

配置
       需要修改文件 /etc/request-key.conf，以便 /sbin/request-key 可以正确引导上调用。 应在调用 keyctl negate 之前添加以下行：

       create    id_resolver    *    *    /usr/sbin/nfsidmap -t 600 %k %d

       这将指向所有 id_resolver 请求到程序 /usr/sbin/nfsidmap。 -t 600 定义密钥将在未来多少秒过期。 这是 /usr/sbin/nfsidmap 的一个可选参数，未指定时默认为 600 秒。

       idmapper 系统使用四个密钥描述：

              uid: 查找给定用户的 UID
              gid: 查找给定组的 GID
             user: 查找给定 UID 的用户名
            group: 查找给定 GID 的组名

       您可以选择单独处理其中的任何一个，而不是使用通用上调用程序。 如果您希望使用自己的程序进行 uid 查找，则应编辑您的 request-key.conf，使其类似于：

       create    id_resolver    uid:*     *    /some/other/program %k %d
       create    id_resolver    *         *    /usr/sbin/nfsidmap %k %d

       请注意，新行添加在通用程序行之前。 request-key 将找到第一个匹配的行并运行相应的程序。 在这种情况下， /some/other/program 将处理所有 uid 查找，而 /usr/sbin/nfsidmap 将处理 gid、user 和 group 查找。

FILES
       /etc/idmapd.conf
              ID mapping configuration file

       /etc/request-key.conf
              Request key configuration file

SEE ALSO
       idmapd.conf(5), request-key(8)

AUTHOR
       Bryan Schumaker, <bjschuma@netapp.com>

1 October 2010                    nfsidmap(8)
```

# `man idmapd.conf`

```
idmapd.conf(5)     文件格式手册        idmapd.conf(5)

名称
       idmapd.conf - libnfsidmap 的配置文件

概要
       libnfsidmap 的配置文件。 由 idmapd 和 svcgssd 使用，用于将 NFSv4 名称与 ID 相互映射。

描述
       idmapd.conf 配置文件由多个部分组成，以 [General] 和 [Mapping] 等字符串开头。每个部分可以包含形式为
         variable = value
       的行。以下是已识别的部分及其识别的变量：

   [General] 部分变量
       Verbosity
              调试的详细程度（默认：0）

       Domain 本地 NFSv4 域名。NFSv4 域是一个具有唯一用户名<->UID 和组名<->GID 映射的命名空间。（默认：主机的完全限定的 DNS 域名）

       No-Strip
              在多域环境中，某些 NFS 服务器将身份管理域附加到所有者和所有者组，而不是使用真正的 NFSv4 域。此选项可以帮助在这种环境中进行查找。如果设置为除 "none" 以外的值，nsswitch 插件将在不去掉域名的情况下首先将名称传递给密码/组查找函数。如果该映射失败，则插件将使用旧方法（将字符串中的域与 Domain 值进行比较，如果匹配则去掉域名，并将生成的短名称传递给查找函数）再次尝试。有效值为 "user"、"group"、"both" 和 "none"。（默认："none"）

       Reformat-Group
              Winbind 有一个特点，即使用 UPN 格式（例如 staff@americas.example.com）查找组时，组将以大写形式显示其完整域（例如 AMERICAS.EXAMPLE.COM\staff），而不是常见的 netbios 名称格式（例如 AMERICAS\staff）。设置此选项为 true 会在将名称传递给组查找函数之前重新格式化名称以解决此问题。除非 No-Strip 设置为 "both" 或 "group"，否则此设置将被忽略。（默认："false"）

       Local-Realms
              可能与本地域名等同的 Kerberos 域名的逗号分隔列表。例如，用户 juser@ORDER.EDU 和 juser@MAIL.ORDER.EDU 在指定的 Domain 中可能被视为同一用户。（默认：主机的默认域名）
              注意：如果在此指定了一个值，则必须包括默认的本地域。

   [Mapping] 部分变量
       Nobody-User
              当映射无法完成时使用的本地用户名。

       Nobody-Group
              当映射无法完成时使用的本地组名。

   [Translation] 部分变量
       Method 一组逗号分隔的、有序的映射方法（插件）列表，用于在 NFSv4 名称和本地 ID 之间进行映射。按顺序尝试每个指定的方法，直到找到映射，或没有更多方法可尝试。默认分发版中包含的映射方法包括 "nsswitch"、"umich_ldap" 和 "static"。（默认：nsswitch）

       GSS-Methods
              一个可选的逗号分隔、有序的映射方法（插件）列表，用于在 GSS 认证名称和本地 ID 之间进行映射。（默认：与为 Method 指定的列表相同）

   [Static] 部分变量
       "static" 翻译方法使用 GSS 认证名称到本地用户名的静态列表。列表中的条目形式为：
        principal@REALM = localusername

   [REGEX] 部分变量
       如果指定了 "regex" 翻译方法，则 [REGEX] 部分中的以下变量用于在 NFS4 名称和本地 ID 之间进行映射。

       User-Regex
              不区分大小写的正则表达式，用于从 NFSv4 名称中提取本地用户名。多个表达式可以用 '|' 连接。将使用第一个匹配项。没有默认值。一个用于域 DOMAIN.ORG 和域 MY.DOMAIN.ORG 的基本正则表达式为：
              ^DOMAIN\([^@]+)@MY.DOMAIN.ORG$

       Group-Regex
              不区分大小写的正则表达式，用于从 NFSv4 名称中提取本地组名。多个表达式可以用 '|' 连接。将使用第一个匹配项。没有默认值。一个用于域 DOMAIN.ORG 和域 MY.DOMAIN.ORG 的基本正则表达式为：
              ^([^@]+)@DOMAIN.ORG@MY.DOMAIN.ORG$|^DOMAIN\([^@]+)@MY.DOMAIN.ORG$

       Prepend-Before-User
              在构建 NFSv4 名称时放在本地用户名之前的常量字符串。通常这是简短的域名，后跟 '´。（默认：无）

       Append-After-User
              在构建 NFSv4 名称时放在本地用户名之后的常量字符串。通常这是 '@' 后跟默认域。（默认：无）

       Prepend-Before-Group
              在构建 NFSv4 名称时放在本地组名之前的常量字符串。通常不使用。（默认：无）

       Append-After-Group
              在构建 NFSv4 名称时放在本地组名之前的常量字符串。通常这是 '@' 后跟域名，再后跟 '@' 和默认域。（默认：无）

       Group-Name-Prefix
              转换为 NFSv4 名称时，在本地组名前添加的常量字符串。如果 NFSv4 组名具有此前缀，则在转换为本地组名时会去除它。使用此功能，中央目录的组名可以为某个独立的组织单位缩短，如果所有组都有一个共同的前缀。（默认：无）

       Group-Name-No-Prefix-Regex
              用于从添加和删除由 Group-Name-Prefix 设置的前缀中排除组的、不区分大小写的正则表达式。正则表达式必须同时匹配远程和本地组名。多个表达式可以用 '|' 连接。（默认：无）

   [UMICH_SCHEMA] 部分变量
       如果指定了 "umich_ldap" 翻译方法，则使用 [UMICH_SCHEMA] 部分中的以下变量。

       LDAP_server
              LDAP 服务器名称或地址（使用 UMICH_LDAP 时必须）

       LDAP_base
              绝对 LDAP 搜索基准。（使用 UMICH_LDAP 时必须）

       LDAP_people_base
              用于人员帐户的绝对 LDAP 搜索基准。（默认：LDAP_base 值）

       LDAP_group_base
              用于组帐户的绝对 LDAP 搜索基准。（默认：LDAP_base 值）

       LDAP_canonicalize_name
              是否对给定的 LDAP_server 名称进行名称规范化（默认："true"）

       LDAP_follow_referrals
              是否跟随 ldap 引用。（默认："true"）

       LDAP_use_ssl
              设置为 "true" 以启用与 LDAP 服务器的 SSL 通信。（默认："false"）

       LDAP_ca_cert
              在启用 SSL 时使用的受信任 CA 证书的位置（如果 LDAP_use_ssl 为 true 且 LDAP_tls_reqcert 未设置为 never，则必须）

       LDAP_tls_reqcert
              控制 LDAP 服务器证书验证行为。它可以采用与 ldap.conf(5) 中的 TLS_REQCERT 可调参数相同的值。（默认："hard"）

       LDAP_timeout_seconds
              LDAP 请求超时的秒数（默认：4）

       LDAP_sasl_mech
              用于 sasl 认证的 SASL 机制。如果要使用 SASL 认证，则必须。（默认：无）

       LDAP_realm
              用于 sasl 认证的 SASL 域。（默认：无）

       LDAP_sasl_authcid
              用于 sasl 认证的认证身份。（默认：无）

       LDAP_sasl_authzid
              用于 sasl 认证的授权身份。（默认：无）

       LDAP_sasl_secprops
              Cyrus SASL 安全属性。它可以与 ldap.conf(5) 中的 sasl_secprops 采用相同的值。

       LDAP_sasl_canonicalize
              指定是否应对 LDAP 服务器主机名进行规范化。如果设置为 yes，LDAP 库将进行反向主机名查找。如果未设置，将使用 LDAP 库的默认值。（默认：无）

       LDAP_sasl_krb5_ccname
              Kerberos 凭证缓存的路径。如果未设置，将使用环境变量 KRB5CCNAME 的值。如果环境变量未设置，将使用 Kerberos 库的默认机制。

       NFSv4_person_objectclass
              您本地 LDAP 模式中人员帐户的对象类名称（默认：NFSv4RemotePerson）

       NFSv4_name_attr
              您本地模式中用于 NFSv4 用户名的属性名称（默认：NFSv4Name）

       NFSv4_uid_attr
              您本地模式中用于 uidNumber 的属性名称（默认：uidNumber）

       GSS_principal_attr
              您本地模式中 GSSAPI 主体名称的属性名称（默认：GSSAuthName）

       NFSv4_acctname_attr
              您本地模式中用于帐户名称的属性名称（默认：uid）

       NFSv4_group_objectclass
              您本地 LDAP 模式中组帐户的对象类名称（默认：NFSv4RemoteGroup）

       NFSv4_gid_attr
              您本地模式中用于 gidNumber 的属性名称（默认：gidNumber）

       NFSv4_group_attr
              您本地模式中用于 NFSv4 组名的属性名称（默认：NFSv4Name）

       LDAP_use_memberof_for_groups
              某些 LDAP 服务器在通过 memberuid 列表搜索用户时的索引效率更高。其他服务器（如 SunOne 目录）在有成千上万的组时，搜索可能需要几分钟。因此，在配置文件中将 LDAP_use_memberof_for_groups 设置为 true 将使用帐户的 memberof 列表，仅在这些组中搜索以获得 gids。（默认：false）

       NFSv4_member_attr
              如果 LDAP_use_memberof_for_groups 为 true，这是要搜索的属性。（默认：memberUid）

       NFSv4_grouplist_filter
              用于确定组成员资格的可选搜索过滤器。（无默认）

示例
       示例 /etc/idmapd.conf 文件：

       [General]

       Verbosity = 0
       Domain = domain.org
       Local-Realms = DOMAIN.ORG,MY.DOMAIN.ORG,YOUR.DOMAIN.ORG

       [Mapping]

       Nobody-User = nfsnobody
       Nobody-Group = nfsnobody

       [Translation]

       Method = umich_ldap,regex,nsswitch
       GSS-Methods = umich_ldap,regex,static

       [Static]

       johndoe@OTHER.DOMAIN.ORG = johnny

       [Regex]

       User-Regex = ^DOMAIN\([^@]+)@DOMAIN.ORG$
       Group-Regex = ^([^@]+)@DOMAIN.ORG@DOMAIN.ORG$|^DOMAIN\([^@]+)@DOMAIN.ORG$
       Prepend-Before-User = DOMAIN
       Append-After-User = @DOMAIN.ORG
       Append-After-Group = @domain.org@domain.org
       Group-Name-Prefix = sales-
       Group-Name-No-Prefix-Regex = -personal-group$

       [UMICH_SCHEMA]

       LDAP_server = ldap.domain.org
       LDAP_base = dc=org,dc=domain

文件
       /usr/etc/idmapd.conf
       /usr/etc/idmapd.conf.d/*.conf
       /etc/idmapd.conf
       /etc/idmapd.conf.d/*.conf

              文件按列出的顺序读取。后面的设置覆盖前面的设置。

SEE ALSO
       idmapd(8) svcgssd(8)

BUGS
       Report bugs to <nfsv4@linux-nfs.org>

19 Nov 2008         idmapd.conf(5)
```

# `man request-key`

```
REQUEST-KEY(8)                Linux 密钥管理工具               REQUEST-KEY(8)

名称
       request-key - 处理来自内核的密钥实例化回调请求

语法
       /sbin/request-key <op> <key> <uid> <gid> <threadring> <processring>      <sessionring> [<info>]

描述
       当内核请求一个它没有立即可用的密钥时，会调用此程序。 内核创建一个部分设置的密钥，然后调用该程序进行实例化。 它并不打算直接调用。

       但是，出于调试目的，可以在命令行上提供一些选项：

       -d     开启调试模式。在此模式下，不会尝试访问任何密钥，如果选择了处理程序程序，则不会执行；而是该程序将打印一条消息并退出 0。

       -D     在调试模式下，使用指定的建议密钥描述，而不是程序内置的示例（“user;0;0;1f0000;debug:1234”）。

       -l     使用当前目录的配置。该程序将使用当前目录中的 request-key.d/* 和 request-key.conf，而不是 /etc 中的。

       -n     不记录到系统日志。通常，错误消息和调试消息将复制到系统日志中 - 这将防止这种情况。

       -v     开启调试输出。可以多次指定此选项，以产生增加的详细程度。

       --version
              打印程序版本并退出。

错误
       所有错误将记录到 syslog。

文件
       /etc/request-key.d/*.conf  单独的配置文件。

       /etc/request-key.conf  备用配置文件。

SEE ALSO
       keyctl(1), request-key.conf(5), keyrings(7)

Linux                15 Nov 2011             REQUEST-KEY(8)
```
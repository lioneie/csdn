#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kthread.h>
#include <net/sock.h>

static struct task_struct *task;

static int server_port = 5555; // 默认端口
module_param(server_port, int, 0644);
MODULE_PARM_DESC(server_port, "The port on which the server will listen");

static int socket_thread(void *data)
{
	struct socket *sock, *newsock;
	struct sockaddr_in addr;
	int err;
	int cnt;
	
	err = sock_create_kern(&init_net, PF_INET, SOCK_STREAM, IPPROTO_TCP, &sock);
	if(err < 0) {
		printk("server sock_create_kern failed, err: %d\n", err);
		return err;
	}

	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_addr.s_addr = htonl(INADDR_ANY);
	addr.sin_port = htons(server_port);
	err = kernel_bind(sock, (struct sockaddr *) &addr, sizeof(addr));
	if (err < 0) {
		printk("server kernel_bind port %d to socket failed, err: %d\n", server_port, err);
		goto release_sock;
	}
	
	err = kernel_listen(sock, 1024);
	if (err < 0) {
		printk("server kernel_listen on port %d failed, err: %d\n", server_port, err);
		goto release_sock;
	}
	
	err = kernel_accept(sock, &newsock, 0);
	if (err < 0) {
		printk("server kernel_accept failed, err: %d\n", err);
		goto release_sock;
	}
	memset(&addr, 0, sizeof(addr));
	err = kernel_getpeername(newsock, (struct sockaddr *)&addr);
	if (err <= 0) {
		printk("server kernel_accept failed, err: %d\n", err);
		goto release_newsock;
	}
	// %pI4 格式化字符串会将 in_addr 类型的 IP 地址转换为字符串并以标准点分十进制的形式打印出来
	printk("server kernel_accept %pI4:%d successful\n", &addr.sin_addr, ntohs(addr.sin_port));

	cnt = 0;
	while (!kthread_should_stop()) {
		struct msghdr msg = { .msg_name = NULL, .msg_flags = MSG_DONTWAIT };
		char buffer[1024];
		int len;
		int buflen = sizeof(buffer);
		struct kvec iov = {
			.iov_base = buffer,
			.iov_len  = (size_t)buflen,
		};

		wait_event_interruptible(*sk_sleep(newsock->sk),
			!skb_queue_empty(&newsock->sk->sk_receive_queue) ||
					 kthread_should_stop());

		// receive message
		if(!skb_queue_empty(&newsock->sk->sk_receive_queue)) {
			len = kernel_recvmsg(newsock, &msg, &iov, 1, buflen,
					     MSG_DONTWAIT);
			if(len < 0)
				printk("server kernel_recvmsg failed, err: %d\n", len);
			else
				printk("server kernel_recvmsg %d bytes, buffer: %s\n", len, buffer);
		}

		// send message
		cnt++;
		sprintf(buffer, "data from server %d", cnt);
		iov.iov_base = buffer;
		iov.iov_len = strlen(buffer);
		kernel_sendmsg(newsock, &msg, &iov, 1, iov.iov_len);
	}
release_newsock:
	sock_release(newsock);
release_sock:
	sock_release(sock);

	return err;
}

static int __init socket_server_init(void)
{
	task = kthread_run(socket_thread, NULL, "socket server thread");
	
	return 0;
}

static void __exit socket_server_exit(void)
{
	if (task) {
		// 如果没调用kthread_stop()，会发生panic
		// https://gitee.com/chenxiaosonggitee/tmp/blob/master/mptcp/kernel-socket-panic-log.txt
		kthread_stop(task);
		task = NULL;
	}
}

module_init(socket_server_init);
module_exit(socket_server_exit);
MODULE_LICENSE("GPL");


#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kthread.h>
#include <net/sock.h>
#include <linux/delay.h>
#include <linux/inet.h>

static struct task_struct *task;

static char *server_ip = "192.168.53.37";  // 默认 server IP 地址
module_param(server_ip, charp, 0644);
MODULE_PARM_DESC(server_ip, "The IP address to connect to");

static int server_port = 5555; // 默认端口
module_param(server_port, int, 0644);
MODULE_PARM_DESC(server_port, "The port on which the server is listening");

static int socket_thread(void *data)
{
	struct socket *sock;
	struct sockaddr_in server_addr;
	char buffer[1024];
	int buflen = sizeof(buffer);
	int err;
	int cnt;
	struct msghdr send_msg;
	struct msghdr recv_msg = { .msg_name = NULL, .msg_flags = MSG_DONTWAIT };
	
	err = sock_create_kern(&init_net, PF_INET, SOCK_STREAM, IPPROTO_TCP, &sock);
	if(err < 0) {
		printk("client sock_create_kern failed, err: %d\n", err);
		return err;
	}
	
	memset(&server_addr, 0, sizeof(server_addr));
	// server_addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK); // 127.0.0.1
	// 将字符串 IP 地址转换为网络字节序的整数
	err = in4_pton(server_ip, strlen(server_ip), (u8 *)&server_addr.sin_addr.s_addr, 0, NULL);
	if (err != 1) {
		printk("client in4_pton failed, err: %d\n", err);
		return -EINVAL;
	}
	server_addr.sin_port = htons(server_port);
	server_addr.sin_family = AF_INET;

	err = kernel_connect(sock, (struct sockaddr *)&server_addr, sizeof(server_addr), 0);
	if (err < 0) {
		printk("client kernel_connect to %s:%d failed, err: %d\n", server_ip, server_port, err);
		goto release_sock;
	}
	printk("client kernel_connect to %s:%d successful\n", server_ip, server_port);

	send_msg.msg_name = &server_addr,
	send_msg.msg_namelen = sizeof(server_addr);
	cnt=0;
	while (!kthread_should_stop()) {
		struct kvec iov;
		// send message
		int len;
		cnt++;
		sprintf(buffer, "data from client %d", cnt);
		iov.iov_base = buffer;
		iov.iov_len = strlen(buffer);
		kernel_sendmsg(sock, &send_msg, &iov, 1, iov.iov_len);

		// receive message
		iov.iov_base = buffer;
		iov.iov_len  = (size_t)buflen;
		// MSG_WAITFORONE是同步读，如果异步读用 MSG_DONTWAIT
		len = kernel_recvmsg(sock, &recv_msg, &iov, 1, buflen,
					MSG_WAITFORONE);
		if(len < 0)
			printk("client kernel_recvmsg failed, err: %d\n", len);
		else
			printk("client kernel_recvmsg %d bytes, buffer: %s\n", len, buffer);

		msleep(2 * 1000);
	}

release_sock:
	sock_release(sock);
	return err;
}

static int __init socket_client_init(void)
{
	task = kthread_run(socket_thread, NULL, "socket client thread");
	
	return 0;
}

static void __exit socket_client_exit(void)
{
	if (task) {
		// 如果没调用kthread_stop()，会发生panic
		// https://gitee.com/chenxiaosonggitee/tmp/blob/master/mptcp/kernel-socket-panic-log.txt
		kthread_stop(task);
		task = NULL;
	}
}

module_init(socket_client_init);
module_exit(socket_client_exit);
MODULE_LICENSE("GPL");


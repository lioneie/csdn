#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kthread.h>
#include <net/sock.h>
#include <linux/delay.h>

static int socket_thread(void *data)
{
	struct socket *sock;
	struct sockaddr_in server_addr;
	char buffer[1024];
	int err;
	int cnt;
	struct msghdr msg;
	struct kvec iov;
	
	err = sock_create_kern(&init_net, PF_INET, SOCK_STREAM, IPPROTO_TCP, &sock);
	if(err < 0) {
		printk("sock_create_kern fail, err: %d\n", err);
		return err;
	}
	
	memset(&server_addr, 0, sizeof(server_addr));
	server_addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
	server_addr.sin_port = htons(5555);
	server_addr.sin_family = AF_INET;

	err = kernel_connect(sock, (struct sockaddr *)&server_addr, sizeof(server_addr), 0);
	if (err < 0) {
		printk("kernel_connect fail, err: %d\n", err);
		goto release_sock;
	}

	msg.msg_name = &server_addr,
	msg.msg_namelen = sizeof(server_addr);
	cnt=0;
	while (!kthread_should_stop()) {
		cnt++;
		sprintf(buffer, "data %d", cnt);
		printk("kernel_sendmsg, buffer: %s\n", buffer);
		iov.iov_base = buffer;
		iov.iov_len = strlen(buffer);
		kernel_sendmsg(sock, &msg, &iov, 1, iov.iov_len);
		msleep(1 * 1000);
	}

release_sock:
	sock_release(sock);
	return err;
}

static int __init socket_client_init(void)
{
	struct task_struct *task;
	task = kthread_run(socket_thread, NULL, "socket client thread");
	
	return 0;
}

static void __exit socket_client_exit(void)
{
}

module_init(socket_client_init);
module_exit(socket_client_exit);
MODULE_LICENSE("GPL");


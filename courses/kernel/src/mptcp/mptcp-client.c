/*  Make the necessary includes and set up the variables.  */

#include <sys/types.h>
#include <sys/socket.h>
#include <stdio.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdlib.h>

int main()
{
	int sockfd;
	int len;
	struct sockaddr_in address;
	int result;
	char data = 0;

	/*  Create a socket for the client.  */

	sockfd = socket(AF_INET, SOCK_STREAM, IPPROTO_MPTCP);

	/*  Name the socket, as agreed with the server.  */

	address.sin_family = AF_INET;
	address.sin_addr.s_addr = inet_addr("192.168.53.37");
	address.sin_port = htons(9734);
	len = sizeof(address);

	/*  Now connect our socket to the server's socket.  */

	result = connect(sockfd, (struct sockaddr *)&address, len);

	if(result == -1) {
		perror("oops: client3");
		exit(1);
	}

	/*  We can now read/write via sockfd.  */
	while (1) {
		write(sockfd, &data, 1);
		result = read(sockfd, &data, 1);
		if (result) {
			printf("char from server = %d\n", data);
		}
	}
	close(sockfd);
	exit(0);
}

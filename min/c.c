
//to be added at Startup Applications

//Sample for UNIX domain socket

#include <unistd.h> // for close
#include <stdio.h> // for printf
#include <stdlib.h> // for exit

#include <netinet/in.h> //socket+INET

#include <stdbool.h>

// for print error message
#include <string.h>
#include <errno.h>

int main(int argc, char **argv)
{
	int server_sock = socket(AF_INET, SOCK_STREAM, 0);//AF_UNIX
	if (server_sock == -1)
	{
		printf("Error when opening server socket.\n");
		exit(1);
	}

	struct sockaddr_in address;
	address.sin_family = AF_INET;
	address.sin_addr.s_addr = INADDR_ANY;
	//Port defined Here:
	address.sin_port=htons(8000);

	int len = sizeof(address);

	int rc = bind(server_sock, (struct sockaddr *)&address, len);
	if (rc == -1)
	{
		printf("Server bind error: %s\n", strerror(errno));
		close(server_sock);
		exit(1);
	}

	rc = listen(server_sock, 1); // maximum number of client connections in queue
	if (rc == -1)
	{
		printf("Listen error: %s\n", strerror(errno));
		//unlink(SERVER_SOCK_PATH);
		close(server_sock);
		exit(1);
	}

	struct sockaddr_in client_addr;
	int client_fd;

	while(true){
		memset(&client_addr, 0, sizeof(client_addr));
		client_fd = accept(server_sock, (struct sockaddr *) &client_addr, (socklen_t*)&len);
		if (client_fd == -1)
		{
			printf("Accept error: %s\n", strerror(errno));
			close(client_fd);
			close(server_sock);
			exit(1);
		}
		char a;
		char re = recv(client_fd, &a, 1, 0);
		if (re != 1){
			if (re == -1)printf("Error when receiving message: %s\n", strerror(errno));
			close(client_fd);
			close(server_sock);
			exit(1);
		}
		close(client_fd);
		if(a!='a')break;
	}
	close(server_sock);

	return 0;
}

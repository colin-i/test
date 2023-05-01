
//to be added at Startup Applications

//Sample for UNIX domain socket

#include <unistd.h> // for close
#include <stdio.h> // for printf
#include <stdlib.h> // for exit

#include <netinet/in.h> //socket+INET

// for print error message
#include <string.h>
#include <errno.h>

//#include <libgen.h> //basename

#include "a.h"

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
	address.sin_port=htons(port);

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
		close(server_sock);
		exit(1);
	}

	struct sockaddr_in client_addr;
	int client_fd;
	memset(&client_addr, 0, sizeof(client_addr));

	while(1){
		client_fd = accept(server_sock, (struct sockaddr *) &client_addr, (socklen_t*)&len);
		if (client_fd == -1)
		{
			printf("Accept error: %s\n", strerror(errno));
			close(client_fd);
			close(server_sock);
			exit(1);
		}
		system("termux-notification -c 'not connected'");
		close(client_fd);
	}

	close(server_sock);

	return 0;
}

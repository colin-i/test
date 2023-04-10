

//Sample for UNIX domain socket

#include <unistd.h> // for close
#include <stdio.h> // for printf
#include <stdlib.h> // for exit
#include <sys/socket.h> // socket call constants and some functions
#include <sys/un.h> // socket in Unix (storage size of sockaddr_un)

// for print error message
#include <string.h>
#include <errno.h>

#include <stdbool.h> //true

#include <libgen.h> //basename

#include "a.h"

int main(int argc, char **argv)
{
	/****************************************************/
	/* Open the server socket with the SOCK_STREAM type */
	/****************************************************/
	int server_sock = socket(AF_UNIX, SOCK_STREAM, 0);
	if (server_sock == -1)
	{
		printf("Error when opening server socket.\n");
		exit(1);
	}

	char server_name[sizeof(SERVER_SOCK_PATH)+1];
	variable_name(argv[0],SERVER_SOCK_PATH,server_name);
	/*************************************/
	/* Bind to an address on file system */
	/*************************************/
	// similar to other IPC methods, domain socket needs to bind to a file system
	// so that client know the address of the server to connect to
	struct sockaddr_un server_addr;
	memset(&server_addr, 0, sizeof(server_addr));
	server_addr.sun_family = AF_UNIX;
	strcpy(server_addr.sun_path, server_name);
	int len = sizeof(server_addr);

	// unlink the file before bind, unless it can't bind
	//unlink(server_name);

	int rc = bind(server_sock, (struct sockaddr *)&server_addr, len);
	if (rc == -1)
	{
		printf("Server bind error: %s\n", strerror(errno));
		close(server_sock);
		exit(1);
	}

	//system("chmod o+w unix_sock.server");

	/***************************************/
	/* Listen and accept client connection */
	/***************************************/
	// set the server in the "listen" mode and maximum pending connected clients in queue
	rc = listen(server_sock, 1); // maximum number of client connections in queue
	if (rc == -1)
	{
		printf("Listen error: %s\n", strerror(errno));
		unlink(server_name);
		close(server_sock);
		exit(1);
	}

	/********************/
	/* Listen to client */
	/********************/
	struct sockaddr_un client_addr;
	int client_fd;
	// for simplicity, we will assign a fixed size for buffer of the message
	char buf[buf_size];
	char store[buf_size];
	unsigned char store_length;
	while(true){
		memset(&client_addr, 0, sizeof(client_addr));
		client_fd = accept(server_sock, (struct sockaddr *) &client_addr, (socklen_t*)&len);
		if (client_fd == -1)
		{
			printf("Accept error: %s\n", strerror(errno));
			close(client_fd);
			unlink(server_name);
			close(server_sock);
			exit(1);
		}

		//printf("Connected to client at: %s\n", client_addr.sun_path);

		int byte = recv(client_fd, buf, 1, 0);
		if (byte == -1)
		{
			printf("Error when receiving message: %s\n", strerror(errno));
			close(client_fd);
			unlink(server_name);
			close(server_sock);
			exit(1);
		}
		else{
			unsigned char incoming_size=buf[0];
			if(incoming_size==0){
				//send to client since there is the out point
				send(client_fd, store, store_length, 0);
				break;
			}else if(incoming_size > buf_size){
				printf("What are we doing here?\n");
				close(client_fd);
				unlink(server_name);
				close(server_sock);
				exit(1);
			}else{
				store_length = recv(client_fd, buf, incoming_size, 0);
				if (store_length != incoming_size){
					printf("Something is wrong!\n");
					close(client_fd);
					unlink(server_name);
					close(server_sock);
					exit(1);
				}
				memcpy(store,buf,store_length);
				close(client_fd);
			}
		}
	}

	close(client_fd);
	unlink(server_name);
	close(server_sock);

	return 0;
}

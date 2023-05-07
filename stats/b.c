
//Sample for UNIX domain socket

#include <unistd.h> // for close
#include <stdio.h> // for printf
#include <stdlib.h> // for exit
#include <sys/socket.h> // socket call constants and some functions
#include <sys/un.h> // socket in Unix (storage size of sockaddr_un)

// for print error message
#include <string.h>
#include <errno.h>

#include <libgen.h> //basename

#include "a.h"

#define CLIENT_SOCK_PATH "unix_sock.client"

int main(int argc, char **argv)
{
	if(argc>2){
		printf("This is not the correct usage.");
		exit(1);
	}
	unsigned char store_length;
	if(argc==2){
		store_length=strlen(argv[1]);
		if((store_length > buf_size)||(store_length == 0)){
			printf("Buffer size not ok.");
			exit(1);
		}
	}else store_length = 0;

	/**************************************************/
	/* Open a client socket (same type as the server) */
	/**************************************************/
	int client_sock = socket(AF_UNIX, SOCK_STREAM, 0);
	if (client_sock == -1)
	{
		printf("Socket error: %s\n", strerror(errno));
		exit(1);
	}

	char server_name[sizeof(SERVER_SOCK_PATH)+1];
	variable_name(argv[0],SERVER_SOCK_PATH,server_name);
	/****************************************/
	/* Set server address and connect to it */
	/****************************************/
	struct sockaddr_un server_addr;
	memset(&server_addr, 0, sizeof(server_addr));
	server_addr.sun_family = AF_UNIX;
	strcpy(server_addr.sun_path, server_name);
	int len = sizeof(server_addr);
	int rc = connect(client_sock, (struct sockaddr*)&server_addr, len);
	if(rc == -1)
	{
		printf("Connect error. %s\n", strerror(errno));
		close(client_sock);
		exit(1);
	}

	/**************************/
	/* Send messages to server */
	/**************************/
	char*send_err="Send error. %s\n";
	rc = send(client_sock, &store_length, 1, 0);
	if (rc == -1)
	{
		printf(send_err, strerror(errno));
		close(client_sock);
		exit(1);
	}
	if(store_length>0){
		rc = send(client_sock, argv[1], store_length, 0);
		if (rc == -1)
		{
			printf(send_err, strerror(errno));
			close(client_sock);
			exit(1);
		}
	}else{
		char client_name[sizeof(CLIENT_SOCK_PATH)+1];
		variable_name(argv[0],CLIENT_SOCK_PATH,client_name);
		/********************************************/
		/* Bind client to an address on file system */
		/********************************************/
		// Note: this binding could be skip if we want only send data to server without receiving
		struct sockaddr_un client_addr;
		memset(&client_addr, 0, sizeof(client_addr));
		client_addr.sun_family = AF_UNIX;
		strcpy(client_addr.sun_path, client_name);
		int len = sizeof(client_addr);
		rc = bind(client_sock, (struct sockaddr *)&client_addr, len);
		if (rc == -1)
		{
		    printf("Client binding error. %s\n", strerror(errno));
		    close(client_sock);
		    exit(1);
		}

		//get the response
		char buf[buf_size];
		rc = recv(client_sock, buf, buf_size, 0);
		if (rc == -1)
		{
			printf("Recv Error. %s\n", strerror(errno));
			unlink (client_name);
			close(client_sock);
			exit(1);
		}
		write(fileno(stdout),buf,rc);
		unlink (client_name);
	}

	close(client_sock);
	return 0;
}

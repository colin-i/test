
#include <netdb.h> //socket+INET+hostent
#include <unistd.h> //close
#include <errno.h>
#include <stdio.h>
#include <string.h>

#include "a.h"

void send_data(char*host,void*data,size_t len){
	int client_sock = socket(AF_INET, SOCK_STREAM, 0);
	if (client_sock == -1)
	{
		printf("Socket error: %s\n", strerror(errno));
		return;
	}

	struct sockaddr_in address;

	address.sin_family = AF_INET;
	struct hostent *hp;
	hp = gethostbyname(host);
	/*
	 * gethostbyname returns a structure including the network address
	 * of the specified host.
	 */
	if (hp == (struct hostent *) 0) {
		fprintf(stderr, "%s: unknown host\n", host);
		return;
	}
	memcpy((char *) &address.sin_addr, (char *) hp->h_addr,hp->h_length);
	address.sin_port = htons(port);

	int rc = connect(client_sock, (struct sockaddr*)&address, sizeof(address));
	if(rc == -1)
	{
		printf("Connect error. %s\n", strerror(errno));
		close(client_sock);
		return;
	}

	rc = send(client_sock, data, len, 0);
	if (rc == -1)
	{
		printf("Send error. %s\n", strerror(errno));
		close(client_sock);
		return;
	}

	close(client_sock);
}

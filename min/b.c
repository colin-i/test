
//waittime
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

int sum_time(unsigned short more){
	char path[10];
	FILE*fp=fopen("/home/bc/min_sum_time","r+");
	size_t shlen=fread(path,1,10,fp);
	path[shlen]='\0';
	int newtime=atoi(path)+more;

	shlen=sprintf(path,"%u",newtime);
	rewind(fp);//fgetpos has one cursor
	fwrite(path,shlen,1,fp);
	fclose(fp);

	return newtime;
}

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
		//unlink(SERVER_SOCK_PATH);
		close(server_sock);
		exit(1);
	}

	struct sockaddr_in client_addr;
	int client_fd;

	int n=sizeof(unsigned short);int max=n+1;
	memset(&client_addr, 0, sizeof(client_addr));
	while(1){
		client_fd = accept(server_sock, (struct sockaddr *) &client_addr, (socklen_t*)&len);
		if (client_fd == -1)
		{
			printf("Accept error: %s\n", strerror(errno));
			close(client_fd);
			//unlink(SERVER_SOCK_PATH);
			close(server_sock);
			exit(1);
		}

		unsigned int minutes;
		char re = recv(client_fd, &minutes, max, 0);
		if (re == -1){//anyone can send more than 3 bytes on the network
			printf("Error when receiving message: %s\n", strerror(errno));
			close(client_fd);
			//unlink(SERVER_SOCK_PATH);
			close(server_sock);
			exit(1);
		}
		close(client_fd);
		if(re == max){
			system("notify-send \"Not connected\"");
			continue;
		}

		int s=sum_time((unsigned short)minutes);
		#define for "notify-send \"Time\" \"%hu %hu\""
		char out[sizeof(for)-3-3+5+5+1];
		sprintf(out,for,minutes,s);
		system(out);
		#define max_per_month (30*60)+25 //this will be exact 365 hours per year
		if(s>max_per_month)system("notify-send \"Done\"");
		break;
	}
	//unlink(SERVER_SOCK_PATH);
	close(server_sock);

	return 0;
}

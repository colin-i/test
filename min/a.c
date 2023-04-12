
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <signal.h>

#include <time.h>
#include <netdb.h> //socket+INET+hostent
#include <unistd.h> //close
#include <errno.h>
#include "a.h"

void send_time(time_t start){
	int client_sock = socket(AF_INET, SOCK_STREAM, 0);
	if (client_sock == -1)
	{
		printf("Socket error: %s\n", strerror(errno));
		return;
	}

	struct sockaddr_in address;

	address.sin_family = AF_INET;
	char*host="192.168.1.11";
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

	time_t now=time(NULL);
	time_t dif=now-start;
	time_t minutes=dif/60;
	if(minutes>65535){printf("No\n");close(client_sock);return;}//16777215

	rc = send(client_sock, &minutes, 2, 0);
	if (rc == -1)
	{
		printf("Send error. %s\n", strerror(errno));
		close(client_sock);
		return;
	}

	close(client_sock);
}
static FILE*logfile=NULL;
void putlog(char*b){
	if(logfile!=NULL){
		fwrite(b,strlen(b),1,logfile);
		fflush(logfile);
	}
	puts(b);
}
void main(int argc,char**argv){
	sleep(1);//kill not working?from ps is the id and for permission a keyring?

	time_t start=time(NULL);
	//send_time(start);return;

	if(argv[1][0]=='1'){
		logfile=fopen("logfile","wb");
	}

	FILE *fp;
	char path[11];

	fp=fopen("shares","rb");
	size_t shlen=fread(path,10,1,fp);
	fclose(fp);
	path[shlen]='\0';
	putlog(path);
	putlog("\n");
	int shares=atoi(path);
	printf("\nShares needed: %d\n",shares);

	fp = popen("ps aux|grep etcminer|grep -v grep|tr -s ' '|cut -f2 -d' '", "r");
	if (fp == NULL) {
		printf("Failed to run command\n" );
		exit(1);
	}
	fgets(path, sizeof(path), fp);
	pclose(fp);
	putlog(path);
	

	pid_t id=atoi(path);
	//sprintf(msg,"sudo kill -2 %s",path);

	size_t n=1000;
	char*b=malloc(n);
	while(getline(&b,&n,stdin)!=-1){//first process must print with flushes
		putlog(b);
		char*p=strstr(b,"**Accepted");
		if(p!=NULL){
			shares--;
			if(shares==0){
				send_time(start);
				kill(id,2);
				//system("./keyring");//"Operation not permitted" without sudo , only at "screen"
				//system(msg);
			}
			printf("\nRemaining shares: %d\n",shares);//fflush(stdout);
		}
	}
	free(b);
	if(logfile!=NULL)fclose(logfile);
}

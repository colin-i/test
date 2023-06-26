
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <signal.h>

#include <time.h>
#include <netdb.h> //socket+INET+hostent
#include <unistd.h> //close
#include <errno.h>
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

FILE*logfile=NULL;
void putlog(char*b){
	if(logfile!=NULL){
		fwrite(b,strlen(b),1,logfile);
		fflush(logfile);
	}
	puts(b);
}

char path[11];
void stop(){
	FILE* fp = popen("ps aux|grep etcminer|grep -v grep|tr -s ' '|cut -f2 -d' '", "r");
	if (fp != NULL) {
		fgets(path, sizeof(path), fp);
		pclose(fp);
		putlog(path);
		pid_t id=atoi(path);
		//sprintf(msg,"sudo kill -2 %s",path);
		kill(id,2);
		//system("./keyring");//"Operation not permitted" without sudo , only at "screen"
		//system(msg);
	}
}

int mintime(time_t start){
	time_t now=time(NULL);
	time_t dif=now-start;
	return dif/60;
}

char*mintimefile="interval";
void interval_set(time_t start){
	int minutes=mintime(start);
	FILE*fp=fopen(mintimefile,"wb");
	sprintf(path,"%u",minutes);
	fwrite(path,strlen(path),1,fp);
	fclose(fp);
}
time_t interval_get(){
	time_t now=time(NULL);
	FILE*fp=fopen(mintimefile,"rb");
	size_t shlen=fread(path,1,10,fp);
	fclose(fp);
	path[shlen]='\0';
	int mintime=atoi(path);
	printf("\npast time: %u\n",mintime);
	now=now-(60*mintime);
	return now;
}

int send_time(time_t start){
	time_t minutes=mintime(start);

	if(minutes<60){
		printf("At least one hour");
		return 1;
	}

	if(minutes>65535)printf("No\n");//16777215
	else send_data("192.168.1.11",&minutes,2);
	return 0;
}

void main(int argc,char**argv){
	time_t start=interval_get();
	//send_time(start);return;

	if(argv[1][0]=='1'){
		logfile=fopen("logfile","wb");
	}

	FILE *fp;

	fp=fopen("sharesleft","rb");
	size_t shlen=fread(path,1,10,fp);//10,1? will return 0
	fclose(fp);
	path[shlen]='\0';
	putlog(path);
	int shares=atoi(path);
	printf("\nShares needed: %d\n",shares);

	//int startshares=shares;
	size_t n=1000;
	char*b=malloc(n);
	while(getline(&b,&n,stdin)!=-1){//first process must print with flushes
		putlog(b);
		if(strstr(b,"**Accepted")!=NULL){
			shares--;
			if(shares==0){
				shares=send_time(start);
				if(shares==0){
					//still can be dust
					int dust=system("./a");
					if(dust==0)stop();//1 return is 0x100
					else shares=1;
				}
			}
			printf("\nRemaining shares: %d\n",shares);//fflush(stdout);
			//in case of problems
			fp=fopen("sharesleft","wb");
			sprintf(path,"%u",shares);
			fwrite(path,strlen(path),1,fp);
			fclose(fp);
		}else if(strstr(b,"not-connected")!=NULL){
			int nothing;
			send_data("192.168.1.11",&nothing,3);
			send_data("192.168.1.8",NULL,0);
			send_data("192.168.1.14",NULL,0);
			if(access("problem",F_OK)==0){
				interval_set(start);
				stop();
			}
		}else if(access("problem",F_OK)==0){//it is working but want to exit
			//remove problem if not wanting to change something and restart
			interval_set(start);
			stop();
		}else if(strstr(b,"difficulty")!=NULL){
			fp=fopen("difficulty","wb");
			fwrite(b,strlen(b),1,fp);
			fclose(fp);
		}
	}
	free(b);
	if(logfile!=NULL)fclose(logfile);
}

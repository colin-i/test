
#include <stdlib.h>
#include <signal.h>

#include <time.h>

#include "d.h"

FILE*logfile=NULL;//cc a.c && stat -c %y a.out
char path[11];
char*mintimefile="interval";
int before_time=1;
char*main_ip="192.168.1.11";

void putlog(char*b){
	if(logfile!=NULL){
		fwrite(b,strlen(b),1,logfile);
		fflush(logfile);
		if(access("logflag",F_OK)!=0){
			fclose(logfile);
			logfile=NULL;
		}
	}
	puts(b);
}

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

int send_the_time(time_t start){
	time_t minutes=mintime(start);
	if(minutes>65535)printf("No\n");//16777215
	else send_data(main_ip,&minutes,2);
	return 0;
}
int send_time(time_t start){
	if(before_time||system("./a")!=0){
		printf("\nat least one hour and wallet balance\n");
		return 1;
	}
	return send_the_time(start);
}

void logfileinit(){
	logfile=fopen("logfile","wb");
}

void main(int argc,char**argv){
	time_t start=interval_get();

	if(argv[1][0]=='1')logfileinit();

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
	time_t pooltime;
	int lastmins;
	while(getline(&b,&n,stdin)!=-1){//first process must print with flushes
		putlog(b);
		if(strstr(b,"**Accepted")!=NULL){
			shares--;
			if(shares==0){
				shares=send_time(start);
				if(shares==0)stop();
			}
			printf("\nRemaining shares: %d\n",shares);//fflush(stdout);
			//in case of problems
			fp=fopen("sharesleft","wb");
			sprintf(path,"%u",shares);
			fwrite(path,strlen(path),1,fp);
			fclose(fp);
		}else if(strstr(b,"not-connected")!=NULL){
			int nothing;
			send_data(main_ip,&nothing,3);

			char *lineptr=NULL;
			size_t n;//this is not strlen or streln+1, is allocated size
			FILE*fp=fopen("problems","rb");
			while(getline(&lineptr,&n,fp)!=-1){
				n=strlen(lineptr);
				if(lineptr[n-1]=='\n')lineptr[n-1]='\0';
				send_data(lineptr,NULL,0);
			}
			free(lineptr);
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
		}else if(shares==1){//to not wait for last share if there is no dust and shares seem ok
			if(before_time){
				before_time=mintime(start)<60;
				if(before_time==0){
					pooltime=time(NULL);lastmins=0;
				}
			}else{
				int mins=mintime(pooltime);
				if(lastmins!=mins){
					lastmins=mins;
					printf("\nanother minute, %d\n",mins);
					if(mins>9){
						shares=WEXITSTATUS(system("./a"));//1 return is 0x100
						if(shares==0){
							send_the_time(start);
							stop();
						}else{
							pooltime=time(NULL);lastmins=0;
							printf("\npool is not finding blocks\n");
							if(access("logflag",F_OK)==0)if(logfile==NULL)logfileinit();
						}
					}
				}
			}
		}
	}
	free(b);
	if(logfile!=NULL)fclose(logfile);
}

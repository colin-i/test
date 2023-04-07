
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void main(){//int argc,char**argv){
	FILE *fp;
	char path[10];

	fp=fopen("shares","rb");
	fread(path,10,1,fp);
	fclose(fp);
	int shares=atoi(path);
	printf("\nShares needed: %d\n",shares);

	fp = popen("ps aux|grep etcminer|grep -v grep|tr -s ' '|cut -f2 -d' '", "r");
	if (fp == NULL) {
		printf("Failed to run command\n" );
		exit(1);
	}
	fgets(path, sizeof(path), fp);
	pclose(fp);

	puts(path);
	char msg[100];
	sprintf(msg,"sudo kill -2 %s",path);
	puts(msg);

	size_t n=1000;
	char*b=malloc(n);
	while(getline(&b,&n,stdin)!=-1){//first process must print with flushes
		puts(b);//fflush(stdout);
		//puts("\ntest\n");
		char*p=strstr(b,"**Accepted");
		if(p!=NULL){
			shares--;
			if(shares==0){
				system("./keyring");//"Operation not permitted" without sudo , only at "screen"
				system(msg);
			}
			printf("\nRemaining shares: %d\n",shares);//fflush(stdout);
		}
	}
}

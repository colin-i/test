
#define SERVER_SOCK_PATH "unix_sock.server"

#define buf_size 10

//this was later added to store a maximum of 10 variables
static char*variable_name(char*name,char*in,char*out){
	char*n=basename(name);
	char extra[2];
	if(n[1]=='.')extra[0]='\0';
	else sprintf(extra,"%c",n[1]);//else n[1]=0-9
	sprintf(out,"%s%s",in,extra);
}

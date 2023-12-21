
#include <unistd.h>
#include <stdlib.h>

void main(){
	//sleep(30);//modem net is off at start. need to sleep. //sleep 30 and ~/arh/activity &  at the already plug script
	chdir("/home/bc/test");
	int a;
	do{
		a=system("PYTHONPYCACHEPREFIX=/home/bc/pycache python -m act");
		//a=WIFEXITED(a); WIFEXITED(0) is 1 WIFEXITED(256) is 1
	}while(a);
}

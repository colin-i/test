
#include <unistd.h>
#include <stdlib.h>

void main(){
	//sleep(30);//modem net is off at start. need to sleep. //sleep 30 and ~/arh/activity &  at the already plug script
	chdir("/home/bc/test");
	int a;
	do{
		a=system("PYTHONPYCACHEPREFIX=/home/bc/pycache python -m act");
		if(WIFEXITED(a))if(WEXITSTATUS(a)==1)continue;
		break;
	}while(1);
}

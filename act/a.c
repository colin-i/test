
#include <unistd.h>
#include <stdlib.h>

void main(){
	//sleep(30);//can't start gtk app without sleep //move it at the already plug script: ~/arh/activity &
	chdir("/home/bc/test");
	system("PYTHONPYCACHEPREFIX=/home/bc/pycache python -m act");
}

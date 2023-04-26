
#include <unistd.h>
#include <stdlib.h>

void main(){
	chdir("/home/bc/test");
	system("PYTHONPYCACHEPREFIX=/home/bc/pycache python -m act");
}


//send_time
#include "d.h"

void main(int argc,char**argv){
	unsigned short mins;
	sscanf(argv[1],"%hu",&mins);
	send_data("192.168.1.11",&mins,2);
}

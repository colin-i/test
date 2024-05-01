

import sys
import os
from multiprocessing.connection import Client

with open(os.path.expanduser('~')+"/load_ip","rb") as f:
	address = (f.read(), 6000)
try:
	conn = Client(address)
except:
	exit(1) #after send the next one comes in the set number of seconds, is exit !=0 at except but it is documented?
conn.send(sys.argv[1])
conn.close()
exit(0)

#echo 123 > /dev/tcp/192.168.1.11/6000  #will connect, but need "123" there

#/* test for multiple cpu-s
##include <stdio.h>
##include <pthread.h>
##include <unistd.h>
#void* func1(void*) { while (1) { //sleep(2);
#  }}
#void* func2(void*) { while (1) { //sleep(2);
#  }}
#int main(){ pthread_t thread_id; pthread_t thread_id2;
#  pthread_create(&thread_id, NULL, func1, NULL); pthread_create(&thread_id2, NULL, func2, NULL);
#  sleep(8); printf("done\n"); return 0;}*/

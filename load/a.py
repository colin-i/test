

from multiprocessing.connection import Client
import sys

address = ('192.168.1.15', 6000)
conn = Client(address)
conn.send(sys.argv[1])
conn.close()

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
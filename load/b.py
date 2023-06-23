
class bcolors:
    red = '\033[101m'
    green = '\033[102m'
    yellow = '\033[103m'
    end = '\033[0m'
    bold = '\033[1m'
    underline = '\033[4m'
#print(f"{bcolors.bold}{bcolors.underline}{bcolors.red}1{bcolors.green}2{bcolors.yellow}3{bcolors.end}123")
#print(f"{bcolors.bold}{bcolors.underline}{bcolors.red}1{bcolors.green}2{bcolors.yellow}3")
#print("123")
print(f"{bcolors.bold}{bcolors.underline}{bcolors.red} {bcolors.green} {bcolors.yellow} {bcolors.end}")

import os
print(os.get_terminal_size().columns)


from multiprocessing.connection import Listener

address = ('192.168.1.11', 6000)     # family is deduced to be 'AF_INET'
listener = Listener(address)

conn = listener.accept()
print('connection accepted from', listener.last_accepted)
print(conn.recv())
conn.close()

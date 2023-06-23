
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
cols=os.get_terminal_size().columns


import sys
a=float(sys.argv[1])
b=100-a
c=float(sys.argv[2])/100
d=b*c
e=a+d
e*=100
import math
e=math.floor(e)
e/=100
print(str(e))

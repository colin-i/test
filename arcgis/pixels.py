
#import numpy
from PIL import Image

image = Image.open("a.jpg", "r")
width, height = image.size
values = list(image.getdata())
#channels = 3  # image.mode == "RGB"
#values = numpy.array(values).reshape((width, height, channels))

for y in range(0,height):
	for x in range(0,width):
		a=values[width*y+x]
		print(" %02x/%02x/%02x" % (a[0],a[1],a[2]),end='') #values[x][y][0]
	print()

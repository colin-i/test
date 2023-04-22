
from . import points
from . import play
from . import draw
from . import save
from . import sets

def init():
	global button
	button=sets.colorButton(chr(0x1F3D7),create,"Build")
	return button

def create(b,d):
	f=play.entry.get_text()
	#read points and build info
	info=points.read(f)
	if info:
		sampwidth,channels,rate,draw.length=info
		play.open(sampwidth,channels,rate)
		#samples
		draw.samples=[0] * draw.length # [0 for i in range(draw.length)]
		save.apply()
		#for playback
		play.save_file(f,sampwidth,channels,rate)
		play.waveopen(f)

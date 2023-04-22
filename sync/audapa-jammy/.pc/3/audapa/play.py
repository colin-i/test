
import pyaudio
import wave

from gi.repository import GLib

from . import sets
from . import draw
from . import seloff
from . import points
from . import build
from . import forms
from . import drawscroll

wavefile=None
output=0x25B6
#23F5
timer=0

def activate(en,d):
	terminate()
	launch()
def toggle(b,d):
	if not wavefile:
		launch()
		start()
		return
	if stream.is_stopped():
		start()
	else:
		pause()

def init():
	global entry,button
	entry=sets.colorEntry()
	button=sets.colorButton(chr(output), toggle, "Play")
	entry.connect('activate',activate,None)

def callback(in_data, frame_count, time_info, status):
	data = wavefile.readframes(frame_count)
	return (data, pyaudio.paContinue)
def wave_open(f):
	global wavefile
	wavefile=wave.open(f,'rb')
def waveopen(f):
	wave_open(f)
	build.button.set_sensitive(False)

def launch():
	f=entry.get_text()
	waveopen(f)
	sampwidth=wavefile.getsampwidth()
	rate = wavefile.getframerate()
	channels = wavefile.getnchannels()
	draw.length=wavefile.getnframes()
	data = wavefile.readframes(draw.length)
	wavefile.rewind()#for playing
	#pyaudio/draw/bar
	open(sampwidth,channels,rate)
	#points
	points.read(f)
	#samples from file
	draw.get_samples(sampwidth,channels,data)
	#only if size is less than the screen
	forms.drawpoints(drawscroll.win.get_width(),drawscroll.win.get_height())
def open(sampwidth,channels,rate):
	global audio,stream
	# create pyaudio stream
	audio = pyaudio.PyAudio() # create pyaudio instantiation
	stream = audio.open(format=audio.get_format_from_width(sampwidth),rate=rate,channels=channels,
		output = True,start=False,stream_callback=callback)
	#open
	draw.open(sampwidth,channels)
	seloff.open()
def start():
	stream.start_stream()
	button._set_text_(chr(0x23F8))
	global timer
	timer=GLib.timeout_add_seconds(1,is_act,None)
def pausing():
	stream.stop_stream()
	button._set_text_(chr(output))
def pause():
	pausing()
	global timer
	if timer:
		GLib.source_remove(timer)
		timer=0
def stop():
	# stop the stream, close it, terminate the pyaudio instantiation
	pause()
	stream.close()
	audio.terminate()
	# close the file
	global wavefile
	wavefile.close()
	wavefile=None
	build.button.set_sensitive(True)
def terminate():
	if wavefile:
		seloff.stop.emit(sets._click_)

def is_act(d):
	if not stream.is_active():
		pausing()
		global timer
		timer=0
		wavefile.rewind()
		return False
	return True

formats={pyaudio.paInt16:'h',pyaudio.paUInt8:'B',pyaudio.paInt8:'b',
	pyaudio.paFloat32:'f',pyaudio.paInt32:'i'}
def scan(sampwidth,channels):
	fm=scan_format(sampwidth,channels)
	return '<'+fm*channels
def scan_format(sampwidth,channels):
	return formats[audio.get_format_from_width(sampwidth)]

def save_file(f_in,s,c,r):
	with wave.open(f_in,'wb') as file:
		file.setsampwidth(s)
		file.setnchannels(c)
		file.setframerate(r)
		#.setparams((1, 4, Fs, 0, 'NONE', 'not compressed'))
		sc=scan(s,c)
		b=b"".join((wave.struct.pack(sc,i) for i in draw.samples))
		file.writeframes(b)#this is setting nframes, oposite of writeframesraw
def save_opened(f_in):
	save_file(f_in,wavefile.getsampwidth(),wavefile.getnchannels(),wavefile.getframerate())
def save(b,d):
	f_in=entry.get_text()
	save_opened(f_in)
	points.write(f_in)
def saveshort(b,d):
	points.write(entry.get_text())

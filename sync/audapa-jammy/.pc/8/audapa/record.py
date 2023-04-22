import pyaudio
import wave

from time import time

from . import sets

wavefile=None

def callback(in_data, frame_count, time_info, status):
	wavefile.writeframes(in_data)
	return (None, pyaudio.paContinue)

def start(b,ready):
	global audio,stream,wavefile
	if not wavefile:
		audio = pyaudio.PyAudio() # create pyaudio instantiation
		chans=1
		bits=pyaudio.paInt16 # 16-bit resolution
		rate=16000 # 16kHz sampling rate
		# create pyaudio stream
		stream = audio.open(format = bits,rate = rate,channels = chans,
			input = True,
			frames_per_buffer=rate, # one second of samples
			stream_callback=callback)
		w=sets.get_data_file(str(int(time()))+".wav")
		wavefile = wave.open(w,'wb')
		wavefile.setnchannels(chans)
		wavefile.setsampwidth(audio.get_sample_size(bits))
		wavefile.setframerate(rate)
		#visual
		b._set_text_(chr(0x23F9))
		return
	stop()
	b._set_text_(chr(ready))
def stop():
	# stop the stream, close it, terminate the pyaudio instantiation
	stream.stop_stream()
	stream.close()
	audio.terminate()
	# close the file
	global wavefile
	wavefile.close()
	wavefile=None
def terminate():
	if wavefile:
		stop()
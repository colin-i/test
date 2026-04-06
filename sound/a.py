import sounddevice as sd
import numpy as np
import atexit

# Configuration
samplerate = 44100  # Hz
channels = 1         # mono
dtype = 'int16'      # 16-bit PCM

# Buffer to store audio chunks
audio_chunks = []

def callback(indata, frames, time, status):
    if status:
        print("Status:", status)
    # Append a copy of the data to the buffer
    audio_chunks.append(indata.copy())

# Function to save buffer to raw PCM file at exit
def save_audio():
    if audio_chunks:
        audio_data = np.concatenate(audio_chunks)
        audio_data.tofile("output.pcm")
        print(f"Saved {len(audio_data)} samples to output.pcm")

atexit.register(save_audio)

# Start the input stream
with sd.InputStream(samplerate=samplerate, channels=channels, dtype=dtype, callback=callback):
    print("Recording... Press Ctrl+C to stop")
    try:
        while True:
            sd.sleep(1000)  # keep thread alive
    except KeyboardInterrupt:
        print("Stopping...")

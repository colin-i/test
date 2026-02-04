
# python3-torch python3-pyperclip git-lfs wl-clipboard # python3-torchaudio python3-protobuf
# transformers
# git lfs install

# git clone https://huggingface.co/anton-l/wav2vec2-large-xlsr-53-romanian (clone from a system with ram, 8 gb is ok) # heavy
# https://huggingface.co/gigant/romanian-wav2vec2 # balanced
# https://huggingface.co/racai/wav2vec2-base-100k-voxpopuli-romanian # fast
import sys
sys.stdout.reconfigure(encoding='utf-8') # for romanian

import sounddevice as sd
import torch
import pyperclip
from scipy.signal import resample_poly
import os
import json
import queue
import numpy as np
import readchar

# LOCAL PATH
MODEL_PATH=os.environ.get("MODEL_PATH")
if MODEL_PATH==None:
	#MODEL_PATH = "/home/bc/a/models/wav2vec2-large-xlsr-53-romanian"
	#MODEL_PATH = "/home/bc/a/models/romanian-wav2vec2"
	MODEL_PATH = "/home/bc/a/models/wav2vec2-base-100k-voxpopuli-romanian"

#from transformers import Wav2Vec2Processor
#processor = Wav2Vec2Processor.from_pretrained(MODEL_PATH)  # MODEL_NAME = "facebook/wav2vec2-xls-r-300m" # error here
#                                                           # and problems at gigant

def sanitize_tokenizer_config(model_path):
    cfg_path = os.path.join(model_path, "tokenizer_config.json")
    if not os.path.exists(cfg_path):
        return
    with open(cfg_path, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    # Force valid type
    cfg["extra_special_tokens"] = []
    cfg["additional_special_tokens"] = []
    with open(cfg_path, "w", encoding="utf-8") as f:
        json.dump(cfg, f, ensure_ascii=False, indent=2)
sanitize_tokenizer_config(MODEL_PATH)
from transformers import Wav2Vec2CTCTokenizer, Wav2Vec2FeatureExtractor, Wav2Vec2Processor
tokenizer = Wav2Vec2CTCTokenizer.from_pretrained(MODEL_PATH)
feature_extractor = Wav2Vec2FeatureExtractor.from_pretrained(MODEL_PATH)
processor = Wav2Vec2Processor(feature_extractor=feature_extractor, tokenizer=tokenizer)

from transformers import Wav2Vec2ForCTC
model = Wav2Vec2ForCTC.from_pretrained(MODEL_PATH)
model.eval()

DEVICE_SAMPLE_RATE = int(sd.query_devices(sd.default.device[0])['default_samplerate'])
MODEL_SAMPLE_RATE = 16000

audio_queue = queue.Queue()

def callback(indata, frames, time, status):
    if status:
        print(status, file=sys.stderr)
    audio_queue.put(indata.copy())

def record_audio_until_space():
    print("Recording... press a key to stop")

    audio_frames = []

    with sd.InputStream(
        samplerate=DEVICE_SAMPLE_RATE,
        channels=1,
        dtype='float32',
        callback=callback
    ):
        readchar.readchar()
        print("Stopped")

        # DRAIN QUEUE PROPERLY
        while not audio_queue.empty():
            audio_frames.append(audio_queue.get())

    if len(audio_frames) == 0:
        return np.array([], dtype=np.float32)

    audio = np.concatenate(audio_frames, axis=0).flatten()

    # Resample to 16k
    if DEVICE_SAMPLE_RATE != MODEL_SAMPLE_RATE:
        audio = resample_poly(audio, MODEL_SAMPLE_RATE, DEVICE_SAMPLE_RATE)

    return audio

pyperclip.set_clipboard("wl-clipboard")

while True:
    print("\n q = exit | key to start recording")

    key = readchar.readchar()

    if key == "q":
        break

    audio_data = record_audio_until_space()

    if audio_data.shape[0] < 1600:   # 0.1 sec @ 16kHz
        print("Audio too short, skipping")
        continue

    with torch.no_grad():
        inputs = processor(audio_data, sampling_rate=MODEL_SAMPLE_RATE, return_tensors="pt", padding=True)
        logits = model(inputs.input_values).logits
        predicted_ids = torch.argmax(logits, dim=-1)
        text = processor.decode(predicted_ids[0])

    if text:
        pyperclip.copy(text)
        print(f"{text}")
        print("Copied to clipboard.")
    else:
        print("No speech detected")

# sudo apt install python3-pip portaudio19-dev python3-pyaudio
# pip3 install vosk sounddevice
# SAMPLE_RATE = 48000
# BLOCKSIZE = 12000
# wget https://alphacephei.com/vosk/models # no romanian

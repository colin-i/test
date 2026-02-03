
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

# LOCAL PATH
MODEL_PATH=os.environ.get("MODEL_PATH")
if MODEL_PATH==None:
	#MODEL_PATH = "/home/bc/a/models/wav2vec2-large-xlsr-53-romanian"
	#MODEL_PATH = "/home/bc/a/models/romanian-wav2vec2"
	MODEL_PATH = "/home/bc/a/models/wav2vec2-base-100k-voxpopuli-romanian"
RECORD_SECONDS = os.environ.get("RECORD_SECONDS")
if RECORD_SECONDS==None:
	RECORD_SECONDS=5
	print(f"Recording time set to {RECORD_SECONDS} seconds")

#from transformers import Wav2Vec2Processor
#processor = Wav2Vec2Processor.from_pretrained(MODEL_PATH)  # MODEL_NAME = "facebook/wav2vec2-xls-r-300m" # error here
#                                                           # and problems at gigant

import json
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

def record_audio():
    print("Speak now...")
    audio = sd.rec(
        int(RECORD_SECONDS * DEVICE_SAMPLE_RATE),
        samplerate=DEVICE_SAMPLE_RATE,
        channels=1,
        dtype='float32'
    )
    sd.wait()
    print("done")
    audio = audio.flatten()
    # Resample to 16k for wav2vec2
    if DEVICE_SAMPLE_RATE != MODEL_SAMPLE_RATE:
        audio = resample_poly(audio, MODEL_SAMPLE_RATE, DEVICE_SAMPLE_RATE)
    return audio

pyperclip.set_clipboard("wl-clipboard")

import readchar

while True:
    print("\n SPACE = change recording time | q = exit | talk")

    key = readchar.readchar()

    if key == "q":
        break

    # SPACE pressed   change recording time
    if key == " ":
        try:
            new_time = input("New recording time (seconds): ")
            new_time = float(new_time)
            if new_time <= 0:
                raise ValueError
            RECORD_SECONDS = new_time
            print(f"Recording time set to {RECORD_SECONDS} seconds")
        except:
            print("Invalid number. Keeping previous value:", RECORD_SECONDS)
        continue

    # ENTER pressed   record
    audio_data = record_audio()

    with torch.no_grad():
        inputs = processor(audio_data, sampling_rate=MODEL_SAMPLE_RATE, return_tensors="pt", padding=True)
        logits = model(inputs.input_values).logits
        predicted_ids = torch.argmax(logits, dim=-1)
        text = processor.decode(predicted_ids[0])

    if text:
        pyperclip.copy(text)
        print(f"{text}")
        print("Copied to clipboard. Paste into Twitch chat (Ctrl+V + Enter)")
    else:
        print("No speech detected")

# sudo apt install python3-pip portaudio19-dev python3-pyaudio
# pip3 install vosk sounddevice
# SAMPLE_RATE = 48000
# BLOCKSIZE = 12000
# wget https://alphacephei.com/vosk/models # no romanian

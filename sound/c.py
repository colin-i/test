#!/usr/bin/env python3

import sys
import subprocess
import numpy as np

# --- CONFIG ---
samplerate = 44100  # Hz
channels = 1        # mono
dtype = 'int16'     # 16-bit PCM

# --- READ ARGS ---
if len(sys.argv) != 3:
    print(f"Usage: {sys.argv[0]} <input_basename> <sample_indices_comma_separated>")
    sys.exit(1)

base_name = sys.argv[1]            # e.g., "input"
input_file = base_name + ".pcm"    # automatically add .pcm
sample_indices_str = sys.argv[2]   # e.g., "12345,23445,32134"
sample_indices = np.array([int(x) for x in sample_indices_str.split(",")])

# --- CONVERT TO SECONDS ---
segment_times = sample_indices / samplerate
segment_times_str = ",".join(map(str, segment_times))

# --- BUILD OUTPUT FILENAME TEMPLATE ---
output_template = f"{base_name}%02d.wav"

# --- VERBOSE INDICES AND ECHO ---
num_segments = len(sample_indices) + 1  # segments = indices + 1
print("Verbose sample indices and ranges:")
for i in range(num_segments):
    start = 0 if i == 0 else sample_indices[i - 1]
    end = sample_indices[i] if i < len(sample_indices) else "EOF"
    print(f"Segment {i:02d}: {start} → {end}")

# --- RUN FFMPEG ---
cmd = [
    "ffmpeg",
    "-f", "s16le",
    "-ar", str(samplerate),
    "-ac", str(channels),
    "-i", input_file,
    "-f", "segment",
    "-segment_times", segment_times_str,
    "-c", "copy",
    output_template
]

print("\nRunning command:")
print(" ".join(cmd))
subprocess.run(cmd, check=True)
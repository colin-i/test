#!/usr/bin/env python3

import sys
import numpy as np
import wave

# --- CONFIG ---
samplerate = 44100  # Hz
channels = 1        # mono
dtype = np.int16    # 16-bit PCM

# --- READ ARGS ---
if len(sys.argv) not in (3, 4):
    print(f"Usage: {sys.argv[0]} <input_basename> <sample_indices_comma_separated> [offset_seconds]")
    sys.exit(1)

# --- READ ARGS ---
if len(sys.argv) not in (3, 4):
    print(f"Usage: {sys.argv[0]} <input_basename> <sample_indices_comma_separated> [offset_seconds]")
    sys.exit(1)

base_name = sys.argv[1]
input_file = base_name + ".pcm"
sample_indices_input = sys.argv[2]
sample_indices = np.array([int(x) for x in sample_indices_input.split(",")])

# --- OPTIONAL OFFSET (seconds → samples) ---
offset_seconds = float(sys.argv[3]) if len(sys.argv) == 4 else 0.0
offset_samples = int(offset_seconds * samplerate)

# --- PRINT INPUT ARGUMENTS ---
print("Input arguments:")
print(f"  base_name        : {base_name}")
print(f"  input_file       : {input_file}")
print(f"  sample_indices   : {sample_indices_input}")
print(f"  offset_seconds   : {offset_seconds}")
print(f"  offset_samples   : {offset_samples}")
print()

# --- APPLY OFFSET TO INDICES ---
sample_indices = sample_indices + offset_samples
sample_indices = np.clip(sample_indices, 0, None)  # avoid negatives

# --- LOAD PCM DATA ---
audio = np.fromfile(input_file, dtype=dtype)

# --- CONVERT TO TIMES (for verbose only) ---
segment_times = sample_indices / samplerate

# --- SPLIT ---
num_segments = len(sample_indices) + 1

print("Verbose sample indices and ranges (with time):")
segments = []

for i in range(num_segments):
    start_idx = 0 if i == 0 else sample_indices[i - 1]
    end_idx = sample_indices[i] if i < len(sample_indices) else len(audio)

    start_time = start_idx / samplerate
    end_time = end_idx / samplerate # if end_idx is not None else None

    print(
        f"Segment {i:02d}: "
        f"{start_idx} → {end_idx if i < len(sample_indices) else 'EOF'} | "
        f"{start_time:.6f}s → {end_time:.6f}s"
    )

    segments.append(audio[start_idx:end_idx])

# --- WRITE WAV FILES ---
for i, segment in enumerate(segments):
    output_file = f"{base_name}{i:02d}.wav"

    with wave.open(output_file, 'wb') as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(2)  # int16 = 2 bytes
        wf.setframerate(samplerate)
        wf.writeframes(segment.tobytes())

print("\nDone.")

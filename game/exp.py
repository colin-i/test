import json
import os
import subprocess
import sys

def run_scene(scene, cfg, input_file, output_dir):
	cmd = [
		"python",
		os.path.join(os.environ["HOME"],"test/game/expo.py"),
		input_file,
		f"{output_dir}/{scene}.png",
		"--layers"
	]

	for l in cfg["layers"]:
		cmd.append(l)

	for k, v in cfg.get("offsets", {}).items():
		cmd += ["--offset", f"{k}:{v}"]

	if cfg.get("flatten"):
		cmd.append("--flatten")

	print("RUN:", " ".join(cmd))
	subprocess.run(cmd)

def main():
	json_file = sys.argv[1]
	input_ora = sys.argv[2]
	output_dir = sys.argv[3]

	with open(json_file) as f:
		all_data = json.load(f)

	if len(sys.argv) > 4:
		data = {}
		for name in sys.argv[4:]:
			if name not in all_data:
				print("ERROR: scene not found:", name)
				sys.exit(1)
			data[name] = all_data[name]
	else:
		data = all_data

	def resolve(name):
		if "base" not in all_data[name]:
			return all_data[name]

		base = resolve(all_data[name]["base"])

		merged = {
			"layers": list(base.get("layers", [])),
			"offsets": dict(base.get("offsets", {})),
			"flatten": base.get("flatten", False)
		}

		cur = all_data[name]
		minus = cur.get("layers_minus", [])
		replacements = cur.get("layers_replace", {})
		#plus = cur.get("layers_plus", [])
		merged_layers = merged["layers"]

		# remove first
		merged_layers = [l for l in merged_layers if l not in minus]

		# replace
		for old, new in replacements.items():
			if old in merged_layers:
				i = merged_layers.index(old)
				merged_layers[i] = new
			else:
				print("ERROR: layer not found for replace:", old)
				sys.exit(1)

		# append
		#for l in plus:
		#	if l not in merged_layers:
		#		merged_layers.append(l)

		merged["layers"] = merged_layers

		if "offsets" in cur:
			for k, v in cur["offsets"].items():
				k = int(k)
				for l in v:
					merged["offsets"][l] = merged["offsets"].get(l, 0) + k

		if "flatten" in cur:
			merged["flatten"] = cur["flatten"]

		return merged

	for name in data.keys():
		cfg = resolve(name)
		run_scene(name, cfg, input_ora, output_dir)

if __name__ == "__main__":
	main()

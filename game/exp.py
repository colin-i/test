
import copy
import json
import os
import subprocess
import sys

def run_scene(scene, cfg, input_file, output_dir):
	out_file=f"{output_dir}/{scene}.png"
	cmd = [
		launcher,
		os.path.join(os.environ["HOME"],"test/game/expo.py"),
		input_file,
		out_file,
		"--layers"
	]

	if "layers_reuse" in cfg:
		for l in cfg["layers_reuse"]:
			cmd.append(l)
	for l in cfg["layers"]:
		cmd.append(l)

	for k, v in cfg.get("offsets", {}).items():
		cmd += ["--offset", f"{k}:{v}"]

	if "act" in cfg:
		act = resolve_act_constants(cfg["act"])
		cmd += ["--act", json.dumps(act)]

	if cfg.get("flatten"):
		cmd.append("--flatten")

	print("RUN:", " ".join(cmd))
	if subprocess.run(cmd).returncode:
		sys.exit(1)

	if img_viewer:
		subprocess.run([img_viewer,out_file])

def resolve_constant(val):
	neg = val.startswith("-")
	name = val[1:] if neg else val

	if name in constants:
		num = constants[name]
		return -num if neg else num
	else:
		print("ERROR: constant not found: ", name)
		sys.exit(1)

def resolve_act_constants(act):
	for k, v in act.items():
		for lst in v:
			for i in range(1, len(lst)):
				val = lst[i]
				if isinstance(val, str):
					lst[i] = resolve_constant(val)
				else:
					lst[i] = val
	return act

def offsets_set(offs,merged):
	for k, v in offs.items():
		try:
			k = int(k)
		except:
			k = resolve_constant(k)
		for l in v:
			merged["offsets"][l] = merged["offsets"].get(l, 0) + k

def resolve(name):
	cur = all_data[name]

	if "base" not in cur:
		if "layers_copy" in cur:
			base=all_data[cur["layers_copy"]]
			ext=base["layers_reuse"]
			cur["layers"].extend(ext)
			del cur["layers_copy"]
			if "act_copy" in cur:
				if not "act" in cur:
					cur["act"]={}
				for k,v in base["act"].items():
					if k in cur["act_copy"]:
						cur["act"].update({k:v})
						cur["act_copy"].remove(k)
				if cur["act_copy"]:
					print("ERROR: act copy")
					sys.exit(1)
				del cur["act_copy"]
		return cur

	base = resolve(cur["base"])

	merged = {
		"layers": list(base.get("layers", [])),
		"offsets": dict(base.get("offsets", {})),
		"act": copy.deepcopy(base.get("act", {})),
		"flatten": base.get("flatten", False)
	}

	minus = cur.get("layers_minus", [])
	if "layers_minus_copy" in cur:
		minus.extend( all_data[cur["layers_minus_copy"]]["layers_minus_reuse"] )
	if "layers_minus_reuse" in cur:
		minus.extend( cur["layers_minus_reuse"] )

	replacements = cur.get("layers_replace", {})
	if "layers_replace_copy" in cur:
		replacements.update( all_data[cur["layers_replace_copy"]]["layers_replace_reuse"] )
	if "layers_replace_reuse" in cur:
		replacements.update( cur["layers_replace_reuse"] )

	#plus = cur.get("layers_plus", [])

	merged_layers = merged["layers"]

	merged_layers.extend(base.get("layers_reuse", []))

	# remove first
	merged_layers = [l for l in merged_layers if l not in minus]

	# replace
	for old, new in replacements.items():
		if old in merged_layers:
			i = merged_layers.index(old)
			merged_layers[i] = new
			if "act" in merged:
				if old in merged["act"]:
					merged["act"][new] = merged["act"].pop(old)
		else:
			print("ERROR: layer not found for replace:", old)
			sys.exit(1)

	# append
	#for l in plus:
	#	merged_layers.append(l)

	merged["layers"] = merged_layers

	if "offsets_copy" in cur:
		offsets_set(all_data[cur["offsets_copy"]]["offsets_reuse"],merged)
	if "offsets_reuse" in cur:
		offsets_set(cur["offsets_reuse"],merged)
	if "offsets" in cur:
		offsets_set(cur["offsets"],merged)

	if "act" in cur:
		#ke=[]
		for key, value in cur["act"].items():
			if key in merged["act"]:
				merged["act"][key].extend(value)
				#ke.append(key)
			else:
				merged["act"][key] = value
		#for k in ke:
		#	del cur["act"][k]

	if "flatten" in cur:
		merged["flatten"] = cur["flatten"]

	return merged

def main():
	json_file = sys.argv[1]
	input_ora = sys.argv[2]
	output_dir = sys.argv[3]

	global img_viewer
	no_view=os.environ.get("no_view")
	if no_view:
		img_viewer = None
	else:
		with open(os.path.expanduser("~/imgviewer"), "r") as f:
			img_viewer = f.read()
	global launcher
	launcher=os.environ.get("p")
	if not launcher:
		launcher="python"

	global all_data, constants
	with open(json_file) as f:
		all_data = json.load(f)
	constants = all_data.pop("constants", {})

	if len(sys.argv) > 4:
		data = {}
		for name in sys.argv[4:]:
			if name not in all_data:
				print("ERROR: scene not found:", name)
				sys.exit(1)
			data[name] = all_data[name]
	else:
		data = all_data

	for name in data.keys():
		cfg = resolve(name)
		run_scene(name, cfg, input_ora, output_dir)

if __name__ == "__main__":
	main()

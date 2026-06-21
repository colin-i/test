#!/usr/bin/env python3

import argparse
import json
from PIL import Image
import xml.etree.ElementTree as ET
import zipfile


def parse_args():
	p = argparse.ArgumentParser()

	p.add_argument("input")
	p.add_argument("output")

	p.add_argument("--layers", nargs="+", required=True,
		help="layer names to include")

	p.add_argument("--offset", action="append", default=[],
		help="layer_name:y_offset like Eyes:3 or Hat:-10")

	p.add_argument("--act")

	p.add_argument("--flatten", action="store_true")

	return p.parse_args()


def parse_offsets(offset_list):
	offsets = {}
	for item in offset_list:
		name, val = item.split(":")
		offsets[name] = int(val)
	return offsets


def load_layers(zf):
	root = ET.fromstring(zf.read("stack.xml"))

	layers = []

	def walk(node):
		for child in node:
			tag = child.tag.lower()

			if tag.endswith("layer"):
				layers.append({
					"name": child.attrib.get("name", ""),
					"src": child.attrib["src"],
					"x": int(child.attrib.get("x", "0")),
					"y": int(child.attrib.get("y", "0")),
				})

			elif tag.endswith("stack"):
				walk(child)

	walk(root)
	return layers


def canvas_size(zf, layers):
	w, h = 0, 0

	for l in layers:
		with zf.open(l["src"]) as f:
			img = Image.open(f)
			img.load()

		w = max(w, l["x"] + img.width)
		h = max(h, l["y"] + img.height)

	return w, h


def main():
	args = parse_args()

	offsets = parse_offsets(args.offset)
	acts = json.loads(args.act) if args.act else {}

	with zipfile.ZipFile(args.input) as zf:

		layers = load_layers(zf)

		#print("Available layers:");for l in layers:print("-", l["name"])

		selected = []
		for name in args.layers:
			found = None
			for l in layers:
				if l["name"] == name:
					found = l
					break

			if not found:
				print("ERROR: layer not found:", name)
				exit(1)

			selected.insert(0,found)

		w, h = canvas_size(zf, selected)

		canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))

		for l in selected:

			with zf.open(l["src"]) as f:
				img = Image.open(f).convert("RGBA")

			x = l["x"]
			y = l["y"] + offsets.get(l["name"], 0)

			#P
			#dH
			#VM
			tmps = []
			tmps.append(Image.new("RGBA", canvas.size, (0, 0, 0, 0)))
			ix=0
			inx=0
			layer_acts = acts.get(l["name"])
			if layer_acts:
				for act in layer_acts:
					tp = Image.new("RGBA", canvas.size, (0,0,0,0))
					for op in act[0]:
						paint=True
						if op == "m":
							tp.paste(img, (x + act[1], y + act[2]))
						elif op == "v":
							tp = tp.transpose(Image.FLIP_TOP_BOTTOM)
						elif op == "h":
							tp = tp.transpose(Image.FLIP_LEFT_RIGHT)
						elif op == "p":
							tp.paste(tmps[ix], (x, y))
							tmps.append(tp)
							ix=ix+1
							inx=inx+1
							paint=False
						elif op == "d":
							tp.paste(img, (x, y))
						elif op == "M":
							tp.paste(tmps[ix], (x + act[1], y + act[2]))
							tmps[ix] = tp
							paint=False
						elif op == "V":
							tp = Image.alpha_composite(tp, tmps[ix])
							tp = tp.transpose(Image.FLIP_TOP_BOTTOM)
						elif op == "H":
							tp = Image.alpha_composite(tp, tmps[ix])
							tp = tp.transpose(Image.FLIP_LEFT_RIGHT)
						elif op == "P":
							ix=ix-1
							paint=False
						else:
							print("ERROR: unrecognized op ", op)
							exit(1)
					if paint:
						tmps[ix] = Image.alpha_composite(tmps[ix], tp)
			else:
				tmps[ix].paste(img, (x, y))

			for i in range(0,inx+1):
				canvas = Image.alpha_composite(canvas, tmps[i])

			print("layer", l["name"], "at", (x, y))

		if args.flatten:
			bg = Image.new("RGBA", canvas.size, (255, 255, 255, 255))
			canvas = Image.alpha_composite(bg, canvas)
			canvas = canvas.convert("RGB")

		canvas.save(args.output)
		print("saved:", args.output)


if __name__ == "__main__":
	main()

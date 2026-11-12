#!/usr/bin/env python3
import json
import os
import re
import sys
import urllib.request

# Usage: python refs.py [article.wiki]
#    or: cat article.wiki | python refs.py
#    or from ~/.gh_refs.wiki

GITHUB = re.compile(r'github\.com/([^/\s\]|<]+)/([^/\s\]|<#?]+)')
LINKED = re.compile(r'^\*\s*\[\[([^\]|]+)')
PLAIN = re.compile(r'^\*\s*([^<\[{]+?)\s*(?:<|\s-\s|$)')
WIKI_URL = 'https://en.wikipedia.org/w/index.php?title=Physics_engine&action=raw'

def read_source():
	if len(sys.argv) > 1:
		return open(sys.argv[1], encoding='utf-8').read()
	if not sys.stdin.isatty():
		return sys.stdin.read()
	path = os.path.expanduser('~/.gh_refs.wiki')
	if os.path.exists(path):
		return open(path, encoding='utf-8').read()
	req = urllib.request.Request(WIKI_URL, headers={'User-Agent': 'refs.py (personal script)'})
	with urllib.request.urlopen(req) as response:
		return response.read().decode('utf-8')

def entry_name(line):
	m = LINKED.match(line) or PLAIN.match(line)
	return m.group(1).strip() if m else line

def main():
	text = read_source()

	in_section = False
	selected = False
	seen_header = '=== Real-time physics engines ===' in text
	out = []

	for line in text.splitlines():
		if '=== Real-time physics engines ===' in line:
			in_section = True
			continue
		if seen_header and not in_section:
			continue
		if in_section and line.startswith('='):
			break
		if line.startswith(';'):
			header = line[1:].strip()
			selected = header.startswith(('Open source', 'Public domain'))
			print(f'{"selected" if selected else "not selected"}: {header}')
			continue
		if not selected or not line.startswith('*'):
			continue

		m = GITHUB.search(line)
		if m:
			owner, name = m.group(1), m.group(2)
			if name.endswith('.git'):
				name = name[:-4]
			out.append(f'{owner}/{name}')
		else:
			print(f'no github: {entry_name(line)}')

	if not os.environ.get('test'):
		results = []

		for repo in out:
			url = f"https://api.github.com/repos/{repo}"

			try:
				req = urllib.request.Request(url, headers={"User-Agent": "Python"})
				with urllib.request.urlopen(req) as response:
					data = json.load(response)
					results.append((repo, data['stargazers_count']))
			except Exception as e:
				print(f"{repo}: ERROR ({e})")

		results.sort(key=lambda x: x[1], reverse=True)
		for repo, stars in results:
			print(f"{repo}: {stars}")

if __name__ == '__main__':
	main()

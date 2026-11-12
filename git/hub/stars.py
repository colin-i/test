#!/usr/bin/env python3
import json
import os
import re
import sys
import urllib.request

# Usage: python stars.py [article.wiki]
#    or: cat article.wiki | python stars.py
#    or from ~/.gh_stars.wiki

GITHUB = re.compile(r'github\.com/([^/\s\]|<]+)/([^/\s\]|<#?]+)')
LINKED = re.compile(r'^\*\s*\[\[([^\]|]+)')
PLAIN = re.compile(r'^\*\s*([^<\[{]+?)\s*(?:<|\s-\s|\sby\s|$)')
WIKI_URL = 'https://en.wikipedia.org/w/index.php?title=Physics_engine&action=raw'
OVERRIDES = {
	'CryPhysics': 'MergHQ/CRYENGINE',
	'idPhysics': 'id-Software/DOOM-3-BFG',
}

def read_source():
	if len(sys.argv) > 1:
		return open(sys.argv[1], encoding='utf-8').read()
	if not sys.stdin.isatty():
		return sys.stdin.read()
	path = os.path.expanduser('~/.gh_stars.wiki')
	if os.path.exists(path):
		return open(path, encoding='utf-8').read()
	req = urllib.request.Request(WIKI_URL, headers={'User-Agent': 'stars.py (personal script)'})
	with urllib.request.urlopen(req) as response:
		return response.read().decode('utf-8')

def entry_name(line):
	m = LINKED.match(line) or PLAIN.match(line)
	return m.group(1).strip() if m else line

def main():
	text = read_source()

	in_section = False
	seen_header = '=== Real-time physics engines ===' in text
	out = []
	test=os.environ.get('test')

	for line in text.splitlines():
		if '=== Real-time physics engines ===' in line:
			in_section = True
			continue
		if seen_header and not in_section:
			continue
		if in_section and line.startswith('='):
			break
		if line.startswith(';'):
			print(f'\n{line[1:]}')
			continue
		if not line.startswith('*'):
			continue

		name = entry_name(line)
		m = GITHUB.search(line)
		if m:
			owner, repo = m.group(1), m.group(2)
			if repo.endswith('.git'):
				repo = repo[:-4]
			out.append(f'{owner}/{repo}')
			if not test:
				if name in OVERRIDES:
					del OVERRIDES[name]
				continue
			if name in OVERRIDES:
				del OVERRIDES[name]
				s='ignored in overrides'
			else:
				s='ok'
		elif name in OVERRIDES:
			out.append(OVERRIDES.pop(name))
			s='override'
		else:
			s='no github'
		print(f'{s}: {name}')

	if len(OVERRIDES):
		print()
		for name in OVERRIDES:
			print(f'unused override: {name}')

	print()
	if not test:
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


import sys

import requests
url = "https://pypi.org/pypi/"+sys.argv[1]+"/json"
r = requests.get(url)
data = r.json()
for version, files in data['releases'].items():
	for f in files:
		if f.get('yanked') == False and f.get('packagetype') == 'sdist':
			print(version)
			if version == sys.argv[2]:
				print("ok")
				exit(0)
exit(1)


import sys
if len(sys.argv)!=5: exit(1)

# Define the dictionary
lines = {
    "48": 59
}
stations = {
    "Cap linie Palas - Debarcare": 1266
}

params = {
    "selected_line_id": lines[sys.argv[1]],
    "stop_id": stations[sys.argv[2]]
}

from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options

chrome_driver_path = "/usr/bin/chromedriver"  # driver-ul tău manual
chromium_binary = "/usr/bin/chromium"         # binarul Chromium

options = Options()
options.binary_location = chromium_binary
#options.add_argument("--start-maximized")
#options.add_argument("--headless")  # not working

# activăm performance logging
options.set_capability("goog:loggingPrefs", {"performance": "ALL"})

service = Service(chrome_driver_path)

driver = webdriver.Chrome(service=service, options=options)

import json

driver.get("https://info.ctbus.ro")

logs = driver.get_log("performance")

user_info_value = None
app_id_value = None

for entry in logs:
    log = json.loads(entry["message"])["message"]

    if log["method"] == "Network.requestWillBeSent":
        request = log["params"]["request"]
        url = request.get("url", "")

        if "/api/" in url:
            headers = request.get("headers", {})

            if "User-Info" in headers:
                user_info_value = headers["User-Info"]
                print("Găsit User-Info:", user_info_value)
                print("URL:", url)

            if "App-Id" in headers:
                app_id_value = headers["App-Id"]
                print("Găsit App-Id:", app_id_value)
                print("URL:", url)

driver.quit()

print("FINAL User-Info =", user_info_value)
print("FINAL App-Id =", app_id_value)

import requests

url = "https://info.ctbus.ro/api/web/v2-6/lines/stop"

headers = {
    "Accept": "application/json",            # application/json, text/plain, */*
    "User-Agent": "Mozilla/5.0",
    "App-Id": app_id_value,
    "App-Version": "0.0.0",
    "Device-Name": "Chrome",                 # Firefox
    "User-Info": user_info_value,
    "OS-Type": "Web",
    "OS-Version": "5.0 (X11; Linux x86_64)", # 5.0 (X11)
    "Lang": "ro",
    "Source": "ro.radcom.smartcity.web"
}

response = requests.get(url, headers=headers, params=params)

# Print HTTP status code
print("Status Code:", response.status_code)

data = response.content                      # with open("1", "rb") as f: data = f.read()
time_dict = {}

import generic_pb2
root = generic_pb2.Root()
root.ParseFromString(data)
for item in root.items10: # for ? AttributeError: 'RepeatedCompositeFieldContainer' object has no attribute 'field10' # item = root.items10
	time_dict = {int(sub.field1): list(map(int, sub.field2)) for sub in item.field10}

#pairs = re.findall(rb'\x0a\x02(\d{2})|\x12\x02(\d{2})', data)
#values = []
#for a, b in pairs:
#    if a:
#        values.append(("H", a.decode()))
#    elif b:
#        values.append(("M", b.decode()))
#schedule = {}
#current_hour = None
#for typ, val in values:
#    if typ == "H":
#        current_hour = val
#        schedule[current_hour] = []
#    elif typ == "M" and current_hour:
#        schedule[current_hour].append(val)
#for h in sorted(schedule.keys()):
#    print(f"{h}: {' '.join(schedule[h])}")

for key, value in time_dict.items():
	print(f"{key}: {value}")

def previous_times(h, m, n=3):
	result = {}
	i=0
	while i < n:
		if h not in time_dict:
			h -= 1
			m = 60
			continue
		# Find all minutes smaller than current minute
		candidates = [x for x in time_dict[h] if x < m]
		while candidates and i < n:
			m_prev = candidates.pop()  # take the largest smaller minute
			if h not in result:
				result[h] = []
			result[h].append(m_prev)
			i+=1
		# Move to previous hour
		h -= 1
		if h < min(time_dict.keys()):
			break  # reached beginning
		m = 60  # reset minute to find previous
	return result

prev_dict = previous_times(int(sys.argv[3]), int(sys.argv[4]))
print(prev_dict)

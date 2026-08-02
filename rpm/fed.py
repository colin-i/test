from copr.v3 import Client

client = Client.create_from_config_file()
p = client.project_proxy.get("colin", "project")

import json
print(json.dumps(p.__response__.json()))

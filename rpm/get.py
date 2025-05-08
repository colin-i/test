
import sys
p=sys.argv[1]

from copr.v3 import Client
client = Client.create_from_config_file()
x=client.package_proxy.get("colin", "project", p)
print(x.__response__.json())

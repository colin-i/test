
import sys
p=sys.argv[1]

from copr.v3 import Client
client = Client.create_from_config_file()
fn=eval("client."+sys.argv[2]+"."+sys.argv[3])

x=fn("colin", "project", p)
print(x.__response__.json())

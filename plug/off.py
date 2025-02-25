
import broadlink
import os
try:
	with open(os.getenv('HOME')+'/broadlinkip', 'r') as file:
		dev=broadlink.hello(file.read())
except:
	devices = broadlink.discover(discover_ip_address='192.168.1.255')
	dev=devices[0]
dev.auth()
dev.set_power(False)

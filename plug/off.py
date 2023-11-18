
import broadlink

devices = broadlink.discover(discover_ip_address='192.168.1.255')
device=devices[0]
device.auth()
device.set_power(False)

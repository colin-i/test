
import broadlink

devices = broadlink.discover()

device=devices[0]

device.auth()

device.set_power(True)
device.set_power(False)

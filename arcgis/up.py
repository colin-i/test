from os import path
from imgur_python import Imgur
import sys

if len(sys.argv)<3:
	exit()
file = path.realpath(sys.argv[1])
title = 'Img'
description = 'Image'
album = None
disable_audio = 0

imgur_client = Imgur({'client_id': sys.argv[2]})
response = imgur_client.image_upload(file, title, description, album, disable_audio)
print(response['response']['data']['link'])

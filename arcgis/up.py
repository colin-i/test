
import sys
if len(sys.argv)<3:
	exit()

import pyimgur
from os import path

CLIENT_ID = sys.argv[2]
PATH = path.realpath(sys.argv[1])

im = pyimgur.Imgur(CLIENT_ID)
uploaded_image = im.upload_image(PATH, title="Auto")
print(uploaded_image.title)
print(uploaded_image.link)
print(uploaded_image.size)
print(uploaded_image.type)

'''
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
'''

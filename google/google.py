
#1 file name  optional 2 list only

from __future__ import print_function

import google.auth
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

import sys

mim='application/vnd.oasis.opendocument.spreadsheet'

def upload_basic():
	# create drive api client
	service = build('drive', 'v3', credentials=creds)

	file_metadata = {'name': fname} #, 'parents': ['###']

	media = MediaFileUpload(fname,mimetype=mim)
	# pylint: disable=maybe-no-member
	file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
	print(F'File ID: {file.get("id")}')

	yourEmailOfGoogleAccount = 'costin.botescu@gmail.com'
	permission = {
	    'type': 'user',
	    'role': 'writer',
	    'emailAddress': yourEmailOfGoogleAccount,
	}
	service.permissions().create(fileId=file['id'], body=permission).execute()

	#file_back = service.files().get(fileId=file['id'], fields='webContentLink').execute()  # or fields='*'
	#print(file_back.get('webContentLink'))

	return file

def search_file(newid):
	#files = []
	page_token = None
	while True:
		# pylint: disable=maybe-no-member
		response = service.files().list(q="mimeType='"+mim+"'",
			                    spaces='drive',
			                    fields='nextPageToken, '
			                    'files(id, name, createdTime)',
			                    pageToken=page_token).execute()
		for file in response.get('files', []):
			# Process change
			if file.get("name")==fname:
				print(F'Found file: {file.get("name")}, {file.get("id")}, {file.get("createdTime")}')
				if newid!=None:
					id=file['id']
					if id!=newid:
						service.files().delete(fileId=id).execute()
						print('deleted')

		#files.extend(response.get('files', []))
		page_token = response.get('nextPageToken', None)
		if page_token is None:
			break

creds, _ = google.auth.default()
service = build('drive', 'v3', credentials=creds)

fname=sys.argv[1]
try:
	sys.argv[2]
	search_file(None)
except:
	f=upload_basic()
	search_file(f['id'])

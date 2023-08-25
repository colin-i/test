
#same as ./a

import sys
import io

import google.auth
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from googleapiclient.http import MediaIoBaseDownload

mim='application/vnd.oasis.opendocument.spreadsheet'

def upload_basic():
	file_metadata = {'name': fname} #, 'parents': ['###']

	media = MediaFileUpload(fname,mimetype=mim)
	# pylint: disable=maybe-no-member
	file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
	print(F'File ID: {file.get("id")}')

	#"You cannot share this item because it has been flagged as inappropriate."
	#yourEmailOfGoogleAccount = '***@gamil.com'
	#permission = {
	#    'type': 'user',
	#    'role': 'writer',
	#    'emailAddress': yourEmailOfGoogleAccount,
	#}
	#service.permissions().create(fileId=file['id'], body=permission).execute()

	return file

def search_file(newid,download=False):
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
				elif download==True:
					#file_back = service.files().get(fileId=file['id'], fields='webContentLink').execute()  # or fields='*'
					request = service.files().get_media(fileId=file['id'])
					file = io.FileIO(fname,'wb')
					downloader = MediaIoBaseDownload(file, request)
					done = False
					while done is False:
						status, done = downloader.next_chunk()
						print(F'Download {int(status.progress() * 100)}.')

		#files.extend(response.get('files', []))
		page_token = response.get('nextPageToken', None)
		if page_token is None:
			break

creds, _ = google.auth.default()
# create drive api client
service = build('drive', 'v3', credentials=creds)

fname=sys.argv[1]
try:
	flag=sys.argv[2]
	if flag=="0":
		search_file(None,True)
	else:
		search_file(None)
except:
	f=upload_basic()
	search_file(f['id'])

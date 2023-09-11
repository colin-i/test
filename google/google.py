
#same as ./a

import sys
import google.auth
from googleapiclient.discovery import build

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

def print_file(file): #,extra=''
	print(F'Found file: {file.get("name")}, {file.get("id")}, {file.get("createdTime")}')
	#+((' '+extra) if extra else '')
def search_file(newid,download=False,all=False):
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
			if all==False:
				if file.get("name")==fname:
					print_file(file)
					if newid!=None:
						id=file['id']
						if id!=newid:
							service.files().delete(fileId=id).execute()
							print('deleted')
					elif download==True:
						request = service.files().get_media(fileId=file['id'])
						file = io.FileIO(fname,'wb')
						downloader = MediaIoBaseDownload(file, request)
						done = False
						while done is False:
							status, done = downloader.next_chunk()
							print(F'Download {int(status.progress() * 100)}.')
			else:
				#file_back = service.files().get(fileId=file['id'], fields='webContentLink').execute()  # or fields='*'
				#,file_back['webContentLink']
				print_file(file)

		#files.extend(response.get('files', []))
		page_token = response.get('nextPageToken', None)
		if page_token is None:
			break

creds, _ = google.auth.default()
# create drive api client
service = build('drive', 'v3', credentials=creds)

fname=sys.argv[1]
if len(sys.argv)>2:
	flag=sys.argv[2]
	if flag=="0":
		import io
		from googleapiclient.http import MediaIoBaseDownload
		search_file(None,True)
	else:
		search_file(None)
else:
	if fname!="0":
		from googleapiclient.http import MediaFileUpload
		f=upload_basic()
		search_file(f['id'])
	else:
		search_file(None,all=True)

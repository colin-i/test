
#same as ./a

import os

if os.environ.get('mimeType'):
	mim=os.environ['mimeType']
else:
	mim='application/vnd.oasis.opendocument.spreadsheet'

import sys
import google.auth
from googleapiclient.discovery import build

creds, _ = google.auth.default()
# create drive api client
service = build('drive', 'v3', credentials=creds)

if os.environ.get('folder'):
	response = service.files().list(q="mimeType='application/vnd.google-apps.folder'" "and name = '"+os.environ['folder']+"'"
		,spaces='drive',fields='files(id)').execute()
	folderid=response['files'][0]['id']
	folder=" and '"+folderid+"' in parents"
else:
	folder=""

def upload_basic():
	file_metadata = {'name': fname}
	if folder:
		file_metadata['parents']=[folderid]

	media = MediaFileUpload(fname,mimetype=mim)
	# pylint: disable=maybe-no-member
	file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
	fileid=file['id']
	print('File ID: '+fileid)

	#"You cannot share this item because it has been flagged as inappropriate."
	#yourEmailOfGoogleAccount = '***@gamil.com'
	#permission = {
	#    'type': 'user',
	#    'role': 'writer',
	#    'emailAddress': yourEmailOfGoogleAccount,
	#}
	#service.permissions().create(fileId=fileid, body=permission).execute()

	if os.environ.get('anyone'):
		permission = {
			'type': 'anyone',
			'role': 'reader'
		}
		service.permissions().create(fileId=fileid, body=permission).execute()
		response=service.permissions().list(fileId=fileid).execute()
		print(response['permissions'])

	return fileid

def print_file(file): #,extra=''
	print(F'Found file: {file.get("name")}, {file.get("id")}, {file.get("createdTime")}, {file.get("webContentLink")}')
	#+((' '+extra) if extra else '')
def deletefile(id):
	service.files().delete(fileId=id).execute()
	print('deleted')
def search_file(newid,download=False,all=False,delete=False):
	#files = []
	page_token = None
	while True:
		# pylint: disable=maybe-no-member
		response = service.files().list(q="mimeType='"+mim+"'"+folder,
			                    spaces='drive',
			                    fields='nextPageToken, '
			                    'files(id, name, createdTime, webContentLink)',
			                    pageToken=page_token).execute() # fields='*' was ok, here files(*)?
		for file in response.get('files', []):
			if all==False:
				if file.get("name")==fname:
					print_file(file)
					if newid!=None:
					#upload and delete old
						id=file['id']
						if id!=newid:
							deletefile(id)
					elif download==True:
					#download
						request = service.files().get_media(fileId=file['id'])
						file = io.FileIO(fname,'wb')
						downloader = MediaIoBaseDownload(file, request)
						done = False
						while done is False:
							status, done = downloader.next_chunk()
							print(F'Download {int(status.progress() * 100)}.')
						#return? can go here again, is not what I am doing but still can be
					elif delete==True:
						deletefile(file['id'])
					#else:
					#list name
			else:
			#list all
				print_file(file)

		#files.extend(response.get('files', []))
		page_token = response.get('nextPageToken', None)
		if page_token is None:
			break

fname=sys.argv[1]
if len(sys.argv)>2:
	flag=sys.argv[2]
	if flag=="0":
	#download
		import io
		from googleapiclient.http import MediaIoBaseDownload
		search_file(None,True)
	elif flag=="1":
	#delete
		search_file(None,delete=True)
	else:
	#list name
		search_file(None)
else:
	if fname!="0":
	#upload
		from googleapiclient.http import MediaFileUpload
		file_id=upload_basic()
		if not os.environ.get('keep_old'):
		#and delete old
			search_file(file_id)
		else:
		#list all
			search_file(None,all=True)
	else:
	#list all
		search_file(None,all=True)


#file_metadata = { 'name': 'old/o', 'mimeType': 'application/vnd.google-apps.folder' }
#service.files().create(body=file_metadata).execute()

#service.permissions().delete(fileId=file['id'],permissionId='anyoneWithLink').execute()

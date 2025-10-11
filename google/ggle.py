
#same as ./a

import os

if os.environ.get('mimeType'):
	mim=os.environ['mimeType']
else:
	mim=""
# application/gzip
# application/pdf
# application/vnd.debian.binary-package
# application/vnd.google-apps.folder
# application/vnd.oasis.opendocument.spreadsheet
# application/x-rpm
# image/jpeg
# text/plain

import sys

import google.auth # python3-google-auth
from googleapiclient.discovery import build # python3-googleapi

creds, _ = google.auth.default()
# create drive api client
service = build('drive', 'v3', credentials=creds)
permissionAnyone='anyoneWithLink'
is_html=os.environ.get('html')

#file_metadata = { 'name': sys.argv[1], 'mimeType': 'application/vnd.google-apps.folder', 'parents': [sys.argv[2]] }
#service.files().create(body=file_metadata).execute()

#service.permissions().delete(fileId=file['id'],permissionId=permissionAnyone).execute()

dir=os.environ.get('folder')
if dir:
	folders=dir.split("/")
	if len(folders)>1:
		dir_root=folders[1]
		response = service.files().list(q="name = '"+folders[0]+"'",spaces='drive',fields='files(id)').execute()
		dir_q=" and '"+response['files'][0]['id']+"' in parents"
	else:
		dir_root=folders[0]
		dir_q=''
	response = service.files().list(q="name = '"+dir_root+"'"+dir_q,spaces='drive',fields='files(id)').execute()
	folderid=response['files'][0]['id']
	folder="'"+folderid+"' in parents"
elif os.environ.get('folderid'):
	folderid=os.environ.get('folderid') #also at upload
	folder="'"+folderid+"' in parents"
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

	return fileid

def print_file(file):
	if is_html!=None: #arhpub/b
		print('<p>',end='')
	print(F'{file.get("name")},{file.get("id")},{file.get("createdTime")},{file.get("size")},{file.get("webContentLink")},{file.get("parents")},',end='')
	response=service.permissions().list(fileId=file.get("id")).execute()
	if response['permissions'][0]['id']==permissionAnyone:
		print(permissionAnyone,end='')
	if is_html!=None:
		print('</p>')
	else:
		print()
def deletefile(id): #attention at sub-folders(pass also the folder/folderid)
	service.files().delete(fileId=id).execute()
	print('deleted')
def search_file(newid=None,download=False,delete=False,ignore_fname=False):
	#files = []
	page_token = None
	while True:
		# pylint: disable=maybe-no-member
		if mim:
			q="mimeType='"+mim+"'"
			if folder:
				q+=" and "+folder
		else:
			if folder:
				q=folder
			else:
				q=""
		response = service.files().list(q=q,
			                    spaces='drive',
			                    fields='nextPageToken, '
			                    'files(id, name, createdTime, size, webContentLink, parents)',
			                    pageToken=page_token).execute() # fields='*' was ok, here files(*)?
		if newid!=None and delete==True: #will also ignore_fname
			#delete one id
			for file in response.get('files', []):
				if newid==file['id']:
					print_file(file)
					deletefile(newid) #delete only one id from same file
					break
		elif ignore_fname==False: #4 cases here
			for file in response.get('files', []):
				if file.get("name")==fname:
					print_file(file)
					if newid!=None: #was upload, delete old version(s)
						id=file['id']
						if id!=newid:
							deletefile(id) #and continue for safety
					elif download==True:
					#download
						request = service.files().get_media(fileId=file['id'])
						file = io.FileIO(fname,'wb')
						downloader = MediaIoBaseDownload(file, request)
						done = False
						while done is False:
							status, done = downloader.next_chunk()
							print(F'Download {int(status.progress() * 100)}.')
						#return? can go here again, is not what I am doing but stil can continue test for safety
					elif delete==True: #delete
						deletefile(file['id']) #and continue for safety
					#else: #list name
		else: #list all
			for file in response.get('files', []):
				print_file(file)

		#files.extend(response.get('files', []))
		page_token = response.get('nextPageToken', None)
		if page_token is None:
			break
def search_file_all():
	search_file(ignore_fname=True)

fname=sys.argv[1]
if len(sys.argv)>2:
	flag=sys.argv[2]
	if flag=="0":
	#download
		import io
		from googleapiclient.http import MediaIoBaseDownload
		search_file(download=True)
	elif flag=="1":
	#delete
		search_file(delete=True)
	elif flag=="2":
	#delete one id
		search_file(newid=fname,delete=True)
	else:
	#list name
		search_file()
else:
	if fname!="0":
	#upload
		from googleapiclient.http import MediaFileUpload
		file_id=upload_basic()
		if not os.environ.get('keep_old'):
		#and delete old
			search_file(newid=file_id)
		else:
		#list all, is for ~/arhpub
			search_file_all()
	else:
	#list all
		search_file_all()

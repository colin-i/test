

import google.auth
from googleapiclient.discovery import build

creds, _ = google.auth.default()
service = build('drive', 'v3', credentials=creds)

mim='application/vnd.google-apps.folder'

#file_metadata = {
#	'name': 'old',
#	'mimeType': mim
#}
#service.files().create(body=file_metadata).execute()

response = service.files().list(q="mimeType='"+mim+"'" "and name = 'old'"
	,spaces='drive',fields='files(id)',pageToken=None).execute()
dirid=response['files'][0]['id']

mim2='application/vnd.debian.binary-package'

response = service.files().list(q="mimeType='"+mim2+"'" "and '"+dirid+"' in parents"
	,spaces='drive',fields='files(id)',pageToken=None).execute()

exit()

fname='a.deb'
file_metadata = {'name': fname
	,'parents': [dirid]}
from googleapiclient.http import MediaFileUpload
media = MediaFileUpload(fname,mimetype=mim2)

file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
print(F'File ID: {file.get("id")}')

exit()

permission = {
    'type': 'anyone',
    'role': 'reader'
}
service.permissions().create(fileId=file['id'], body=permission).execute()
#service.permissions().delete(fileId=file['id'],permissionId='anyoneWithLink').execute()
#service.files().get(fileId=file['id'], fields='webContentLink').execute()

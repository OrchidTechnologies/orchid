#!/usr/bin/env python3

# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


import socket
import sys

from googleapiclient import discovery
from googleapiclient.http import build_http

from oauth2client.service_account import ServiceAccountCredentials

bundle, apk = sys.argv[1:]

# timeouts are pretty much /always/ the wrong solution to /every/ problem
# sadly, the Google API client build_http (which I could just ignore?...)
# actually checks your timeout and if you don't have one it sets it to 60
# this is nowhere near long enough, though, to upload a large APK file :/
socket.setdefaulttimeout(60*60)

credentials = ServiceAccountCredentials.from_json_keyfile_name("../client_secrets.json",
    scopes=["https://www.googleapis.com/auth/androidpublisher"])
http = credentials.authorize(http=build_http())
service = discovery.build('androidpublisher', 'v3', http=http)
edits = service.edits()

edit = edits.insert(body={}, packageName=bundle).execute()['id']
upload = edits.apks().upload(packageName=bundle, editId=edit, media_body=apk).execute()
# {'versionCode': dec, 'binary': {'sha1': 'hex', 'sha256': 'hex'}}
edits.tracks().update(packageName=bundle, editId=edit, track="production", body={
    'releases': [{'status': 'draft', 'versionCodes': [str(upload['versionCode'])]}]}).execute()
edits.commit(editId=edit, packageName=bundle).execute()['id']

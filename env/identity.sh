#!/bin/bash
set -e
security cms -D -i "$1" | plutil -extract DeveloperCertificates xml1 -o - - | tr -d $' \t\n' | sed -e $'s@</data><data>@\\\n@g;s/<[^>]*>//g' | while read -r data; do
    echo "${data}" | base64 -D | openssl x509 -inform der -fingerprint -noout | sed -e 's/^[^=]*=//;s/://g'
done

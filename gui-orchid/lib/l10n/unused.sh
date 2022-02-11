#!/bin/sh
#
# Attempt to find unused strings in the generated localization file.
#

echo "Update this for shared apps"
exit

cd $(dirname "$0")

gen=../../.dart_tool/flutter_gen/gen_l10n/app_localizations.dart 
list=$(grep '^  String get' $gen | sed 's/^  String get //' | tr -d ';')
cd ..
for s in $list
do
    got=$(egrep --exclude-dir l10n -r "(S.of\(context\)|s)\.${s}([^A-Za-z0-9]|$)" .)
    if [ -z "$got" ]; then echo "$s"; fi
done

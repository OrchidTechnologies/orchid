#!/bin/bash
set -e

usr=$1
git=$2
shift 2
[[ $# -eq 0 ]]

tag=$(git describe --tags --match="v*" --exact-match)
ver=${tag#v}

ish=$(git rev-parse "${tag}^{commit}")

rel=$(curl -su "${usr}" --data-raw '{
    "tag_name": "'"${tag}"'",
    "target_commitish": "'"${ish}"'",
    "name": "'"${tag}"'",
    "draft": true
}' "https://api.github.com/repos/${git}/releases" | jq -r '.id')

env/upload-gha.sh "${usr}" "${git}" "${rel}" app-android/out-and/Orchid.apk application/vnd.android.package-archive orchid-apk_"${ver}".apk

env/upload-gha.sh "${usr}" "${git}" "${rel}" cli-shared/out-lnx/x86_64/orchidcd application/x-elf orchidcd-lnx_"${ver}"
env/upload-gha.sh "${usr}" "${git}" "${rel}" cli-shared/out-mac/x86_64/orchidcd application/x-mach-binary orchidcd-mac_"${ver}"
env/upload-gha.sh "${usr}" "${git}" "${rel}" cli-shared/out-win/x86_64/orchidcd.exe application/vnd.microsoft.portable-executable orchidcd-win_"${ver}".exe

env/upload-gha.sh "${usr}" "${git}" "${rel}" srv-daemon/out-lnx/x86_64/orchidd application/x-elf orchidd-lnx_"${ver}"
#env/upload-gha.sh "${usr}" "${git}" "${rel}" srv-daemon/out-mac/x86_64/orchidd application/x-mach-binary orchidd-mac_"${ver}"
#env/upload-gha.sh "${usr}" "${git}" "${rel}" srv-daemon/out-win/x86_64/orchidd.exe application/vnd.microsoft.portable-executable orchidd-win_"${ver}".exe

curl -u "${usr}" --data-raw '{"draft": false}' "https://api.github.com/repos/${git}/releases/${rel}"

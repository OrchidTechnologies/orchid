#
# Use the simulator to generate iOS screenshots.
# This should be link and run from the app-flutter build folder (see app-flutter.sh)
#
set -euo pipefail

cleanup() {
    local pids=$(jobs -pr)
    [ -n "$pids" ] && kill $pids
}
trap "cleanup" INT QUIT TERM EXIT

cd $(dirname "$0")

# See identity.sh.in
#. identity.sh
identity=""

# screen(device, identity, screen, connected, language, filebase)
screen() {
    device=$1
    identity="$2"
    screen=$3
    connected=$4
    language=$5
    filebase=$6

    (sleep 45; 
        echo "Screenshot for: $filebase $identity, $screen, $connected, $language"
        flutter screenshot -d $device -o "${filebase}_${screen}_${connected}_${language}.png"
    ) &

    # Could use this to save time:
    # --use-application-binary=<path/to/app.ipa> 
    # Note that --no-build doesn't work / is deprecated.
    (cd ../../app-flutter;
    (sleep 55; echo 'q') | ../app-shared/flutter/bin/flutter run -d $device \
        --dart-define mock=true \
        --dart-define mock_accounts=true \
        --dart-define identity="$identity" \
        --dart-define language=$language \
        --dart-define connected=$connected \
        --dart-define release_notes=false \
        --dart-define hide_prices=true \
        --dart-define screen="$screen"
    )
}

# Required for screenshots
emulator=Pixel_4_Pie

# launch emulator
echo init $emulator
flutter emulators --launch $emulator

# TODO: Get this from launch somehow? (or 'flutter devices')
emulator_instance=emulator-5554 
device=$emulator_instance
device_name='pixel_4'

screens="connect accounts traffic purchase circuit"
languages="en es fr hi id it ja ko pt pt_BR ru tr zh"

for screen in $screens
do
    for language in $languages
    do
        if [ $screen == 'connect' ]; then
            screen "$device" "$identity" $screen true $language $device_name
        fi
        screen "$device" "$identity" $screen false $language $device_name
    done
done


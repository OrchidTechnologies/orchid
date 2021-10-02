#
# Use the simulator to generate iOS screenshots.
# This should be link and run from the app-flutter build folder (see app-flutter.sh)
#
set -euo pipefail
cd $(dirname "$0")

# See identity.sh.in
. identity.sh

# Replace these with your iOS simulator UUIDs
iphone_12_pro=E0032C1E-9471-40ED-BBF3-2246D270084A
ipad_pro_12_9=94F717A5-FA97-4036-85A8-0D3C0E1545BE

# initDevice(device)
initDevice() {
    device=$1
    echo init $device

    #open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app
    flutter emulators --launch apple_ios_simulator

    if ! xcrun simctl list | grep -i booted | grep -q $device
    then
        echo "Booting $device"
        xcrun simctl boot $device
    fi

    #echo "Installing"
    #xcrun simctl install $device out-sim/Payload/Orchid.app
}

# screen(device, identity, screen, connected, language, filebase)
screen() {
    device=$1
    identity="$2"
    screen=$3
    connected=$4
    language=$5
    filebase=$6

    (sleep 40; 
    echo "Screenshot for: $filebase $identity, $screen, $connected, $language"
    xcrun simctl io $device screenshot "${filebase}_${screen}_${connected}_${language}.png") &

    # Could use this to save time:
    # --use-application-binary=<path/to/app.ipa> 
    # Note that --no-build doesn't work / is deprecated.
    (cd ../../app-flutter;
    (sleep 50; echo 'q') | ../app-shared/flutter/bin/flutter run -d $device \
        --dart-define mock=true \
        --dart-define identity="$identity" \
        --dart-define language=$language \
        --dart-define connected=$connected \
        --dart-define release_notes=false \
        --dart-define hide_prices=true \
        --dart-define screen="$screen"
    )
}

devices="$iphone_12_pro $ipad_pro_12_9"
screens="connect accounts traffic purchase"
languages="en es fr hi id it ja ko pt pt_BR ru tr zh"

#count=$(expr $(echo $screens | wc -w) \* $(echo $languages | wc -w))

for device in $devices
do
    if [ "$device" == "$iphone_12_pro" ]; then device_name='iphone_12_pro'; fi
    if [ "$device" == "$ipad_pro_12_9" ]; then device_name='ipad_pro_12_9'; fi
    initDevice "$device"
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
done



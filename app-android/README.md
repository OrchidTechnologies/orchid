# Orchid Android: Build and Installation


## Setup

Update Android Studio

### Check installed Android SDK versions

`Preferences-> System Settings -> Android SDK`

(Compare with your phone Android version: `Phone settings -> About Phone -> About Software`)


### Install Android NDK

Within Android Studio, navigate to `Preferences -> Appearance & Behavior -> System Settings -> Android SDK`

On the `SDK Tools` tab check the boxes next to:

* LLDB
* NDK (Side by Side)
* CMake

Then click `Apply` and `OK` in the confirmation dialog to install the required components.


### Build
```sh
cd app-android
export ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/<your version>
make
```

This will produce `out-and/Orchid.apk`


### Install

Turn on developer and debugging mode on the phone:

Navigate to `Settings -> About Phone -> About Software` and tap on the build number repeatedly until it prompts you to enable developer mode.

Then go to `Settings -> Developer Settings -> Turn on USB Debugging`.

```sh
PATH=$PATH:"~/Library/Android/sdk/platform-tools"
adb devices # list devices
adb install out-and/Orchid.apk
```


### Problems

**tclsh error**

Install [tclsh](https://www.tcl.tk/man/tcl8.4/UserCmd/tclsh.htm) from [Homebrew](https://brew.sh) with:

```sh
brew install tcl-tk
export PATH="/usr/local/opt/tcl-tk/bin:$PATH”
```

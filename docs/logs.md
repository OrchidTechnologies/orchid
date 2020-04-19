# Gathering Logs

When debugging client-side issues, you might be requested to share logs. These logs provide advanced details about what the Orchid client is doing behind the scenes to provide you with a private browsing experience. This page is designed to help you collect and share the logs.

# Android Prerequisites
Start by turning on developer and debugging mode on the phone by going to `Settings -> About Phone -> About Software` and tapping on the build number repeatedly until it prompts you to enable developer mode. Then go to `Settings -> Developer Settings -> Turn on USB Debugging`. Finally, you can run the following command on your computer with your phone connected via USB to view the logs.

## Android and iOS Prerequisites
When you connect your device to your computer, it will prompt you to trust the computer. It is important that you do so. Otherwise, you will be unable to collect logs.

## Cydia Impactor
The easiest way to gather logs from both iOS and Android devices is through [Cydia Impactor](http://www.cydiaimpactor.com). In the main window, use the select box to pick the correct device (if you only have one mobile device connected to your computer, this will be done for you). Next, go to `Device -> Watch Log...`. A terminal window will appear and it will start to show a streaming syslog from your mobile device.

## adb logcat (Android)
If you are using an Android device, you can alternatively collect logs through the Android Debug Bridge (ADB). You can follow this [guide](https://www.xda-developers.com/install-adb-windows-macos-linux/) to install adb on Windows, macOS, or Linux. Once installed, you can run the following command in a terminal to view the logs:

```
adb logcat
```

## Sanitizing the Logs
The logs you gather will contain information from all applications and actions taken on your device during the period that logs are being gathered. These are not all necessary for debugging purposes. You can optionally filter out all lines that do not contain the string `orchid` as a quick way to sanitize the output. You can do this with a command like:

```
grep -i 'orchid' client.log
```

Where  `client.log` is the file containing the syslog output from the device. You should also be careful to filter out your various secret keys from the logs:

```
grep -vi 'secret' client.log
```

## Sharing the Logs
The logs you gather will be quite long. You almost certainly do not want to paste them in their entirety into something like a Telegram message. Instead, we encourage you to either share them as an attachment via your preferred method of communication. Or if you are using a communication platform that doesn't support attachments, you can utilize a private pastebin service such as [GitHub Gists](https://gist.github.com), which will provide you with a secret URL you can share to grant access to your logs.
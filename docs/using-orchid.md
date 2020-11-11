# Home Screen

Orchid’s home screen is a representation of your device’s Internet connection. The switch in the upper right corner turns Orchid on/off and the middle section allows you to add and delete ‘hops’ which are VPN connections. On the bottom, there are two tabs. One is for Hops, which is the home screen, and the Traffic tab is a network protocol analyzer that allows you to see information about your phone's network connections.

The simplest configuration for Orchid is to use just one VPN connection. When configured with one hop, Orchid is similar to a typical VPN app, which can only connect to one VPN server at a time. Websites that you visit will then see the IP address and details of the VPN server as opposed to the IP address associated with your device. 

When you add multiple connections, Orchid uses layered encryption to route your traffic through each connection. If a multiple hop route is constructed, traffic flows through the hops from the top to the bottom. The Orchid app supports Orchid VPN connections as well as typical OpenVPN connections. 

Add a hop by clicking on the Add Hop button in the middle of the screen and then going to the hop selection screen. To delete a hop, swipe it to the right or left.

Each hop to an Orchid node requires an Orchid account to pay for service. Read more about how to setup an Orchid account.

For more information about Orchid in general, read the About Orchid section. For information on what kinds of protections Orchid provides, read the Security and Privacy section.

# Hops

Orchid ‘hops’ are vpn connections to the Internet. Examples include a connection to an Orchid node or an OpenVPN connection to a VPN server. You can add and delete hops from the homescreen. Each hop will need a form of authentication to make the server connection. 

Add a hop by clicking on the Add Hop button from the home screen and then selecting a way to add the hop. To add an Orchid hop, select "I have a QR code" if you generated a QR code from your Orchid account or select “I have an Orchid account” to manually input your Ethereum wallet address and generate a signing key that you can put into the app. To add an OpenVPN hop, select “I have an existing VPN subscription” and input the credentials.

## OpenVPN hops

Orchid supports OpenVPN. If you have an existing VPN provider, you can add a hop using OpenVPN credentials. To add an OpenVPN hop, click Add Hop -> I have an existing VPN subscription. Then enter your username, password and paste in the configuration for your OpenVPN connection.

## Orchid hops

Orchid has its own VPN wireline protocol, the Orchid protocol. The traffic to and from Orchid nodes uses the Orchid protocol. The traffic looks like webRTC traffic, which is advantageous for security and includes tiny nanopyments that flow with the traffic.

Each Orchid node also has a curator — this is the curated list that is associated with the hop. When a connection is initiated, the curator creates a subset of the available Orchid nodes for the hop to create the connection. 

The main component of the Orchid node is going to be the Orchid account associated with it. Each hop requires a valid Orchid account to continue to pay for VPN service.

## Linking  an Orchid Account

To add an Orchid account, open the app and select "New Hop" on the homescreen and then "Link Orchid Account" from the add hop screen. Scan or copy/paste the code into the app.

Once you scan the QR code, the app will create a hop using that Orchid account and your default curator settings. You will then be dropped into the hop information screen that shows the saved information. Using the "Share Orchid Account" button, you can pop a QR code and share the Orchid account you just created with other people or devices. Press the back arrow to get back to the main screen. 

From the main screen, turn the toggle in the upper right to turn Orchid on.

# Config Import/Export

## Hop Configuration
A configuration specifying all details needed to connect to a single Orchid hop. It begins with `account = ...`

## Export
To export a hop configuration, you must first add and configure a 'New Hop' within the Orchid iOS or Android application. Once this is complete, select the hop from the main screen. Scroll down and click the purple 'Share Orchid Account' button. This will display a prominant QR code representation of the Hop Configuration that you can scan and import from a different device. Running the QR code through any decoder will reveal the raw configuration contained within.

## Import
From the main screen within the Orchid iOS or Android application, select `New Hop -> I have a QR code`. You can then click the purple `Scan` button to quickly scan and import a Hop Configuration QR code. Alternatively, if you have the raw Hop Configuration, copy it to your device's clipboard and click the `Paste` button.


# Complete Configuration (Hops Configuration)
A configuration made up of the hop configurations for all hops setup within the application.  It begins with `hops = ...`

## Export
From within the Orchid iOS or Android application, open the hamburger menu (`☰`) in the top left corner. Next, go to `Settings -> Manage Configuration (beta) -> Export`. This will display the raw complete configuration (hops configuration). You can copy it to your device's clipboard using the purple `Copy` button at the bottom. Alternatively, you can produce a QR Code representation by clicking the QR Code button immediately to the left of the `Copy` button.

## Import
From within the Orchid iOS or Android application, open the hamburger menu (`☰`) in the top left corner. Next, go to `Settings -> Manage Configuration (beta) -> Import`. You can either paste the raw configuration into the text field or click on the QR Code button at the bottom to scan a QR Code representation of the configuration. After doing so, click the `Import` button to save. Note that this will overwrite all existing configured hops within the application.

# Gathering Logs

When debugging client-side issues, you might be requested to share logs. These logs provide advanced details about what the Orchid client is doing behind the scenes to provide you with a private browsing experience. This page is designed to help you collect and share the logs.

## Android Prerequisites
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
# Quick Setup

To run Orchid with the decentralized network of providers, you will need an Orchid account first. Access to an Orchid account is a requirement, as that is the payment account that pays the providers. Once you have an account, you can then set up the profile (typically done automatically) and hit the connect button to get VPN service.

## Access an Orchid account

See set up an Orchid account on how to buy, create or get access to an Orchid account.

## Add the Orchid account to profile

The Orchid account can be added to the client app by either scanning the QR code, or copy/pasting the account into the app. Look for the “Copy” button next to the QR code in the dApp which will copy the text of the account into your clipboard. If someone shares an account purely by text, you can also copy the account to the clipboard by highlighting the text of the account and hitting copy.

Once you have the account information via QR or text, you can then go to Manage Profile -> New Hop -> Link Orchid Account which brings up the interface to either scan the QR code, or paste in the text from the clipboard.

## Connecting

After attaching the account, you will end up back at the Home screen and can tap Connect to connect to one of the decentralized VPN providers. If there is a problem with an Orchid account used in the profile, a red exclamation mark will appear in the Manage Profile button. If this mark appears, the app will not be able to connect successfully to a provider. Read the Orchid account troubleshooting guide for help.

After tapping connect, the Orchid app will do a number of things:
* Show the “Connecting” status
* Stop all internet traffic across the device (kill switch)
* Go through the stake-weighted random selection to find a provider
* Check to ensure that provider is in the Curator
* Connect to the provider
* If an error is hit, go back to 2 and re-try
* Change the status from “Connecting” to “Connected” and change the screen state from white to purple

Note that this process can sometimes take a few minutes, depending on the status of Orchid’s providers. It is also possible to connect to a server, have the screen change states, and then have the connection die. Typically turning the app off/on can help kickstart the reconnect process whenever you experience no connectivity.

# Key concepts

## Orchid Accounts

To access the Orchid network of providers, you need either Orchid Credits purchased with your native currency within the Orchid App (iOS/macOS only), or an Orchid Account created and funded using crypto currency with the dApp at account.orchid.com

Credits can be purchased in the iOS or macOS app by hitting ‘Buy Orchid Credits’ in the notification area, or by going to ‘Manage Profile’, ‘New Hop’, and then ‘Buy Orchid Account’. While Orchid Credits are simpler to set up, creating an Orchid account using the dApp gives more control over the account, as purchased accounts are limited: there is no way to top-up, fix small deposits or to withdraw the funds from a purchased account.

Jump to [Orchid Accounts](../accounts/) for more information.

## Hops

Orchid ‘hops’ are VPN connections to the Internet. Examples include a connection to an Orchid node or an OpenVPN connection to an OpenVPN server. You can add and delete hops from the ‘Manage Profile’ screen within the Orchid App. Each hop will need a form of authentication to make a server connection. When multiple hops are added, internet traffic for the device goes through each server from top to bottom.

To add a hop in the Orchid Client, go to ‘Manage Profile’ and click ‘New Hop’. From here, you can choose to:
* Buy an Orchid Account (iOS/macOS only feature)
* Link an Orchid Account
* Create a Custom Account (Android only feature)
* Enter an OpenVPN config using your credentials
* Enter a WireGuard config

Orchid has its own VPN wireline protocol, the Orchid protocol. The traffic to and from Orchid nodes uses the Orchid protocol. The traffic appears as webRTC traffic, which is advantageous for security and includes tiny nanopyments that flow with the traffic.

Each Orchid node also has a Curator — this is the curated list that is associated with the hop. When a connection is initiated, the Curator creates a subset of the available Orchid nodes for the hop to create the connection.

The main component of the Orchid node is the Orchid account associated with it. Each Orchid hop requires a valid Orchid account to continue to pay for VPN service.

## Profile Manager

To access the profile manager, hit ‘Manage Profile’ on the Orchid home / status screen. 

The profile manager is used to organize hops into the “profile” that your device will use to connect to the Internet. A typical VPN user only needs one hop. Hops can be mixed and matched here to form your own custom-styled circuits. For example, you could configure a profile with three different Orchid hops, so that your Internet traffic passes through three different servers between your device and the server you are accessing. 

On this screen, you’ll also see ‘View Deleted Hops’ at the bottom. This is an easy way to restore recently removed hops.

There is currently no way to save profiles, nor an easy way to switch between them. The profile manager allows you to only modify the active profile at any given time. If you delete hops, they are still saved and available to be restored.

# How to create an Orchid hop

To use Orchid's decentralized providers, you will need to add an Orchid hop to your profile. The WireGuard and OpenVPN options are for making connections to existing servers where you have login credentials. 

Orchid hops will use the attached Orchid account to send payments and then connect to a random provider on the network.

From the Manage Profile screen, tap "New Hop" and then select an option:

## Buy an Orchid account (iOS/macOS only)

In the iOS and macOS app, you can simply buy a pre-created Orchid account. These accounts come in 3 different sizes and are pre-filled with funds. The purchased accounts can only connect to our list of [preferred providers](https://www.orchid.com/preferredproviders).

Purchased accounts are custodied by Orchid. There is no current way to add funds to them. Email contact@orchid.com for help with purchased accounts.

## Linking an Orchid account

If you have created an Orchid account in the dApp, you can tap Link Orchid Account to simply scan in the QR code. The other option is to copy the text of the account into your clipboard and then tap the Paste option to read in the account that way.

Orchid accounts are shareable, so if your friend sends you a QR code or the text of their account, you can link the account and use it by using the Link Orchid Account option.

## Create a custom account

The custom account option is in the Android app only. With this option you can generate a signer key and use that with your funder wallet to fund the account in the dApp. 

To create a custom account:
* Tap Create Custom Account from the New Hop menu
* Paste in the public address of your funder wallet
* Select "Generate new key"
* Tap Save in the upper right
* Tap the Orchid hop from the Profile Manager
* Tap Copy next to the signer address
* Paste the signer address into the dApp on the [Create Account](../orchid-dapp/#create-account/) flow

The last step will fund the empty account that was created in the app.

# How to restore deleted hops

To restore deleted hops, go to ‘Manage Profile’ from the home / status screen. At the bottom you’ll see a link to ‘View Deleted Hops’.

You’ll need to:
* Click into the hop you want to restore
* Hit ‘Share Orchid Account’ and hit ‘Copy’
* Return to the ‘Manage Profile’ screen, click ‘New Hop’ then ‘Link Orchid Account’ and ‘Paste’
* Your deleted hop will now appear at the bottom of your list of hops

# A note on multiple hops

Orchid supports the use of multiple hops, allowing your Internet connection to be routed through an arbitrary number of VPN servers before reaching its destination. For more information about the implications of multiple hops, refer to the FAQ section on Security.

Different protocols can be used with the multiple hop feature. For example, you could set up your traffic to go to three different Orchid servers, three different WireGuard servers or a combination therein. 

# Using traditional VPN connections

## OpenVPN

To use an OpenVPN hop, you’ll need your username, password and configuration file from your VPN provider. You can usually find these in your provider VPN account under manual configuration or OpenVPN configuration.

To use your OpenVPN configuration, go to ‘Manage Profile’ and ‘New Hop’ then ‘Enter OpenVPN Config’.

## WireGuard

To use your OpenVPN configuration, go to ‘Manage Profile’ and ‘New Hop’ then ‘Enter WireGuard Config’.

Paste your WireGuard configuration into the text box and tap save in the upper right corner. The WireGuard account will now become an active hop available at the manage profile screen.

# Using the traffic monitor

Orchid has a built-in traffic monitor that can run with or without an Orchid account. Using the traffic monitor is similar to WireShark--and Orchid works on iOS! The traffic monitor also works across every platform that Orchid supports.

There are two ways to enable the traffic monitor:
* If you have a connection with at least one hop set up, when your connection is active you will be able to use the traffic monitor
* If you have no hops set up, you can go to ‘Settings’ and then you can enable ‘Allow No Hop VPN’

Once it’s enabled, you can find the traffic monitor from the home screen by opening the menu from the icon on the top left of the screen. ‘Traffic Monitor’ is at the bottom of the menu.

## Filters

Enter a hostname or partial hostname into the search bar to show only matching rows.
Enter multiple terms separated by a space to combine hostname filters using “AND” logic.  e.g. “goog api” will match rows including both “goog” and “api”, such as “api1.google.com”.
Use a “-” minus sign to exclude terms.  e.g. “-goog” will show all hostnames *except* those matching “goog”.  You can mix these to include and exclude combinations such as: “google -api” to find all “google” entries excluding those with “api”.
Use “prot:<name of protocol>”to filter by protocol name.  e.g. “prot:imap” will match all traffic identified as “imap” connections and  “-prot:dns” will filter out all DNS queries from the results.

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

# Orchid App troubleshooting/FAQs

## Help, my Internet connection shut off after I turned Orchid on

Orchid has a built-in “kill switch” and so turning Orchid on will destroy all existing connections to the Internet and force them to go through Orchid. If Orchid is trying to connect, the Internet will be shut off until a connection is established. This is a feature that ensures that none of your Internet traffic will accidentally leak due to a disconnect/reconnect without you pressing the button first. This ensures that when you hit “connect” your traffic is now only going through Orchid.

Read [Connecting](../using-orchid/#connecting) for more information on exactly what happens when you hit connect.

## I can’t find my QR code after making an account

When the QR code or text of an account is truly lost, the account is lost as well. If the account was ever added to the Orchid app, the account should appear under View Deleted hops from the Manage Profile screen.

The funds are NOT LOST! To recover the funds from a lost account, you will need to [withdraw the funds](../orchid-dapp/#withdraw) from that Orchid account using the dApp and the funder wallet used to create the account. 

## Low balance/deposit/efficiency warning

Under certain market conditions, users need to increase the size of their deposit. The market conditions are primarily driven by the price of the currency and the amount of network fees required for the provider to claim a ticket. The face value of the ticket needs to be large enough for it to be profitable to pay the network fees to grab it. 

To fix this, see [Deposit size too small](../accounts/#deposit-size-too-small)
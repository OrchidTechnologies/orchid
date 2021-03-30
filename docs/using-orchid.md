# Using the Orchid app

## Quick Setup

To connect to an Orchid provider, you will need an Orchid account with enough funds in the balance and deposit for a provider to accept payment from that account.  Once you buy, import, or create an account you can then make it active and hit the connect button to connect to a VPN provider. 

Orchid accounts live in the Manage Accounts screen and are listed underneath an [Orchid address](../#orchid-address). 

There are three ways to get an Orchid account:

### Importing Accounts

To import existing Orchid accounts, you can go to the cog wheel next to Orchid Address -> Import which brings up the interface to either scan the QR code, or paste in the text of an Orchid key from the clipboard. That will import all the accounts associated with that key's address.

### Create an Orchid account with crypto

To create an account you will need a wallet (we recommend [Metamask's Chrome plug-in](https://metamask.io/)) and the appropriate funds for the blockchain that you want to house the account. 

The Orchid address and key are held in the app. To create an account with crypto, you will need the address from the app. Tapping on the number underneath the icon on the Manage Accounts screen will copy the address to your clipboard. Paste this information into the Address form field on the [dApp](https://account.orchid.com/), connect your wallet and then transfer crypto to create an account.

Learn more about how to [create an account](../orchid-dapp/#create-account) in the Orchid dApp.

### Buy an Orchid account

In the iOS and macOS app, you can simply buy a pre-created Orchid account filled with [xDai](../#xdai), by tapping 'Add Credit' from the accounts screen. These accounts come in 3 different sizes. The purchased accounts can only connect to our list of [preferred providers](https://www.orchid.com/preferredproviders).

To add funds to an account that has a low balance, simply tap the 'Add Credit' button again with that Orchid address selected.

### Connecting

After buying, creating or importing your account, you will need to make one of the accounts active which means when you connect, you will start making nanopayments on the Orchid network. 

Once you have an active account, your home screen will show the available balance and the current cost of bandwidth below the connect button. You can then tap Connect to connect to one of the decentralized VPN providers. If there is a problem with an Orchid account used in the profile, a red exclamation mark will appear next to the balance of the account. If this mark appears, the app will not be able to connect successfully to a provider. Read the Orchid account troubleshooting guide for help.

After tapping connect, the Orchid app will do a number of things:

* Show the “Connecting” status
* Stop all internet traffic across the device (kill switch)
* Go through the stake-weighted random selection to find a provider
* Check to ensure that provider is in the Curator
* Connect to the provider
* If an error is hit, re-try
* Change the status from “Connecting” to “Connected” and change the screen state from white to purple

Note that this process can sometimes take a few minutes, depending on the status of Orchid’s providers. It is also possible to connect to a server, have the screen change states, and then have the connection die. Typically turning the app off/on can help kickstart the reconnect process whenever you experience no connectivity.

## Key concepts

### Orchid Address

An Orchid Address will be created for you the first time you use the Orchid app. On a single Orchid Address, you can buy and create multiple Orchid Accounts which will appear in a list.

You can also copy your Orchid Address (by clicking on the number below where it says 'Orchid Address' with an icon) and use it to create an Orchid Account funded using crypto currency by pasting it into the Signer Address field on the Create New Account page on the dApp at account.orchid.com

### Orchid Accounts

To access the Orchid network of providers, you need either Orchid Credits purchased with your native currency within the Orchid App (iOS/macOS only), or an Orchid Account created and funded using crypto currency with the dApp at account.orchid.com

Credits can be purchased in the iOS or macOS app by going to Manage Accounts then Add Credit. While Orchid Credits are simpler to set up, creating an Orchid account using the dApp gives more control over the account.

Learn more about [Orchid accounts](../accounts/).

### xDai

The xDai chain is The xDai chain is a stable payments blockchain designed for fast and inexpensive transactions. Orchid accounts created on xDai are viewable using the [BlockScout Explorer](https://blockscout.com/xdai/mainnet). 

Having Orchid accounts denominated in USD is beneficial for users as VPN providers charge for service in USD. xDai Orchid accounts are not subject to exchange risk such as accounts filled with other crypto currencies.

Learn more about [xDai](https://www.xdaichain.com/). 

## Using the multi-hop interface

In order to continue using multi-hop, OpenVPN or WireGuard you will need to go to settings and 'Enable Multi-hop' which will switch back to an older version of the interface. In future releases, we will re-unify this interface to be compatible with the way we handle accounts on multiple chains. The following information in this section is relevant only if you have enabled multi-hop and want to use Orchid in a multi-hop mode.

### Profile Manager (multi-hop interface)

To access the profile manager, hit ‘Manage Profile’ on the Orchid home / status screen. 

The profile manager is used to organize hops into the “profile” that your device will use to connect to the Internet. A typical VPN user only needs one hop. Hops can be mixed and matched here to form your own custom-styled circuits. For example, you could configure a profile with three different Orchid hops, so that your Internet traffic passes through three different servers between your device and the server you are accessing. 

On this screen, you’ll also see ‘View Deleted Hops’ at the bottom. This is an easy way to restore recently removed hops.

There is currently no way to save profiles, nor an easy way to switch between them. The profile manager allows you to only modify the active profile at any given time. If you delete hops, they are still saved and available to be restored.

### Adding a hop (multi-hop interface)

To use Orchid's decentralized providers, you will need to add an Orchid hop to your profile. The WireGuard and OpenVPN options are for making connections to existing servers where you have login credentials. 

Orchid hops will use the attached Orchid account to send payments and then connect to a random provider on the network.

From the Manage Profile screen, tap "New Hop" and then select an option:

### Linking an Orchid account (multi-hop interface)

If you have created an Orchid account in the dApp, you can tap Link Orchid Account to simply scan in the QR code. The other option is to copy the text of the account into your clipboard and then tap the Paste option to read in the account that way.

Orchid accounts are shareable, so if your friend sends you a QR code or the text of their account, you can link the account and use it by using the Link Orchid Account option.

### How to restore deleted hops (multi-hop interface)

To restore deleted hops, go to ‘Manage Profile’ from the home / status screen. At the bottom you’ll see a link to ‘View Deleted Hops’.

You’ll need to:

* Click into the hop you want to restore
* Hit ‘Share Orchid Account’ and hit ‘Copy’
* Return to the ‘Manage Profile’ screen, click ‘New Hop’ then ‘Link Orchid Account’ and ‘Paste’
* Your deleted hop will now appear at the bottom of your list of hops

### A note on multiple hops (multi-hop interface)

Orchid supports the use of multiple hops, allowing your Internet connection to be routed through an arbitrary number of VPN servers before reaching its destination. For more information about the implications of multiple hops, refer to the [FAQ section on Security](../faq/#security-and-privacy).

Different protocols can be used with the multiple hop feature. For example, you could set up your traffic to go to three different Orchid servers, three different WireGuard servers or a combination therein. 

### OpenVPN (multi-hop interface)

To use an OpenVPN hop, you’ll need your username, password and configuration file from your VPN provider. You can usually find these in your provider VPN account under manual configuration or OpenVPN configuration.

To use your OpenVPN configuration, go to ‘Manage Profile’ and ‘New Hop’ then ‘Enter OpenVPN Config’.

### WireGuard (multi-hop interface)

To use your OpenVPN configuration, go to ‘Manage Profile’ and ‘New Hop’ then ‘Enter WireGuard Config’.

Paste your WireGuard configuration into the text box and tap save in the upper right corner. The WireGuard account will now become an active hop available at the manage profile screen.

## Using the traffic monitor

Orchid has a built-in traffic monitor that can run with or without an Orchid account. Using the traffic monitor is similar to WireShark--and Orchid works on iOS! The traffic monitor also works across every platform that Orchid supports.

There are two ways to enable the traffic monitor:

* If you have a connection with at least one hop set up, when your connection is active you will be able to use the traffic monitor
* If you have no hops set up, you can go to ‘Settings’ and then you can enable ‘Allow No Hop VPN’

Once it’s enabled, you can find the traffic monitor from the home screen by opening the menu from the icon on the top left of the screen. ‘Traffic Monitor’ is at the bottom of the menu.

### Filters

Enter a hostname or partial hostname into the search bar to show only matching rows.
Enter multiple terms separated by a space to combine hostname filters using “AND” logic.  e.g. “goog api” will match rows including both “goog” and “api”, such as “api1.google.com”.
Use a “-” minus sign to exclude terms.  e.g. “-goog” will show all hostnames *except* those matching “goog”.  You can mix these to include and exclude combinations such as: “google -api” to find all “google” entries excluding those with “api”.
Use “prot:<name of protocol>”to filter by protocol name.  e.g. “prot:imap” will match all traffic identified as “imap” connections and  “-prot:dns” will filter out all DNS queries from the results.

## Gathering Logs

When debugging client-side issues, you might be requested to share logs. These logs provide advanced details about what the Orchid client is doing behind the scenes to provide you with a private browsing experience. This page is designed to help you collect and share the logs.

### Android Prerequisites
Start by turning on developer and debugging mode on the phone by going to `Settings -> About Phone -> About Software` and tapping on the build number repeatedly until it prompts you to enable developer mode. Then go to `Settings -> Developer Settings -> Turn on USB Debugging`. Finally, you can run the following command on your computer with your phone connected via USB to view the logs.

### Android and iOS Prerequisites
When you connect your device to your computer, it will prompt you to trust the computer. It is important that you do so. Otherwise, you will be unable to collect logs.

### Cydia Impactor
The easiest way to gather logs from both iOS and Android devices is through [Cydia Impactor](http://www.cydiaimpactor.com). In the main window, use the select box to pick the correct device (if you only have one mobile device connected to your computer, this will be done for you). Next, go to `Device -> Watch Log...`. A terminal window will appear and it will start to show a streaming syslog from your mobile device.

### adb logcat (Android)
If you are using an Android device, you can alternatively collect logs through the Android Debug Bridge (ADB). You can follow this [guide](https://www.xda-developers.com/install-adb-windows-macos-linux/) to install adb on Windows, macOS, or Linux. Once installed, you can run the following command in a terminal to view the logs:

```
adb logcat
```

### Sanitizing the Logs
The logs you gather will contain information from all applications and actions taken on your device during the period that logs are being gathered. These are not all necessary for debugging purposes. You can optionally filter out all lines that do not contain the string `orchid` as a quick way to sanitize the output. You can do this with a command like:

```
grep -i 'orchid' client.log
```

Where  `client.log` is the file containing the syslog output from the device. You should also be careful to filter out your various secret keys from the logs:

```
grep -vi 'secret' client.log
```

### Sharing the Logs
The logs you gather will be quite long. You almost certainly do not want to paste them in their entirety into something like a Telegram message. Instead, we encourage you to either share them as an attachment via your preferred method of communication. Or if you are using a communication platform that doesn't support attachments, you can utilize a private pastebin service such as [GitHub Gists](https://gist.github.com), which will provide you with a secret URL you can share to grant access to your logs.

## Orchid App troubleshooting/FAQs

### Help, my Internet connection shut off after I turned Orchid on

Orchid has a built-in “kill switch” and so turning Orchid on will destroy all existing connections to the Internet and force them to go through Orchid. If Orchid is trying to connect, the Internet will be shut off until a connection is established. This is a feature that ensures that none of your Internet traffic will accidentally leak due to a disconnect/reconnect without you pressing the button first. This ensures that when you hit “connect” your traffic is now only going through Orchid.

Read [Connecting](../using-orchid/#connecting) for more information on exactly what happens when you hit connect.

### I can’t find my QR code after creating an account in the dApp

When the QR code or text of an account is truly lost, the account is lost as well. If the account was ever added to the Orchid app, the account should appear under the cog wheel next to your Orchid Address. (Or in the old, multi-hop interface 'View Deleted hops' on 'Manage Profile'.)

The funds are NOT LOST! To recover the funds from a lost account, you will need to [withdraw the funds](../orchid-dapp/#withdraw) from that Orchid account using the dApp and the funder wallet used to create the account. 

### Low balance/deposit/efficiency warning

Under certain market conditions, users need to increase the size of their deposit. The market conditions are primarily driven by the price of the currency and the amount of network fees required for the provider to claim a ticket. The face value of the ticket needs to be large enough for it to be profitable to pay the network fees to grab it. 

To fix this, see [Deposit size too small](../accounts/#deposit-size-too-small)

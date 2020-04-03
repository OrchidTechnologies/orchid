# Configs

## Hop Configuration
A configuration specifying all details needed to connect to a single Orchid hop. It begins with `account = ...`

### Export
To export a hop configuration, you must first add and configure a 'New Hop' within the Orchid iOS or Android application. Once this is complete, select the hop from the main screen. Scroll down and click the purple 'Share Orchid Account' button. This will display a prominant QR code representation of the Hop Configuration that you can scan and import from a different device. Running the QR code through any decoder will reveal the raw configuration contained within.

### Import
From the main screen within the Orchid iOS or Android application, select `New Hop -> I have a QR code`. You can then click the purple `Scan` button to quickly scan and import a Hop Configuration QR code. Alternatively, if you have the raw Hop Configuration, copy it to your device's clipboard and click the `Paste` button.


## Complete Configuration (Hops Configuration)
A configuration made up of the hop configurations for all hops setup within the application.  It begins with `hops = ...`

### Export
From within the Orchid iOS or Android application, open the hamburger menu (`☰`) in the top left corner. Next, go to `Settings -> Manage Configuration (beta) -> Export`. This will display the raw complete configuration (hops configuration). You can copy it to your device's clipboard using the purple `Copy` button at the bottom. Alternatively, you can produce a QR Code representation by clicking the QR Code button immediately to the left of the `Copy` button.

### Import
From within the Orchid iOS or Android application, open the hamburger menu (`☰`) in the top left corner. Next, go to `Settings -> Manage Configuration (beta) -> Import`. You can either paste the raw configuration into the text field or click on the QR Code button at the bottom to scan a QR Code representation of the configuration. After doing so, click the `Import` button to save. Note that this will overwrite all existing configured hops within the application.
# **How Orchid’s Layer 2 Works**

## **Accounts**

Orchid accounts are the center of Orchid’s layer 2 nanopayment system, which allows the decentralized VPN application to function. To use the VPN application, you will need access to an Orchid account.

The Orchid accounts hold the funds that pay providers through the nanopayment system; users are responsible for managing those accounts on the blockchain. Each account has its own public/private keypair, a special funder wallet that controls the account, and the account makeup (deposit & balance), which determines how efficient the account is at transmitting payments.

## **How to get an Orchid account**

* Purchase an account (iOS/macOS/Android only feature) funded by Orchid
* [Create](https://docs.orchid.com/en/latest/orchid-dapp/#creating-an-account) and fund your own Orchid account using the Orchid dApp

### **Purchased Orchid accounts (iOS/macOS/Android)**

In the Orchid Android, iOS and macOS apps, it is possible to simply purchase an Orchid account from Orchid Labs with prepaid access credits using an in-app purchase. These are distinct from Orchid accounts created in the dApp and have the following properties:

* Purchased accounts connect only to [preferred providers](https://www.orchid.com/preferredproviders) for VPN service.
* It is not possible to transfer the crypto out of a purchased Orchid account in the same way as an account created in the dApp.
* Accounts are created on the xDAI blockchain and are denominated in the xDAI stablecoin.

Orchid takes your in-app purchase funds and adds the equivalent xDAI to the selected Orchid address on the xDAI blockchain. Your balance and deposit will increase by the amount of USD purchased.

## **Orchid account efficiency**

Orchid’s nanopayments work on a simple principle: instead of giving your provider $1 one hundred times, it’s better for you to give them 100 scratch-off tickets with a 1% chance of winning $100. That way, even though the provider still receives $100 on average, you only pay for one transaction, instead of one hundred.The transmitted value is determined by comparing the amount of the total ticket value to the value lost to transaction fees; if your ticket was worth $100 and the L1 network fees to process the transaction cost $10, your ticket has a 90% efficiency to the provider.

When the efficiency of an account drops below 0%, providers will no longer accept payments from that account, because the network fees are greater than the amount of value they could receive from a winning ticket. 

There are two major factors that affect efficiency:

* The size of the deposit, which determines the face value of the tickets
* The network fees for the L1 blockchain that houses the account at a given moment

### **Efficiency example**

Imagine an Orchid account with a 10 xDAI deposit. The account will issue tickets with a 5 xDAI face value; therefore, providers get a tiny chance at “winning” 5xDAI with each ticket they accept for service. Providers must pay the network fee to claim the 5 xDAI; so, the provider queries the current L1 network fee and makes sure the fee is not greater than 5 xDAI. When the network fees the provider pays to claim the fees are greater than 5 xDAI ticket value, the provider does not accept payments from that account, as that account has a &lt;0% efficiency.

## **Deposit**

The deposit is required to accept service and is verified by providers. The deposit prevents double spending, and in general, the deposit maintains good standing on the network.

The size of the deposit determines the face value of the tickets sent from the user to the provider. The face value refers to the amount of funds that a provider claims when they receive a winning off-chain nanopayment; currently, the face value is set to half the value of the deposit.

When an Orchid account is funded, the deposit is “locked” and cannot be withdrawn from the account until it is “unlocked” and the requisite 24-hour cool-off period has passed.

### **Size of deposit**

Market conditions are constantly changing, which includes fluctuations in network fees. When the account efficiency gets low, it is a good idea to add additional funds to your deposit to increase the efficiency. We recommend a minimum deposit that sets your ticket value to 90% efficiency; consult our [chart](https://account.orchid.com/widget) for more information on recommended amounts.

## **Balance**

The balance of the Orchid account is the amount of currency held to pay providers. When the account is in use, the tickets are backed by funds in the balance. When a ticket “wins”, the face value of the ticket is withdrawn from the user’s account balance and deposited into the provider’s account with an on-chain transaction.

As a practical matter, while using Orchid, you may notice that the balance remains unchanged for long periods of time; this is because you can sometimes receive significant amounts of bandwidth before a payment ticket “wins”, funds are claimed, and your balance is adjusted.

The balance of an Orchid account can be thought of as a number of tickets. The size of the ticket is governed by the deposit, as the network requires two tickets worth of deposit for payments to be accepted. So if the account’s deposit size is 10 xDAI, and there is 15 xDAI in the balance, because the size of each ticket is 5 xDAI (deposit / 2) there are 3 tickets worth of balance (total balance / ticket size).

The dApp has an [Add Funds](https://docs.orchid.com/en/latest/orchid-dapp/#add-funds-tab) screen to add additional balance to your account.

### **Tickets**

A ticket is a nanopayment sent from a user to a provider to pay for service. The ticket has a probability of winning along with a face value, which is the amount of currency the provider receives if the ticket “wins”.

The face value of a ticket is set at half of the deposit in the Orchid account. While this is hard coded in the app right now, in the future the face value of tickets could vary, depending on market conditions and to optimize for variance. However, the upper limit of ticket size is governed by the deposit, and the max ticket size is always half of the deposit.

Orchid accounts with very few tickets will experience a high amount of variance due to the nature of probability.

### **Variance**

There is an important concept to consider when using Orchid: _variance_. Since tickets have a probability of a win, it is possible that a winning ticket will be claimed either faster or slower than is expected.

For a quick example, imagine you have an Orchid account with one ticket worth of balance. As you start using the service, you get “unlucky”, and a winning ticket is issued immediately; your balance then goes to zero, and you will need to add funds. This is an example of not getting what you expect due to variance. The inverse can also happen: that is, you may receive much more service than expected because your winning ticket is not getting pulled.

To combat variance, Orchid accounts need more tickets worth of service. That way, the probability of a winning ticket being issued before or after you would expect is mitigated. As of now, Orchid recommends at least four tickets worth of service in your account balance.

## **Technical parts of an Orchid account**

The makeup of an Orchid account is important for understanding how to manage it, and how the different components work together. Ultimately, the technical details of the account are dictated by the nanopayment smart contract, which holds the funds and allows users to interact with their accounts.

### **The Orchid funder wallet**

The funder wallet is a blockchain address that corresponds to the wallet address that funded the account. The owner of that wallet has complete control over the Orchid account and can add or remove funds, along with all the other operations available in the Orchid account manager.

Simply put, the funder wallet is the custodian of the Orchid account. Without the keys to the funder wallet, no functions can be performed on the account, such as adding/removing funds, unlocking/locking the deposit and moving funds between balance and deposit.

If the keys to a funder wallet are lost, the associated Orchid account will still function, but the user cannot add funds, remove funds or make any changes to the account. You will be able to use the account while it’s efficiency is above 0%, until the balance is reduced to zero. If the deposit is lost, and the account efficiency drops below 0%, there is no way to add to the deposit.

### **The Orchid address and key**

An Orchid account utilizes its own keypair: the layer 1 funder wallet address, and the layer 2 Orchid identity key.

The public portion of the keypair is the address used when funding the Orchid account. The transaction that moves funds from the funder wallet into the nanopayment contract requires the funds be linked to an Orchid address. In the Orchid dApp, the address is required before a new Orchid account can be created; you can copy your Orchid Address in the app, and paste that in the signer address field in the dApp to create an account.

The private portion of the key or “secret” is used by the client to sign tickets. The key is therefore a core technical property of the Orchid account; it is the important bit of information that is shared when an Orchid account is shared between people or devices.

The keypair is generated in the app. To create a new keypair, go to “Manage Accounts”, tap on the cog wheel, and select “New Identity”. The Orchid address will be displayed next to an identicon and can be copied over to the dApp to add an Orchid account to this address. Then, you can export the key by selecting “Export Identity” and have access to any accounts with that address.

### **Sharing Orchid accounts**

There’s no limit to the number of people or devices that a single Orchid account can be shared with. The account is specified by the L1 funder wallet address, the L2 identity key, and the chain the account is funded on. To share an account, go to “Manage Accounts”, tap on the cog wheel, and select “Export Identity”. A QR code encoding this information will appear, as well as a Copy button. The account information is displayed under the QR code, and can be copied and directly pasted into the client app as text. Also note the L1 chain the account was funded upon; as Orchid has expanded to multiple partnerships with chains, the functionality to automatically determine the originating chain for each wallet has encountered difficulties. So, to share accounts, it is important to select the correct chain to properly access the Orchid account.

## **Orchid Account Troubleshooting**

### **Deposit size too small**

Both the Orchid client app and the Orchid web dApp will display a warning when the Orchid account efficiency or balance is too low for usage. There are a few solutions when you see this error:

**For in-app purchased accounts (Android/iOS/macOS only feature):** Tap on the warning to go into the selected account. Simply use “Add Credit” to increase the balance and deposit with an in-app purchase. Do not try to fix purchased accounts in the dApp; only manage purchased accounts using in-app purchases.

**For Orchid accounts created with the dApp:** The Orchid dApp can add funds to the account’s deposit, which will improve the Orchid account efficiency and eliminate the warning, allowing the app to start working. To add funds, connect the funder wallet used to create the Orchid account and click on the “Add Funds” tab.

### **What is the difference between Balance and Deposit in my Orchid Account?**

The [balance](https://docs.orchid.com/en/latest/accounts/#balance) is the collateral for the tickets sent from the user to the provider. Over time, as winning tickets are issued from your Orchid app, the Orchid account balance will decrease. The [deposit](https://docs.orchid.com/en/latest/accounts/#deposit) is the Orchid token held in escrow; this amount never depletes and can be withdrawn after the 24-hour "unlock" period.

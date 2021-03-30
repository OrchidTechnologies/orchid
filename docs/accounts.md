# Orchid Accounts

## What are accounts
Orchid accounts are the center of the payment system that allows Orchid’s decentralized VPN application to function. To use the VPN application, you will need access to an Orchid account.

The Orchid accounts hold the funds that pay providers through the nanopayment system and users are responsible for managing those accounts on the blockchain. Each account has its own public/private keypair, a special funder wallet that can control the account and the account makeup (deposit & balance), which determines how efficient the account is at transmitting payments.

## How to get an Orchid account

* Purchase an account (iOS/macOS only feature) custodied by Orchid
* [Create](../orchid-dapp/#create-account) and self-custody an Orchid account using the Orchid dApp
* [Access an account](../accounts/#Sharing-orchid-accounts) that was shared with you

### Purchased Orchid accounts (iOS/macOS only feature)

In the Orchid iOS and macOS apps, it is possible to simply purchase an Orchid account from Orchid Labs using an in-app purchase. These are distinct from Orchid accounts created in the dApp and have the following properties:

* Purchased accounts connect only to [preferred providers](https://www.orchid.com/preferredproviders) for VPN service.  
* It is not possible to transfer the crypto out of a purchased Orchid account in the same way as an account created in the dApp.
* Accounts are created on the xDai blockchain and are denominated in the XDAI stablecoin.

Orchid takes your in-app purchase funds and adds the equivalent XDAI to the selected Orchid address on the xDai blockchain. Your balance and deposit will increase by the amount of USD purchased.

## Orchid account efficiency

Orchid’s nanopayments work on a principle: that sending someone a scratch lottery ticket with a 1/100 chance of winning $100 instead of sending $1 will save you transaction fees and transmit the same amount of value over time. The amount of value transmitted per “winning” ticket divided by the fees gives the account’s efficiency which is displayed in the app and dApp.

When the efficiency of an account drops below 0%, providers will no longer accept payments from that account because the network fees are greater than the amount of value they could receive from a winning ticket. Accounts with 0% efficiency will not work with the VPN service and will warn the user with a red “!”. 

There are three major factors that affect efficiency:

* The size of the deposit of the account which determines the face value of the tickets
* The network fees for a given moment in time
* Currency conversion of the currency held in the account to the currency used to pay network fees

### Efficiency example

Imagine an Orchid account with a 150 OXT deposit. The account will issue tickets with a 75 OXT face value. Providers therefore are getting a tiny chance at “winning” 75 OXT for each ticket they accept for service. Providers must pay the network fee to claim the 75 OXT. Since the OXT denominated account is on Ethereum, the network fees are paid in ETH. So the provider calculates the current ETH gas price in OXT and makes sure that the fee is not greater than 75 OXT. When the network fees the provider pays to claim the 75 OXT are greater than 75 OXT of value, the provider does not accept payments from that account and that account has a 0% efficiency.

## Deposit

The deposit is required to accept service and is verified by providers. The deposit prevents double spending and in general, the deposit maintains good standing on the network.

The size of the deposit determines the face value of the tickets sent from the user to the provider. The face value refers to the amount of OXT that a provider claims when they receive a winning off-chain nanopayment. Currently the face value is set to equal half of the deposit. 

When an Orchid account is created, the deposit is “locked” and cannot be withdrawn from the account until it is “unlocked” and a 24-hr cooling period has passed.

### Size of Deposit

Market conditions are constantly changing. This includes fluctuations in network fees (Ethereum gas amounts) and changes in the conversion rate from the currency held in the account to the currency to pay network fees (OXT -> ETH). When the account efficiency gets low, it is a good idea to add additional OXT to the deposit of the account to increase the efficiency.

The dApp has an [efficiency slider](../orchid-dapp/#efficiency-slider-to-determine-deposit-size/) that displays the amount of deposit necessary to achieve that efficiency.

Increasing the size of the deposit increases the efficiency of the account by increasing the face value of the tickets. 

## Balance

The balance portion of the Orchid account is the amount of currency held to pay providers. When the account is in use, the tickets are backed by funds in the balance. When a ticket “wins”, the face value of the ticket is withdrawn from the user’s account balance and deposited into the provider’s account with an on-chain transaction.

As a practical matter, while using the Orchid VPN, you will notice that the balance remains unchanged for long periods of time. That is because you can often receive significant amounts of bandwidth, on average, before a payment ticket “wins”, funds are claimed and your balance is adjusted. 

The balance of an Orchid account can be thought of as a number of tickets. The size of the ticket is governed by the deposit, as the network requires two tickets worth of deposit for payments to be accepted. The two tickets worth of deposit is required to prevent double spending attacks. So for example, if the account’s deposit size is 150 OXT and there is 225 OXT in the balance, the Orchid account has 3 tickets worth of balance because the size of each ticket is 75 OXT (deposit / 2) and there are 3 tickets worth of balance (total balance / ticket size).

The dApp has an [Add Funds](../orchid-dapp/#add-funds) screen to add additional balance to your account. 

### Tickets

A ticket is a nanopayment sent from a user to a provider to pay for service. The ticket has a probability of winning along with a face value, which is the amount of currency the provider receives if the ticket “wins”. 

The face value of a ticket is set at half of the deposit in the Orchid account. While this is hard coded in the app right now, in the future the face value of tickets could vary, depending on market conditions and to optimize for variance. However, the upper limit of ticket size is governed by the deposit, and the max ticket size is always half of the deposit.

Orchid accounts with very few tickets will experience a high amount of variance due to the nature of probability. 

### Variance

There is an important concept to consider when using Orchid -- variance. Since tickets have a probability of a win, it is likely that a winning ticket will be claimed either faster or slower than is expected. 

For a quick example, imagine you have an Orchid account with one ticket worth of balance. As you start using the service, a winning ticket is issued immediately because you are “unlucky”. Your balance then goes to 0 and you will need to add funds. This is an example of not getting what you expect due to variance. The inverse can also happen: that is to receive much more service than expected.

To combat variance, Orchid accounts need more tickets worth of service. That way, the probability of a winning ticket being issued before or after you would expect is mitigated. As of now, Orchid recommends at least 3 tickets worth of service in your account balance.

## Technical Parts of an Orchid account

The makeup of an Orchid account is important for understanding how to manage it, and how the different components work together. Ultimately the technical details of the account are dictated by the nanopayment smart contract which holds the funds and allows users to interact with their accounts.

### The Orchid funder wallet

The funder wallet is a block-chain address that corresponds to the wallet address that funded the account. The owner of that wallet has complete control over the Orchid account and can add or remove funds, along with all the other operations available in the Orchid account manager.

Simply put, the funder wallet is the custodian of the Orchid account. Without the keys to the funder wallet, no functions can be performed on the account, such as adding/removing funds, unlocking/locking the deposit and moving funds between balance and deposit.

If the keys to a funder wallet are lost, the associated Orchid account will still function, but the user cannot add funds, remove funds or make any changes to the account. You will be able to use the account while it’s efficiency is above 0%, until the balance is reduced to 0. If the deposit is lost and if the account efficiency drops below 0%, there is no way to add to the deposit.

### The Orchid Address & Key

Orchid accounts utilize their own keypair. The private portion of the key or “secret” is used by the client to sign tickets. The key is therefore a core technical property of the Orchid account and is the important bit of information that is shared when an Orchid account is shared between people or devices.

The public portion of the keypair is the address which is used when funding the Orchid account. The funding transaction that takes funds from the funder wallet and into the nanopayment contract requires the funds to be linked to an Orchid address. In the Orchid dApp, the address is required before a new Orchid account can be created – you can copy your Orchid Address in the latest version of the app and paste that in the signer address field in the dApp to create an account.

The keypair is generated in the app. To create a new keypair, go to the Manage Accounts->Gear Icon->New. The Orchid address will be displayed next to an identicon and can be copied over to be used by the dApp to add an orchid account to this address. The key can be exported using the gear icon and saved and will have access to any accounts with that address.

### Sharing Orchid accounts

There’s no limit to the number of people or devices that a single Orchid account can be shared with. The account is specified by the funder wallet and the signer secret. To share an account, you can click the cog wheel next to Orchid Address and then 'export.' A QR code encoding this information with a copy button will appear feature. The account information can also be copied and directly pasted into the client app as text. 

The Orchid account format looks like this:

account={ secret: "<signer secret>" }


## Orchid Account Troubleshooting

### Deposit size too small
Both the Orchid client app and the Orchid web dApp will display a warning when the Orchid account efficiency or balance is too low for usage. There are a few solutions when you see this error.

**For in-app purchased accounts (iOS/macOS only feature)**
Tap on the warning to go into the selected account. Simply Add Credit to the account to increase the balance and deposit with a purchase. Do not try to fix purchased accounts in the dApp, manage purchased accounts using in-app purchases only in the app.

**For Orchid accounts created with the DApp**
The Orchid dApp can add funds to the account’s deposit, which will improve the Orchid account efficiency and eliminate the warning, allowing the app to start working. To add funds, connect the funder wallet used to create the Orchid account and click on the Add Funds tab.

### What is the difference between Balance and Deposit in my Orchid Account?

The [balance](../accounts/#balance) is the collateral for the tickets sent from the user to the provider. Over time, as winning tickets are issued from your Orchid app, the Orchid account balance will drop. The [deposit](../accounts/#deposit) is the Orchid token held in escrow to disincentivize double spending on the network. This amount never depletes and can be withdrawn after a 24hr "unlock" period.

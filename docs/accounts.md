# What are accounts
Orchid accounts are the center of the payment system that allows Orchid’s decentralized VPN application to function. To use the VPN application, you will need access to an Orchid account.

The Orchid accounts hold the funds that pay providers through the nanopayment system and users are responsible for managing those accounts on the blockchain. Each account has its own public/private keypair, a special funder wallet that can control the account and the account makeup (deposit & balance), which determines how efficient the account is at transmitting payments.

# How to get an Orchid account

* Purchase an account (iOS/macOS only feature) custodied by Orchid
* [Create](https://docs.orchid.com/en/stable/orchid-dapp/#create-account) and self-custody an Orchid account using the Orchid dApp
* [Access an account](https://docs.orchid.com/en/stable/accounts/#Sharing-orchid-accounts) that was shared with you

## Purchased Orchid accounts (iOS/macOS only feature)

In the Orchid iOS and macOS apps, it is possible to simply purchase an Orchid account from Orchid Labs using an in-app purchase. These are distinct from Orchid accounts created in the dApp.

Currently these accounts are pre-filled with currency and the credentials for them are custodied by Orchid Labs. That means that once an account is purchased, the account cannot be refilled and the deposit cannot be increased if market conditions change. We are aware of this critical limitation and will address it in our next iteration of the in-app purchase system.

For now, email contact@orchid.com if your purchased account has any issues and we can promptly resolve them.

# Orchid account efficiency

Orchid’s nanopayments work on a principle: that sending someone a scratch lottery ticket with a 1/100 chance of winning $100 instead of sending $1 will save you transaction fees and transmit the same amount of value over time. The amount of value transmitted per “winning” ticket divided by the fees gives the account’s efficiency which is displayed in the app and dApp.

When the efficiency of an account drops below 0%, providers will no longer accept payments from that account because the network fees are greater than the amount of value they could receive from a winning ticket. Accounts with 0% efficiency will not work with the VPN service and will warn the user with a red “!”. 

There are three major factors that affect efficiency:
* The size of the deposit of the account which determines the face value of the tickets
* The network fees for a given moment in time
* Currency conversion of the currency held in the account to the currency used to pay network fees

## Efficiency example

Imagine an Orchid account with a 150 OXT deposit. The account will issue tickets with a 75 OXT face value. Providers therefore are getting a tiny chance at “winning” 75 OXT for each ticket they accept for service. Providers must pay the network fee to claim the 75 OXT. Since the OXT denominated account is on Ethereum, the network fees are paid in ETH. So the provider calculates the current ETH gas price in OXT and makes sure that the fee is not greater than 75 OXT. When the network fees the provider pays to claim the 75 OXT are greater than 75 OXT of value, the provider does not accept payments from that account and that account has a 0% efficiency.

# Deposit

The deposit is required to accept service and is verified by providers. The deposit prevents double spending and in general, the deposit maintains good standing on the network.

The size of the deposit determines the face value of the tickets sent from the user to the provider. The face value refers to the amount of OXT that a provider claims when they receive a winning off-chain nanopayment. Currently the face value is set to equal half of the deposit. 

When an Orchid account is created, the deposit is “locked” and cannot be withdrawn from the account until it is “unlocked” and a 24-hr cooling period has passed.

## Size of Deposit

Market conditions are constantly changing. This includes fluctuations in network fees (Ethereum gas amounts) and changes in the conversion rate from the currency held in the account to the currency to pay network fees (OXT -> ETH). When the account efficiency gets low, it is a good idea to add additional OXT to the deposit of the account to increase the efficiency.

The dApp has an [efficiency slider](https://docs.orchid.com/en/stable/orchid-dapp/#efficiency-slider-to-determine-deposit-size/) that displays the amount of deposit necessary to achieve that efficiency.

Increasing the size of the deposit increases the efficiency of the account by increasing the face value of the tickets. 

# Balance

The balance portion of the Orchid account is the amount of currency held to pay providers. When the account is in use, the tickets are backed by funds in the balance. When a ticket “wins”, the face value of the ticket is withdrawn from the user’s account balance and deposited into the provider’s account with an on-chain transaction.

As a practical matter, while using the Orchid VPN, you will notice that the balance remains unchanged for long periods of time. That is because you can often receive significant amounts of bandwidth, on average, before a payment ticket “wins”, funds are claimed and your balance is adjusted. 

The balance of an Orchid account can be thought of as a number of tickets. The size of the ticket is governed by the deposit, as the network requires two tickets worth of deposit for payments to be accepted. The two tickets worth of deposit is required to prevent double spending attacks. So for example, if the account’s deposit size is 150 OXT and there is 225 OXT in the balance, the Orchid account has 3 tickets worth of balance because the size of each ticket is 75 OXT (deposit / 2) and there are 3 tickets worth of balance (total balance / ticket size).

The dApp has an [Add Funds](https://docs.orchid.com/en/stable/orchid-dapp/#add-funds) screen to add additional balance to your account. 

## Tickets

A ticket is a nanopayment sent from a user to a provider to pay for service. The ticket has a probability of winning along with a face value, which is the amount of currency the provider receives if the ticket “wins”. 

The face value of a ticket is set at half of the deposit in the Orchid account. While this is hard coded in the app right now, in the future the face value of tickets could vary, depending on market conditions and to optimize for variance. However, the upper limit of ticket size is governed by the deposit, and the max ticket size is always half of the deposit.

Orchid accounts with very few tickets will experience a high amount of variance due to the nature of probability. 

## Variance

There is an important concept to consider when using Orchid -- variance. Since tickets have a probability of a win, it is likely that a winning ticket will be claimed either faster or slower than is expected. 

For a quick example, imagine you have an Orchid account with one ticket worth of balance. As you start using the service, a winning ticket is issued immediately because you are “unlucky”. Your balance then goes to 0 and you will need to add funds. This is an example of not getting what you expect due to variance. The inverse can also happen: that is to receive much more service than expected.

To combat variance, Orchid accounts need more tickets worth of service. That way, the probability of a winning ticket being issued before or after you would expect is mitigated. As of now, Orchid recommends at least 3 tickets worth of service in your account balance.

# Technical Parts of an Orchid account

The makeup of an Orchid account is important for understanding how to manage it, and how the different components work together. Ultimately the technical details of the account are dictated by the nanopayment smart contract which holds the funds and allows users to interact with their accounts.

## The Orchid funder wallet

The funder wallet is a block-chain address that corresponds to the wallet address that funded the account. The owner of that wallet has complete control over the Orchid account and can add or remove funds, along with all the other operations available in the Orchid account manager.

Simply put, the funder wallet is the custodian of the Orchid account. Without the keys to the funder wallet, no functions can be performed on the account, such as adding/removing funds, unlocking/locking the deposit and moving funds between balance and deposit.

If the keys to a funder wallet are lost, the associated Orchid account will still function, but the user cannot add funds, remove funds or make any changes to the account. You will be able to use the account while it’s efficiency is above 0%, until the balance is reduced to 0. If the deposit is lost and if the account efficiency drops below 0%, there is no way to add to the deposit.

## The Orchid signer

Orchid accounts utilize their own keypair, the signer. The private portion of the key or “secret” is used by the client to sign tickets. The signer key is therefore a core technical property of the Orchid account and is the key bit of information that is shared when an Orchid account is shared between people or devices.

The public portion of the signer, the signer address, is used when funding the Orchid account. The funding transaction that takes funds from the funder wallet and into the nanopayment contract requires the funds to be linked to a signer address. In the Orchid dApp, the signer address is required before a new Orchid account can be created.

The signer address is used by providers to ensure the funds in an Orchid account correspond to a ticket they receive for service. The address can also be used to lookup information about the account on-chain.

The signer is generated when a [custom Orchid account](https://docs.orchid.com/en/stable/using-orchid/#create-a-custom-account) is created (Android only feature) or when [creating an Orchid account](https://docs.orchid.com/en/stable/orchid-dapp/#create-account) in the dApp. 

## Sharing Orchid accounts

There’s no limit to the number of people or devices that a single Orchid account can be shared with. The account is specified by the funder wallet and the signer secret. The QR code sharing feature in the app just encodes this information. The account information can also be copied and directly pasted into the client app as text. 

The Orchid account format looks like this:

account={ protocol: "orchid", funder: "<public funder wallet address>", secret: "<signer secret>" }

Note - the public funder wallet address starts with 0x, while the signer secret does not use the 0x prefix.

# Orchid Account Troubleshooting

## Deposit size too small
Both the Orchid client app and the Orchid web dApp will display a warning when the Orchid account efficiency or balance is too low for usage. There are a few solutions when you see this error.

**Turn off Orchid and wait for network fees to drop**
A primary cause of a deposit that is too low could be a sudden spike in network transaction fees. If, for example, your Orchid account is on the Ethereum chain with OXT in it, then the Ethereum gas costs could suddenly spike, which causes your Orchid account’s efficiency to drop below 0. Waiting for network fees to settle is all that is needed for account efficiency to rise back up, and to get it working again.

**For in-app purchased accounts (iOS/macOS only feature)**
Orchid attempts to pre-fill Orchid accounts with enough of a deposit at the time of purchase, but market conditions can change rapidly. Email Orchid support at contact@orchid.com to fix problems with purchased accounts. In the near future, users will be able to manage their accounts through additional purchases in the client app. For now, there is no way for the user to fix purchased accounts with low efficiency. Do not try to fix purchased accounts in the dApp, as there is no way to do that correctly. We apologize for the inconvenience until this new system is online.

**For Orchid accounts created with the DApp**
The Orchid dApp can add funds to the account’s deposit, which will improve the Orchid account efficiency and eliminate the warning, allowing the app to start working. To add funds, connect the funder wallet used to create the Orchid account and click on the Add Funds tab.

## What is the difference between Balance and Deposit in my Orchid Account?

The [balance](https://docs.orchid.com/en/stable/accounts/#balance) is the collateral for the tickets sent from the user to the provider. Over time, as winning tickets are issued from your Orchid app, the Orchid account balance will drop. The [deposit](https://docs.orchid.com/en/stable/accounts/#deposit) is the Orchid token held in escrow to disincentivize double spending on the network. This amount never depletes and can be withdrawn after a 24hr "unlock" period.

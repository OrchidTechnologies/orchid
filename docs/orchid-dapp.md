# The Orchid DApp

## What is the Orchid DApp

The Orchid dApp is a hosted front-end for users to create and manage Orchid accounts, so users don’t need to interact with the smart contract directly. At its core, the dApp is a wrapper for the function calls of the smart contract combined with UI elements to help users make decisions for their account makeup.

Orchid Labs hosts the dApp at [account.orchid.com](https://account.orchid.com/)

## DApp Overview

The interface allows users to create and manage their Orchid account.

Orchid is an EVM-compatible layer 2 that enables the transmission of tiny payments. Users connect their L1 wallet on one of the supported chains, and using the dApp, they can move funds into and out of their Orchid accounts.

We currently support the following chains:

* [Aurora](https://aurora.dev/)
* [Avalanche](https://www.avax.network/)
* [Binance](https://www.binance.com/en/bnb)
* [CELO](https://celo.org/)
* [Ethereum](https://ethereum.org/)
* [Fantom](https://www.fantom.foundation/)
* [Gnosis](https://gnosis.io/)
* [Optimism](https://www.optimism.io/)
* [Polygon](https://polygon.io/)

Once a wallet is connected, the interface will activate for the Orchid account associated with that wallet. The interface will show your account’s balance, deposit, amount of available tickets, and the efficiency of your account’s tickets. The “Add” and “Withdraw” tabs at the bottom of the interface are where you can add funds or remove them from the selected account.

## Creating an Account

To successfully create and fund an account, there are three important steps: connecting your wallet, adding an Orchid identity, and funding the account.

### Connecting a wallet

In order to make the dApp active, you will need to attach a funder wallet. The “Connect” button will show your wallet options, depending on whether you are on desktop or mobile, and whether or not a wallet is detected. This step is similar to “logging in”, as the funder wallet you use to create the account is required to access and manage the account.

The key supported wallet connection methods are:

* Load the dApp in a dApp browser
* Use a desktop browser with a web3 browser plugin enabled

For testing purposes, Orchid uses Metamask.

Once the wallet is connected, you will see the address of that wallet displayed as the “funder wallet” with the funds associated with it appearing next to the address. 

### L2 keys/Orchid identity 

As Orchid is a layer 2 solution, you will need to generate an Orchid identity in addition to your wallet to fund your account. Keys are created and managed in the Orchid app; to fund your Orchid account, simply copy the Orchid identity from your Orchid app into the Orchid dApp.

### Determining balance/deposit size

The backbone of Orchid is a probabilistic payment system designed to mitigate the amount of transactions and subsequent gas fees for the end user. Essentially, Orchid conducts transactions with a lottery ticket system. Let’s say you wanted to pay your provider $100 incrementally; instead of paying them $1 one hundred times and paying 100 transaction fees, with Orchid, you send them 100 lottery tickets, with each ticket having a 1% chance of winning $100. The provider receives the same amount of money, but instead of paying for 100 transactions, you only pay for the one winning ticket.

When funding your account, the value of your tickets is set to half the value of your deposit. However, Orchid’s services will not withdraw funds from your deposit; to generate tickets for your account, you must add funds to your balance, which Orchid will draw from whenever a winning ticket is pulled by your provider.

Now, a core component of determining the size of your balance and deposit is “efficiency”. When it comes to Orchid lottery tickets, since the user still has to pay an L1 network fee for that winning transaction to go on-chain, we use the concept of “efficiency” to denote the transmitted value as a percentage of the total ticket value to the provider. So, if you gave your provider a winning ticket worth $100, but your ticket’s efficiency is only 20%, the provider will receive the $100 and pay $80 in L1 network fees, meaning they only really receive $20.

The amount of tickets you hold on your account is also an important factor, to combat the variance of the probabilistic system. To read more about variance, click [here](https://docs.orchid.com/en/latest/accounts/#variance).

For funding your account, we recommend maintaining a deposit large enough for at least 90% efficiency, and a balance large enough for at least four tickets. For your convenience, Orchid provides users with a chart showing each of our partnered chains and the recommended amounts (in USD) to fund an account’s balance, deposit, and the fees associated with funding and withdrawing from your account. You can view the chart [here](https://account.orchid.com/widget/).

Because efficiency is coupled tightly with network transaction fees, it is useful to see if there is something abnormal happening with current gas fees that could cause the efficiencies of Orchid accounts to rapidly change. If network fees rise on a given L1 where an Orchid account is housed, a larger deposit will be required to maintain the same level of efficiency.

## Funding the account

Enter the amount of balance and deposit you want to add into the corresponding fields, denominated in token values from your wallet’s chain of choice. We currently support nine chains: Aurora, Avalanche, Binance, CELO, Ethereum, Fantom, Gnosis, Optimism and Polygon. Once again, you can consult our [chart](https://account.orchid.com/widget/) to determine the amount necessary to fund your account to our recommended values of 90% efficiency and four tickets. You can click on “USD Prices” in the top-right to view our recommended values in USD to better understand the amount being added.

Once you’ve entered your desired funds, tap on the Add Funds button to submit the transaction to your attached wallet for approval; once approved, the transaction will be submitted to the blockchain and confirmed. A transaction pop-up will link to that blockchain’s block explorer so you can view the confirmation.

### Add funds tab

The “Add Funds” tab allows you to add either to the deposit or balance of your account. In order to add funds to an account, the funder wallet of the account will need to be connected to the dApp interface.

Once there is enough currency in the funder wallet, click the “Add Funds” button to initiate the transaction. The funder wallet needs to approve the transaction, then a purple banner will appear with the status of your transaction.

### Withdraw tab

The “Withdraw” tab allows you to pull funds from the balance and deposit of the account to a wallet of your choice. If the deposit is still locked, only the balance will be able to be withdrawn.

If you are looking to withdraw everything from the account, the way to do this with the least amount of network fees is to unlock the deposit, then withdraw the balance and deposit together. That way, you only incur network fees for the unlock and withdraw, as opposed to incurring fees for the withdrawal twice.

### Unlocking funds

The deposit of all Orchid accounts requires a 24 hour cool-off period before it can be withdrawn. The cool-off period gives enough time for providers to settle any winning tickets they may have, and prevents double spending on the network. When funds are added to a deposit, they are considered “locked”; these locked funds are used by the network for calculations. Once a deposit is unlocked, those deposit funds are not counted towards the usable deposit on the network.

To unlock and withdraw funds, go to the Withdraw tab, check the “Unlock deposit” checkbox, then click “Unlock Deposit” at the bottom to send the transaction for approval in your wallet. Once that transaction is confirmed, the deposit funds will be available in 24 hours.

### Advanced tab

The Advanced tab allows you to access all the features of the dApp from a single tab. To add or withdraw funds from your deposit/balance, enter the desired amount of funds in the token used to fund the account, select “Add” or “Withdraw” from the dropdown menu, and click “Submit Transaction”.

If you want to withdraw from your deposit, but don’t want to unlock/withdraw the entire amount, you can use “Set Warned Amount” to unlock a portion of your deposit. Enter the amount you wish to unlock, and click “Submit Transaction”.

Note that moving funds from your deposit to your balance or withdrawing from your deposit will require you to unlock the funds in your deposit, which can be done using the “warn” feature and requires a 24 hour cool-off period before being made available.

## Orchid DApp FAQs

### Why do I need a new Ethereum wallet? Why can’t I use my main wallet?

While you could use your primary Ethereum wallet, we do not recommend it if you are seeking privacy with Orchid. Using Orchid results in on-chain payments flowing from your wallet to the Orchid nanopayment contract, and then on to VPN providers selling bandwidth. Ethereum on-chain analytics can easily link payments to/from the nanopayment smart contract, and then to providers. If the source of the funds comes from your personal Ethereum wallet, anyone using Etherscan would be able to see that you used Orchid and sent payments to VPN providers whenever the Orchid nanopayment system issues a winning ticket.

### Why should I trust a big exchange with my personal info? Would a decentralized exchange that doesn’t store my personal info be better?

While a decentralized exchange does not store personal information that could link your source of funds to your identity, a decentralized exchange does typically require an Ethereum account with some sort of crypto such as ETH, which has its own history of transactions. If that ETH or wallet is linked to your identity, then the source of funds could be linked through the DEX back to your originating Ethereum wallet.

A large exchange typically has a ledger they use to keep track of ownership, with a hot wallet they use to send funds in and out of the exchange. While the exchange knows your identity, the movement of currency in and out of the exchange is anonymous, as the funds can’t be tracked to your identity on the blockchain without the exchange being hacked, subpoenaed or otherwise compromised.

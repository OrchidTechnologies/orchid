# The Orchid DApp

The Orchid dApp is a hosted front-end for users to create and manage Orchid accounts so users don’t need to interact with the smart contract directly. At its core, the dApp is a wrapper for the function calls of the smart contract with UI elements to help users make decisions for account makeup.

The dApp interface will ask users to set their efficiency and number of max-sized tickets in their balance, so a familiarity with Orchid accounts is helpful to understand the terminology.

Orchid Labs hosts the dApp at [account.orchid.com](https://account.orchid.com/)

# DApp Overview

The interface allows users to create and manage multiple Orchid accounts, although for most users only one account is necessary. When arriving at the interface for the first time, the create account screen will display with the controls inactive.

Once a wallet is connected, the interface will activate for the Orchid account associated with that wallet. If multiple accounts exist, clicking on the purple Orchid logo at the top right will bring them up so one can be selected.

The Add and Withdraw buttons at the top of the interface are how you can add funds or remove them from the selected account. 

The More tab provides a few more screens for navigation.

* Info: more details about the selected account
* Transactions: a list of transactions associated with the attached wallet
* Move Funds: a function to move funds from balance -> deposit
* Lock/Unlock Funds: a function to lock or unlock the deposit
* Advanced: a debugging output screen 


# Connecting a wallet

In order to make the dApp active, you will need to attach a funder wallet. The “Connect” button will pop-up your wallet options, depending on whether you are on desktop or mobile, and whether or not a wallet is detected. This step is similar to “logging in” in some sense, as the funder wallet you use to create the account is required to access and manage the account.

The key supported wallet connection methods:
* Load the dApp in a dApp browser, such as MetaMask Mobile or Trust Wallet
* Use any desktop browser and then connect a mobile wallet with WalletConnect
* Use a desktop browser with MetaMask enabled as a web3 browser plugin

Once the wallet is connected, you will see the address of that wallet displayed as the “funder wallet” with the funds associated with that wallet appearing next to the address. All of the Orchid accounts created by that funder are available to manage.

To disconnect a wallet, click on the purple Orchid logo in the upper right corner. That will pop open a menu with a Disconnect button.

# Create account

To create an account, you will first need to have a wallet connected. Once that is complete, the interface will activate and you will see your funder wallet address displayed.

The first step is to determine how much currency you will need to fund the account. The key decisions are how much to put into the deposit and how much to put into the balance.

## Signer address

If you have created an Orchid signer in the Orchid app (Android-only feature labeled as “custom account creation”), you can paste the public portion of the signer, the signer address, into the box.

For most users, you will not have a signer keypair generated. No problem. Use the button to create the signer. Once the signer is created, the account exists in some sense, and you can now scan the QR code, or copy and paste the account into the app. 

It is a great idea to backup the account credentials at this time. A simple way to do that is to click the “Copy” button under the QR code, and then paste the account info into a password manager.

NOTE: the account will have a zero balance until all three of these actions have happened: the transactions are submitted by pressing the “create” button, the transactions are approved by the attached wallet and the transactions have been confirmed by the blockchain.

## Efficiency slider to determine deposit size

The efficiency slider shows what the payment efficiency will be for the current market conditions. The UI gathers the relevant information about the current price of the digital currencies and the amount of gas required for a provider to claim a payment, and then translates that into an efficiency metric.

We recommend at least 50% efficiency, but that still means that 50% of your currency is going towards network fees. As you get into higher efficiency, the deposit size grows, but the amount paid to fees lessens. So there is a tradeoff between the total amount of money put into the deposit and the account efficiency.

Because efficiency is coupled tightly with network transaction fees, it is useful to see if there is something abnormal happening with current Ethereum gas fees that could be causing the efficiencies of Orchid accounts to be rapidly changing. 

## Size picker to determine balance size

Due to the nature of the nanopayment system, the size of the balance needs some thought. Because payments are sent as probabilities of winning larger sums of money (what we call “lottery tickets”) the balance needs to be large enough to make tickets that will be accepted by providers. Learn more about [tickets here](../accounts/#tickets).

Since the deposit is not used to pay for bandwidth, the amount of currency in your account that can be used for purchasing service is determined by the balance amount. 

As of now, the size of lottery tickets is half of the balance of the deposit. The size picker simply turns this into a plus and minus button, so you can pick how many tickets worth of balance you want in your account. You can always enter a number into the box as well.

Our recommendation is to have a minimum of 3 tickets worth of balance. That helps even out the probabilities of the tickets over time, so that you don’t experience too much variance.

## Add enough funds to your funder wallet

Once you have used the interface to pick an efficiency and size, you will then know how much funds you will need to create the account. The amount is totaled right above the create button as “Total OXT” as well as the “Network fee ETH”. You will need that amount of OXT and that amount of ETH in the funder wallet in order to enable the create account button.

A current listing of exchanges where to buy OXT and ETH are listed here: [https://www.orchid.com/oxt](https://www.orchid.com/oxt)

## Funding the account

Once there are enough funds in the attached funder wallet, the Create button will become available. Click Create!

That will trigger 2 transactions to be submitted to the blockchain. The first one is an approval and will be less expensive than the second one, which is a push. Both need to successfully complete in order for the account to be usable and created properly. Both transactions will pop-up in the funder wallet and require approval, along with the payment for associated network fees. 

The first transaction to accept will be an approve call for the ERC-20 OXT token. This is relatively cheap, and is typically picked up fast by Ethereum. The second transaction is a push call to the Orchid nanopay contract. This is the more expensive function, and typically will require more gas and time. If your wallet supports increasing the gas limit for transactions, it is a good idea to use a higher gas limit for the second transaction so that it gets confirmed by the blockchain faster.

Once the 2 transactions are approved and submitted to the blockchain, two purple banners will appear so you can keep track of the status of each transaction. Depending on the load on the current blockchain and the fees submitted with the two transactions, this can end up taking either a few minutes or many hours to complete. Blockchain tools such as Etherscan can be used to get an estimation on how long it will take.

## Multiple Account Management

Once you have an Orchid account created, it will become selected in the interface and the UI elements will be relevant for that Orchid account. The information appearing on the Overview screen is relevant to that account, along with adding/withdrawing funds, etc. 

The Orchid dApp supports a single attached funder wallet to make multiple accounts. To access multiple accounts, click on the purple Orchid logo in the upper right to open the account list. From there you can create a new account and select between existing accounts.

# Add funds

The Add Funds screen allows you to add funds to an existing account. In order to add funds to an account, the funder wallet of the account will need to be connected to the dApp interface.

Clicking on Add Funds will bring up the interface. It is very similar to the account creation interface, except that the account has an existing balance and deposit. The efficiency slider and size picker will both help determine the amount of funds you need to add to the account.

The total at the bottom of the interface is the amount of currency you will need in order to change the account makeup to be as selected in the interface. In addition to the currency that will be added to the balance and/or deposit, you will also need to pay the network fee.

The recommendation is to have an efficiency of at least 50% and to have at least 3 tickets worth of balance.

Once there is enough currency in the funder wallet, click the “Add Funds” button to initiate the two transactions needed to add funds. The funder wallet needs to approve both transactions and then two purple banners will appear with the status of both of those transactions.

# Withdraw

For the withdraw function to be available, a funder wallet will need to be connected first. The withdraw screen allows you to pull the currency out of the Balance and Deposit of the account to a wallet of your choice. If the deposit is still locked, only the balance will be able to be withdrawn. 

Note - if you are looking to withdraw everything from the account, the way to do this with the least amount of network fees is to unlock the Deposit and then withdraw the Balance and Deposit together. Then you only incur network fees for the unlock and withdraw, vs incurring fees for the withdraw twice.

Once the Deposit is unlocked and the 24 hour cooling off period satisfied, the check box to “Withdraw Full Balance and Deposit” will be available. 

# Lock/Unlock Funds

The deposit of all Orchid accounts requires a 24 hour cooling off period before it can be withdrawn. The cooling off period gives enough time for providers to settle up any winning tickets they may have, and prevents double spending on the network.

In order to withdraw the deposit, the deposit will first need to be unlocked using the Lock/Unlock Funds screen.

Connect the funder wallet of the Orchid account to unlock and then click on the More menu in the upper right hand corner. There is a link for Lock/Unlock funds. That will open the interface. 

The account’s deposit will either be locked or unlocked. Use the button to change the status back and forth. Note that there is a network fee for each lock and unlock. The amount of the network fee will be shown in the funder wallet after you click the lock/unlock purple button.

# Account info

To see your Orchid Account info, go to ‘More’ and then ‘Info’. You’ll see the wallet associated with the Orchid Account, and the ETH and OXT amounts in the attached wallet at the top. Below that, you’ll see the Signer Key and then under ‘Orchid Account’ is your balance and deposit.

At the bottom, you’ll see Market Stats including minimum and recommended amounts for your balance and deposit. These numbers will fluctuate depending on the current market conditions.

Finally, you’ll see whether the funds in your account are locked or unlocked.

# Notification banners

Notification banners alert you to changes related to market interactions and the Orchid network that impact your Orchid account balance and deposit. For help with specific notification messages, see [Orchid account troubleshooting](../accounts/#orchid-account-troubleshooting).

Notification banners also appear when there are transactions submitted from the dApp, approved by the funder wallet and awaiting confirmation from the blockchain.

# Orchid DApp FAQs

## Why do I need a new Ethereum wallet? Why can’t I use my main wallet?

While you could use your primary Ethereum wallet that you typically use for other Ethereum applications, we do not recommend it if you are seeking privacy with Orchid. The main reason is that using Orchid results in on chain payments flowing from your wallet to the Orchid nanopayment contract, and then on to VPN providers selling bandwidth. Ethereum on-chain analytics can easily link payments to/from the nanopayment smart contract and then to providers. If the source of the funds comes from your personal Ethereum wallet linked to other services, anyone using Etherscan would be able to see that you used Orchid and sent payments to VPN providers, when the occasional Orchid nanopayment system issues a winning ticket.

## Why should I trust a big exchange with my personal info? Would a decentralized exchange that doesn’t store my personal info be better?

While a decentralized exchange does not store your personal information that could link your source of funds to your identity, a decentralized exchange does typically require an Ethereum account with some sort of crypto such as ETH, which has its own history of transactions. If that ETH or wallet is linked to your identity, then the source of funds could be linked through the DEX back to your originating Ethereum wallet.

A large exchange typically has a ledger they use to keep track of ownership, with a hot wallet they use to send funds in and out of the exchange. While the exchange knows your identity, the movement of currency in and out of the exchange is anonymous, as the funds can’t be tracked to your identity on the blockchain without the exchange being hacked, subpoenaed or otherwise compromised.

## Why do I need ETH and OXT?

Orchid is a series of decentralized smart contracts and client software that uses Ethereum. Certain operations require the use of ETH for gas to power the smart contracts that run Orchid. For users who use the Orchid app, ETH is required when adding or removing funds from your Orchid account through the web3 browser interface.



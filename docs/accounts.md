# Orchid Accounts

To create an Orchid account for use with the Orchid app to buy VPN service, see our [set-up guide](https://orchid.com/join).

Orchid accounts exist as entries in an Ethereum smart contract which holds the OXT for users and pays providers. Funds exist on-chain so that providers can verify that funds exist for the services they are providing and can claim those funds. Learn more about how our 2nd layer scaling solution works: [Introducing Nanopayments](https://blog.orchid.com/introducing-nanopayments/).

To access the Orchid account, you must use a web3 enabled browser plugin such as Metamask or a DApp enabled wallet such as Trust Wallet. Access to the Ethereum wallet used to create the account is required to maintain access to the account.

Orchid Labs hosts a web3 enabled website which provides an easy way to setup and manage OXT funds for service. Load [https://account.orchid.com](https://account.orchid.com) in your web3 browser to access the account. It is also possible to call the smart contract functions [directly](https://etherscan.io/address/0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1#code) or to host the wrapper code on your own.

The OXT held in the Orchid account has a balance and deposit component. The balance is the amount of OXT available to pay for service. The deposit size signals information to the provider.

## The deposit 

The deposit is required to accept service and is verified by providers. Our recommendation for VPN service on Orchid is at least 15 OXT for the deposit.

The size of the deposit is important because it determines the face value of the nanopayments. Currently the face value is set to half the deposit. For our recommendation of 15 OXT, that gives a face value of 7.5 OXT, which is enough for VPN providers to claim given estimated gas fees on Ethereum. Providers pass along the Ethereum gas fees to the client when they claim the face value of a winning ticket. 

## Deposit size too small

Under certain market conditions, users need to increase the size of their deposit. If you have received a message in the Orchid app that the deposit is too small, follow these steps:

-Open the Ethereum wallet you used to create the Orchid account (i.e. load Metamask or Trust Wallet)
-Load [account.orchid.com](https://account.orchid.com/). You should see your funded account.
-Click on "More" in the upper right, then select "Move Funds"
-Ensure that your current deposit is at least 15 OXT
-If you need more OXT, click on the "Add" button to add funds from your Ethereum wallet

Market conditions are driven by the price of OXT and the current gas cost on Ethereum. Email contact@orchid.com for support if you received the "deposit size too small" message and are having difficulty.

## The balance

The balance is the amount of OXT that can be used to pay for service. 

Using the current price of OXT and market prices(which includes the gas costs of network operations), we can estimate how many Gigabytes of VPN service you can get for the given balance. Note that as the variables change, the estimated amount of service changes.  

## Web3 Links

Here are links to the specific pages in our hosted web3 website and what they do. In general, each one of these pages helps you make a call to our nanopayment Ethereum smart contract. Eventually, we will move this website back to IPFS. It is possible to call the functions directly on our smart contract.

[**Create account**](https://account.orchid.com/)
Creates an Orchid account. Requires OXT and ETH. 

[**Add funds**](https://account.orchid.com/#addFunds)
Adds OXT to your balance and deposit.

[**Withdraw funds**](https://account.orchid.com/#withdrawFunds)
Withdraws funds from your account to an Ethereum wallet.

[**Move funds**](https://account.orchid.com/#moveFunds)
Moves funds from your balance to your deposit. 

[***Unlock Funds**](https://account.orchid.com/#lockFunds)
Locks and unlocks your deposit for withdrawal.

[**View Balances**](https://account.orchid.com/#balances)
Displays all the information about your account, including the deposit, balance, public signer key and Ethereum wallet address.



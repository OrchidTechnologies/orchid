# Orchid Accounts

To create an Orchid account for use with the Orchid app to buy VPN service, see our [set-up guide](https://orchid.com/join).

Orchid accounts exist as entries in an Ethereum smart contract which holds the OXT for users and pays providers. Funds exist on-chain so that providers can verify that funds exist for the services they are providing and can claim those funds. Learn more about how our 2nd layer scaling solution works: [Introducing Nanopayments](https://blog.orchid.com/introducing-nanopayments).

To access the Orchid account, you must use a web3 enabled browser plugin such as [Metamask](https://metamask.io) (recommended) or a DApp enabled mobile wallet such as [Trust Wallet](https://trustwallet.com), [BRD Wallet](https://brd.com) or [Coinbase Wallet](https://wallet.coinbase.com). Access to the Ethereum wallet used to create the account is required to maintain access to the account.

Orchid Labs hosts a web3 enabled website which provides an easy way to setup and manage OXT funds for service. Load [https://account.orchid.com](https://account.orchid.com) in your web3 browser to access the account. It is also possible to call the smart contract functions [directly](https://etherscan.io/address/0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1#code) or to host the website yourself.

The OXT held in the Orchid account has a balance and deposit component. The balance is the amount of OXT available to pay for service. The deposit size signals information to the provider.

## The deposit 

The deposit is required to accept service and is verified by providers. The deposit prevents double spending and in general, the deposit maintains good standing on the network.

The size of the deposit determines the face value of the nanopayments. The face value refers to the amount of OXT that a provider claims when they receive a winning off-chain nanopayment. Currently the face value is set to half the deposit. Providers need to receive nanopayments with a high enough face value to provide service, given current market conditions.

Our recommendation for VPN service on Orchid is given in the DApp at the time of creation to include current market conditions.

## Deposit size too small

Under certain market conditions, users need to increase the size of their deposit. The market conditions are primarily driven by the price of OXT and the amount of Ethereum gas required to claim a ticket. The face value of the ticket needs to be large enough for it to make sense to the provider to provide service. When the face values are too small, the size of the deposit needs to be increased.

If you have received a message in the Orchid app that the deposit is too small, follow these steps:

- Open the Ethereum wallet you used to create the Orchid account (i.e. load Metamask or Trust Wallet)
- Load [account.orchid.com](https://account.orchid.com). You should see your funded account.
- Click on "Info" in the upper right, scroll to the bottom and find the "Market Stats" section for current minimums and recommendations
- Click on "More" in the upper right, then select "Move Funds"
- Ensure that your current deposit at the recommendation
- If you need more OXT in the balance as well as the deposit, click on the "Add" button to add funds from your Ethereum wallet

Market conditions are driven by the price of OXT and the [current gas cost](https://ethgasstation.info) on Ethereum. Please [contact us](https://www.orchid.com/contact) for support if you received the "deposit size too small" message and are having difficulty.

## The balance

The balance is the amount of OXT that can be used to pay for service. 

Using the current price of OXT and market prices (which includes the gas costs of network operations), we can estimate how many Gigabytes of VPN service you can get for the given balance. Note that as the variables change, the estimated amount of service changes.  

## Orchid Account Functionality

Here is an overview of the different ways you can manipulate an Orchid account using our web3 website. In general, each one of these pages helps you make a call to our nanopayment Ethereum smart contract. 

- [**Create account**](https://account.orchid.com)
Creates an Orchid account. Requires OXT and ETH. 

- [**Add funds**](https://account.orchid.com/#addFunds)
Adds OXT to your balance and deposit.

- [**Withdraw funds**](https://account.orchid.com/#withdrawFunds)
Withdraws funds from your account to an Ethereum wallet.

- [**Move funds**](https://account.orchid.com/#moveFunds)
Moves funds from your balance to your deposit. 

- [**Unlock Funds**](https://account.orchid.com/#lockFunds)
Locks and unlocks your deposit for withdrawal.

- [**View Balances**](https://account.orchid.com/#balances)
Displays all the information about your account, including the deposit, balance, public signer key and Ethereum wallet address.

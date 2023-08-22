![](img/name_logo.png "Orchid Logo")

# Vision
Our vision is to enable secure access to the internet for everyone, everywhere.

## Overview
Orchid is a decentralized marketplace for bandwidth. Providers run a server that talks to a decentralized [directory](https://github.com/OrchidTechnologies/orchid/tree/master/dir-ethereum) running on [Ethereum](https://etherscan.io/address/0x918101FB64f467414e9a785aF9566ae69C3e22C5) and stake OXT in it to compete for inbound service requests (stake-weighted random selection). Payment is settled via Orchid’s own L2/L3 using [streaming probabilistic nanopayments](https://github.com/OrchidTechnologies/orchid/tree/master/lot-ethereum).

The Orchid project includes a VPN application and a lower-level client demon. The app is available for iOS/macOS/Android. The “VPN” app includes Wireshark for traffic analysis and has the ability to string multiple VPN server connections together to form multi-hop circuits. OpenVPN, WireGuard and Orchid protocol are all supported. The app can naturally purchase VPN service from the Orchid bandwidth marketplace by making a request to the directory and then connecting to a provider and paying for VPN service with nanopayments.

The Orchid L2/L3 can be best thought of as a “probabilistic rollup”. Money is sent off-chain as the equivalent of scratch lottery tickets. The payer creates an account and then can issue lottery tickets for payment. Each one has a win rate and amount. The provider can then examine the ticket and accept it for service. The win rate is configurable, and so the number of transactions a second that is possible with the scheme is really only limited by provider’s ability to read the tickets.

## Pick a Key Topic
* [Orchid Accounts](accounts/): Orchid accounts are the decentralized entities that store digital currency on a blockchain to pay for services through nanopayments. The nanopayment smart contract governs Orchid accounts. The Orchid client requires an account in order to pay for VPN service. 
* [The Orchid Client](using-orchid/): An open-source, Virtual Private Network (VPN) client that supports decentralized Orchid accounts, as well as WireGuard and OpenVPN connections. The client can string together multiple VPN tunnels in an [onion route](https://en.wikipedia.org/wiki/Onion_routing) and can provide local traffic analysis.
* [The Orchid DApp](orchid-dapp/): The Orchid dApp allows you to create and manage Orchid Accounts. The operations supported by the account manager are simply an interface to the decentralized smart contract that holds the funds and governs how they are added and removed.
* [Security & Technical FAQs](faq/): Security, how our system works and other non-product frequently asked questions.


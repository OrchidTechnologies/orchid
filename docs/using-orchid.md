# How to Use Orchid

## Home Screen

The Orchid’s home screen is a representation of your device’s Internet connection. The switch in the upper right corner turns Orchid on and the middle section allows you to add and delete ‘hops’ which are VPN connections. On the bottom, there is a tab for Hops, which is the home screen and Traffic, which allows you to see information about the specific connection requests flowing through your phone.

The simplest configuration for Orchid is to use just one VPN connection. When configured with one hop, Orchid is similar to a typical VPN app, which can only connect to one VPN server at a time.

When you add multiple connections, Orchid uses layered encryption to route your traffic through each connection. If a multiple hop route is constructed, traffic flows through the hops from the top to the bottom. The Orchid app supports Orchid VPN connections as well as typical OpenVPN connections.

Add a hop by clicking on the Add Hop button in the middle of the screen and then going to the hop selection screen. To delete a hop, swipe it to the right or left.

Each hop to an Orchid node requires an Orchid account to pay for service. Read more about how to setup an Orchid account.

For more information about Orchid in general, read the About Orchid section. For information on what kinds of protections Orchid provides, read the Security and Privacy section.

## Hops

Orchid ‘hops’ are vpn connections to the Internet. Examples include a connection to an Orchid node or an OpenVPN connection to a VPN server. You can add and delete hops from the homescreen. Each hop will need a form of authentication to make the server connection.

Add a hop by clicking on the Add Hop button from the home screen and then selecting a way to add the hop. To add an Orchid hop, select "I have a QR code" if you generated a QR code from your Orchid account or select “I have an Orchid account” to manually input your Ethereum wallet address and generate a signing key that you can put into the app. To add an OpenVPN hop, select “I have an existing VPN subscription” and input the credentials.

### OpenVPN hops

Orchid supports OpenVPN. If you have an existing VPN provider, you can add a hop using OpenVPN credentials. To add an OpenVPN hop, click Add Hop -> I have an existing VPN subscription. Then enter your username, password and paste in the configuration for your OpenVPN connection.

### Orchid hops

Orchid has its own VPN wireline protocol, the Orchid protocol. The traffic to and from Orchid nodes uses the Orchid protocol. The traffic looks like webRTC traffic, which is advantageous for security and includes tiny nanopyments that flow with the traffic. To establish and maintain a VPN connection with an Orchid node, you will need a funded Orchid account.

Each Orchid node also has a curator — this is the curated list that is associated with the hop. When a connection is initiated, the curator creates a subset of the available Orchid nodes for the hop to create the connection.

The main component of the Orchid node is going to be the Orchid account associated with it. Each hop requires a valid Orchid account to continue to pay for VPN service.

## Orchid Account

Orchid accounts exist as entries in an Ethereum smart contract (the nanopayment contract) which holds the OXT for all users and pays providers. Funds exist on-chain so that VPN providers can verify that funds exist for the services they are providing and can claim those funds. Learn more about how our 2nd layer scaling solution works: [Introducing Nanopayments](https://blog.orchid.com/introducing-nanopayments/).

To setup, withdraw and add funds to the Orchid account, you must use a web3 enabled browser plugin such as Metamask or a DApp enabled wallet such as Trust Wallet. Orchid Labs hosts our wrapper for the Nanopayment smart contract at [https://account.orchid.com](https://account.orchid.com), which provides an easy way to setup and manage OXT funds for service. It is also possible to call the smart contract functions directly or to host the wrapper code on your own.

The OXT held in the Orchid account is split into the balance and a deposit. A majority of the funds go into the balance, which is then paid out for service. The deposit is required to accept service, and is used to cover potential overages. A minimal amount of OXT, typically 2-4 OXT is all that is needed in the deposit.

The Ethereum wallet connected via the web3 browser/DApp wallet is how the user is authenticated.

#### Setting up an Orchid account

An Orchid account consists of OXT that has been moved into the Orchid nanopayment smart contract. Once the account is setup, anyone with access to the account can send nanopayments backed by the OXT in that account. Setting up the account costs ETH in 'gas', so creating an Orchid account requires both OXT and ETH digital currencies.

#### Get OXT and ETH

You need the OXT digital currency to pay providers for service. 10 OXT is enough to get started and should provide approximately 60 Gigabytes of VPN service. You will also need approximately .005 ETH to pay for the two transactions on Ethereum that are required to setup the Orchid account. Right now,[Coinbase](https://www.coinbase.com/price/orchid) lists OXT and ETH. Free OXT is available through Coinbase's Earn campaign. Other places where OXT is available include Uniswap and other Ethereum exchanges.

Remember: You only pay for the service you use, so whenever you turn Orchid off you are no longer spending OXT from your Orchid account.

#### Add the OXT and ETH to a web3-enabled Ethereum wallet

Every Orchid account requires an Ethereum wallet from which to fund the account. We recommend setting up a new Ethereum wallet for using Orchid that is unassociated from other Ethereum services that you may use. We have tested and support a number of wallets, but some may work better than others depending on your setup. The easiest will be to setup your Orchid account using the Metamask browser plugin on a laptop or desktop.

Suggested wallets:

* [Metamask](https://metamask.io) - Our recommendation is to use the Metamask Chrome plug-in from a laptop or desktop.

* [Trust Wallet](https://trustwallet.com) - Works on Android and iOS.

* [Coinbase Wallet](https://wallet.coinbase.com) - Works on Android and iOS. Might lose DApp functions soon on iOS.

* [BRD Wallet](https://brd.com/) - Works on Android and iOS.

We recommend setting up a new wallet for use with Orchid for privacy.

Move your OXT and ETH to the new wallet you have setup. If you used Coinbase to earn or purchase your OXT and ETH, go into Coinbase and do a "send" from there to the Ethereum wallet's address. Moving both the OXT and ETH will cost a tiny amount of ETH in gas cost. You will need both in your wallet to create an Orchid account.

#### Create and fund an Orchid account

Your gateway to funding Orchid is found at <a href="https://account.orchid.com/">account.orchid.com</a>. The webpage is a web3-enabled front end that interfaces with the Orchid nanopayment contract. Account.orchid.com will need to be loaded with the Metamask plugin enabled or from your wallet's DApp browser. Once the page is loaded correctly, you can transfer funds between your wallet and Orchid. This is also where you can top-up your account balance or withdraw your funds after you have created an account and linked it to the app.

You will need a funded wallet with account.orchid.com loaded in order to create an Orchid account. Mobile wallets have a browser built into them, typically called a DApp browser. For the Metamask plugin, simply load the page with Metamask enabled and accept the connection request. It is a good idea to bookmark account.orchid.com so you can navigate back easily.

Read the text on the account.orchid.com page. The page is responsive and will tell you if you need to add more OXT or ETH to your wallet for account creation. Once ready, you can click or tap on the "Transfer Available OXT:" purple button which will initiate 2 transactions that you will need to approve.

Note- we recommend editing the transaction fee and paying extra ETH for "fast" so that the Orchid account is created within 30-60 seconds. Paying for slow sometimes can cause the transactions to hang.

Once your account is created, a QR code will appear on the page. If you don't see the QR code on the Overview page, it is available by clicking on the More link in the upper right of the page and selecting Info. From there you can see your account balance and the QR code.

#### Adding your Orchid account to the app

To add your newly created Orchid account, simply open the app and press the QR code icon on the initial help text pop. If that doesn't appear for you, select "New Hop" on the homescreen and then "I have a QR code" from the add hop screen. Scan or copy/paste the code into the app.

Once you scan the QR code, the app will create a hop using that Orchid account and your default curator settings. You will then be dropped into the hop information screen that shows the saved information. Using the "Share Orchid Account" button, you can pop a QR code and share the Orchid account you just created with other people or devices. Press the back arrow to get back to the main screen.

From the main screen, turn the toggle in the upper right to turn Orchid on.

# About Orchid

## What is Orchid?

Orchid is a decentralized, market-based system for anonymous communication and virtual private networking, including a bandwidth market where node providers stake tokens to advertise their services using the Ethereum blockchain and receive payment in OXT (Orchid’s native cryptocurrency).

## What is the purpose of Orchid?

Orchid’s mission is to build Open Source software that keeps the internet open and accessible — a natural resource for everyone, everywhere.

## How does it work?

The Orchid network enables a decentralized virtual private network (VPN), allowing users to buy bandwidth from a global pool of service providers.

To do this, Orchid uses an ERC-20 utility token called OXT, a new VPN protocol for token-incentivized bandwidth proxying, and smart-contracts with algorithmic advertising and payment functions. Orchid's users connect to bandwidth sellers using a provider directory, and they pay using probabilistic nanopayments so Ethereum transaction fees on packets are acceptably low.

# Orchid App FAQ

## Why do I need a new Ethereum wallet? Why can’t I use my main wallet?

While you could use your primary Ethereum wallet that you typically use for other Ethereum applications, we do not recommend it if you are seeking privacy with Orchid. The main reason is that using Orchid results in on chain payments flowing from your wallet to the Orchid nanopayment contract, and then on to VPN providers selling bandwidth. Ethereum on-chain analytics can easily link payments to/from the nanopayment smart contract and then to providers. If the source of the funds comes from your personal Ethereum wallet linked to other services, anyone using Etherscan would be able to see that you used Orchid and sent payments to VPN providers, when the occasional Orchid nanopayment system issues a winning ticket.

## Why should I trust a big exchange with my personal info? Would a decentralized exchange that doesn’t store my personal info be better?

While a decentralized exchange does not store your personal information that could link your source of funds to your identity, a decentralized exchange does typically require an Ethereum account with some sort of crypto such as ETH, which has its own history of transactions. If that ETH or wallet is linked to your identity, then the source of funds could be linked through the DEX back to your originating Ethereum wallet.

A large exchange typically has a ledger they use to keep track of ownership, with a hot wallet they use to send funds in and out of the exchange. While the exchange knows your identity, the movement of currency in and out of the exchange is anonymous, as the funds can’t be tracked to your identity on the blockchain without the exchange being hacked, subpoenaed or otherwise compromised.

## Why do I need ETH and OXT?

Orchid is a series of decentralized smart contracts and client software that uses Ethereum. Certain operations require the use of ETH for gas to power the smart contracts that run Orchid. For users who use the Orchid app, ETH is required when adding or removing funds from your Orchid account through the web3 browser interface.

## What is the difference between Balance and Deposit in my Orchid Account?

The balance is the collateral for the tickets sent from the user to the provider. Over time, as winning tickets are issued from your Orchid app, the Orchid account balance will drop. The deposit is the Orchid token held in escrow to disincentivize double spending on the network. This amount never depletes and can be withdrawn after a 24hr "unlock" period.

# Security and Privacy

## What protections does the Orchid app provide?

Basic Internet connections function by transmitting packets of data between two hosts (computers). In order to find their way, packets contain both a source and destination IP address. As packets move from the destination to the source, different routers and physical infrastructure require both of these addresses for the two-way connection to be established and maintained. This means that instantly and over time, the owners of the physical infrastructure are in a position to build a profile of Internet usage on their paying user (you!) and also to block content as the owner sees fit.

Typically these infrastructure owners are ISPs — mobile carriers providing phone data connections, home cable Internet providers, WiFi hotspot operators, and any Internet backbone operators that have peering agreements with user-facing ISPs. In all these cases, the ISP is in an advantaged position to monitor and/or restrict Internet usage. It is common in many countries for ISPs to restrict content so that users cannot load certain websites.

If you are not happy with or do not trust your existing ISP(s), by using Orchid you can currently limit their knowledge to knowing only that you are sending and receiving bytes through Orchid, and completely block their ability to mess with the details of your traffic, unblocking the previously blocked content. They either block all of Orchid or nothing, so if things continue to work after turning on Orchid, then your ISP has allowed "Orchid in general" and cannot manipulate the individual bytes between you and the rest of the Internet, granting you access to the entire Internet.

## How can the Orchid app help me with privacy today?

The goal with the Orchid app is to give users insight and control over the network connection of their device. To gain privacy, users configure a circuit in Orchid by setting up an Orchid account and funding it with OXT. Then the Orchid app connects to the Orchid network and selects a node using Orchid’s [linear stake-weighted algorithm](https://blog.orchid.com/orchids-network-random-selection-stake-weighting/) to serve as a VPN and pays for bandwidth via a continuous stream of tiny OXT [nanopayments](https://blog.orchid.com/introducing-nanopayments/).

In a single-hop circuit configuration, Orchid provides:

* Protection from websites seeing your real IP address and physical location

* Protection from the ISP seeing what websites you are visiting and when

* Access to the open Internet--once a user can connect to Orchid, they are not restricted by ISP level firewalls and can browse the entire Internet freely

A potential problem with using only a single VPN provider is that the provider running the single node circuit knows both your IP address and the content you are accessing. If the provider maintains logs, those logs could be sold to advertisers or otherwise used against you. In the current VPN marketplace, it is hard to know who is maintaining logs and who is not. For Orchid nodes, we have developed a flexible curation system that gives users a way to pick whom to trust. Read about [curated lists here](https://www.orchid.com/faq#technology--how-do-curated-lists-work).

Another solution is to trust no single provider with enough information to know both who you are and what information you are accessing. To that end, Orchid supports an advanced feature that allows users to configure multi-hop routes by stringing together multiple nodes into a flexible multi-hop circuit. Orchid currently supports several underlying protocols including the native Orchid VPN protocol and OpenVPN, allowing users to mix and match Orchid nodes with traditional VPN nodes.  While the potential is there to protect the user from any one provider knowing enough information to reveal their circuit, this is an advanced feature that is currently "use at your own risk".

## How is Orchid private given that it has public payments on Ethereum?

The Orchid app pays for the circuit by sending a continuous stream of tiny nanopayments to providers for the duration of the connection. While the [nanopayment architecture](https://blog.orchid.com/introducing-nanopayments) locks user funds into a smart contract and only issues on-chain payments to providers very rarely, occasional winning tickets do result in OXT macro-payments posted on the public Ethereum blockchain. When that happens, the user’s Ethereum address, the provider’s Ethereum address, and a timestamp are stored publically on the Ethereum blockchain. Note that the payment address of the provider is not a mapping to any single server; instead it is an arbitrary (and potentially temporary) payment address that the provider created specifically to receive funds. Also, the frequency of how often on-chain payments occur is configurable.

All information gained by a potential network attacker is an advantage. However, consider exactly what information is revealed. For an Orchid user running a single hop circuit: the provider sees the user’s payment address when it accepts service, along with the user’s real IP address and the destination addresses that the user is connecting to (if it maintains logs). Once a rare on-chain payment is made, the user’s payment address and provider’s payment address are stored on Ethereum with a timestamp available to the public.

When considering anonymity, it is important to understand if the user is linked to the OXT used in their circuit. Worst case, if the user purchased OXT on an exchange with their real identity, or the VPN provider used in the circuit maintained logs, then either of those two entities could be compelled to give information that could deanonymize the user. Similarly, a user who paid for a VPN service that maintained logs with a credit card could be deanonymized with just one entity being compelled.

A multi-hop circuit affords greater network protections, but to setup a multi-hop Orchid circuit, it would be naive to pay for each hop from the same Ethereum wallet. In that configuration, each provider would be able to see that wallet’s address and potentially use that address to get information about the user. To mitigate that, a better way to setup multi-hop circuits would be to use different wallet addresses for each Orchid hop. If every wallet address is independently dissociated from the user, the full circuit might be quite difficult to link back to the user. Again, multi-hop circuits in Orchid are an advanced feature; use at your own risk.

Orchid is working on additional features to mitigate payment leakage, such as onion payment routing.  The idea of this technique is to help obfuscate payments by routing them through several layers of indirection (paying Alice to pay Bob to pay Charlie). The payments then take a different random route than the traffic, preventing the rare occasional public payment records from indirectly revealing route information.

## Can Orchid nodes monitor network traffic?

Yes, providers on Orchid could monitor the bytes that come in and out of the Orchid node. However, all traffic carried over Orchid between hops from the user to the exit is encrypted at the Orchid protocol level, which is an additional layer of encryption. The final exit traffic is then decrypted by the exit node and sent to the destination. In many cases the underlying traffic will also be encrypted with protocols such as TLS, providing at least two layers of encryption.


However, not all traffic on the Internet is encrypted and Orchid doesn’t fix that problem. The last hop configured in the active circuit will need to send the user requests out onto the Internet. So if the user sends an HTTP request, which has no SSL/TLS encryption, Orchid will honor that request and cleartext information would be revealed to the Orchid node. For this reason, you should always use SSL/TLS for sensitive Internet connections, even on Orchid. And even SSL/TLS encryption leaves metadata that the Orchid node could monitor, including the destination address, hostname, packet sizes and the timing of packets.

Using Orchid’s multi-hop feature with a three hop circuit would compartmentalize the information any one provider could monitor. With a properly configured multi-hop circuit the origin and destination of the traffic would be anonymized from any one provider, however, that is an advanced feature which is currently "use at your own risk". The way the different Orchid hops are funded has an impact on information leakage that could potentially de-anonymize.

Lastly, the Orchid client randomly selects from a "curated list" of providers. This adds an additional layer of protection as users could pick or make their own curated list of providers that they trust or someone that they trust, trusts. Orchid has a default list of trusted providers that ships with the Orchid app.

## So I'm totally private and anonymous when I use a VPN like Orchid?

**No.**

Orchid is a tool that keeps private certain types of information from ISPs, websites, and providers. Orchid adds layers that separate you from the content you are trying to access. If you login to Amazon, the website will know that it is you and can build out information about what you are doing on their website, even with Orchid enabled. However, your local ISP or network provider will not know you are visiting Amazon. Amazon will not know where you are in the world, and will not get your real IP address. If using at least three hops, no single provider will know your IP address and know that you are accessing Amazon.

Also consider that Orchid is a VPN and that all VPNs have vulnerabilities at the software level. Typical modern browsers that are not "hardened" run all sorts of “active content” such as Java, Javascript, Adobe Flash, Adobe Shockwave, QuickTime, RealAudio, ActiveX controls, and VBScript and other binary applications. This code runs at the operating system level with user account access, meaning they can access anything your user account can access. These technologies could store cookies, bypass proxy settings, store other types of data and share information directly to other sites on the Internet. Therefore, these technologies must be disabled in the browser you are using to improve your security in conjunction with using Orchid.

Other metadata such as the size of the browser window, type of pointing device used and other unique information could be used to "fingerprint" the user and potentially de-anonymize. These browser fingerprinting attacks could affect any VPN users, Orchid included. Hardened browsers can help reduce or eliminate the user’s visible browser fingerprint.

Also certain apps or code running on your device could send de-anonymizing data out to the Internet or third parties. No VPN can prevent attacks from arbitrary software running on your device, such as malware or a virus.

Furthermore, there is active network security research into "traffic fingerprinting" attacks that attempt to reveal private information by monitoring encrypted connections. By watching the timing and size of packets, an adversary monitoring an encrypted connection could get a good idea if a particular user is watching a video, browsing the Internet or downloading a large file, just based on the timing and size of packets. Further analysis could reveal what websites are visited by seeing the sequence of things that are loaded— again, the timing and size of packets along with when requests are made.

Orchid is researching "bandwidth burning" and related techniques to help obfuscate a user’s traffic against these advanced packet timing and size analysis attacks.

# On Technology

## How does the Orchid token (OXT) work?

OXT is a "pre-mined" cryptocurrency based on the ERC-20 standard that will be used to decentralize trust between buyers and sellers in the Orchid marketplace. It also functions as a tool to promote security and healthy market dynamics, as providers can adjust their OXT stake to remain competitive. At launch we intend there to be a limited supply of one billion (1,000,000,000). We do not intend ever to create any additional OXT.

## How do curated lists work on Orchid?

The Orchid client calls an on-chain ‘curated list’ function which filters the viable nodes on Orchid (that is, nodes that have properly staked) into a custom subset. Initial releases of the official Orchid client will use this feature to prevent certain kinds of attacks from malicious exit nodes (e.g. SSL downgrade attacks) by using a default list consisting of trusted VPN partners.

Overall, the curated lists are a federated reputation solution for determining what VPN providers on Orchid you can trust. The system is fully programmable, exists on-chain and is Turing complete. The list function can take information as an argument, and then use that information to determine, for any given Orchid node, whether you want to connect to that node or not.

Customized Orchid clients can use their own lists, the official Orchid client can select from different lists and eventually we expect well known third parties to emerge as curators. Given that this system is on-chain, an entity such as a DAO could manage a list too.

The curated list mechanism is a means for the importation of external reputational trust to supplement the economic incentive based trust provided by node staking.

## What is the Orchid Protocol?

The Orchid software is designed to use a custom VPN protocol, similar in scope to OpenVPN or WireGuard. The Orchid protocol is designed for high-performance networking and runs on top of WebRTC, a common web standard, widely used to transmit video and audio from inside browsers. Our protocol is intended to allow users to request access to remote network resources and pay for these resources using OXT via a nanopayments system.

# Staking

## What is Staking in Orchid?

Staking is a process where one deposits and locks up an asset into an illiquid contract or mechanism in exchange for revenue or rewards.  Orchid providers stake OXT tokens in an Ethereum smart contract (the directory) to advertize their services to clients.  Orchid clients then select providers randomly, weighted by proportional stake, so that the probability of picking a particular provider is equal to their fraction of the total stake.

Anyone else can also stake on a provider’s address, allowing a form of "delegated staking".  Any OXT holder can stake their OXT tokens on providers of their choosing.  There are no automatic benefits of staking on someone else’s behalf, but the staking mechanism could be combined with a revenue sharing contract between the staker and the stakee.

## Is Orchid Staking like Proof of Stake?

Staking in Orchid is similar to proof of stake systems only in the sense of using stake as a linear weighting mechanism.  In most proof-of-stake systems stakeholders can automatically earn revenue just by running nodes with stake.  Orchid has no such automatic mechanism, and has no inflation to fund staking.  The only source of income on Orchid is customers paying for bandwidth.

## How can I earn passive revenue on my OXT?

You can find an Orchid bandwidth provider who is seeking staking partners in exchange for a share of revenue or recurring payments - using any on-chain or off-chain mechanism.

An Ethereum smart contract can be used to help automatically split revenue between a staker and a provider. The staker would stake on the smart contract, and the provider would direct client payments to the smart contract, which would then allow each party to withdraw some parameterized fraction of the funds.

Note that any such delegated staking arrangement (even using on-chain mechanisms) can not guarantee that the provider will actually honor the contract: the provider could easily direct clients to a different payment address. And even if the provider is perfectly honest, there is still ultimately uncertainty in revenue and consequent return on stake.

As an alternative to revenue sharing, providers could send recurring payments to the staker - essentially a stake rental or leasing arrangement.  In this case the return is more predictable, but there is still no guarantee that the provider will make the scheduled payments.  Again a smart contract could be used to help automate the payments, but can not guarantee the provider will have the necessary funds.  There is always risk.

When a staker decides to repoint their stake to a different provider, there is a lengthy withdrawal delay (currently about 3 months).  So it is important for stakers to choose providers carefully.  Stakers should start with small allocations and slowly increase them based on measured profitability.

Eventually third party websites could provide an interface to help simplify and automate the process of finding, evaluating and staking on Orchid bandwidth providers.
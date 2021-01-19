![](gui-orchid/assets/images/3.0x/name_logo.png "Orchid Logo")

Overview
========
The Orchid network enables a decentralized virtual private network (VPN),
allowing users to buy bandwidth from a global pool of service providers.

To do this, Orchid uses an ERC-20 utility token called OXT, a new VPN protocol
for token-incentivized bandwidth proxying, and smart-contracts with algorithmic
advertising and payment functions. Orchid's users connect to bandwidth sellers
using a provider directory, and they pay using probabilistic nanopayments so
Ethereum transaction fees on packets are acceptably low.

Vision
======
Our vision is to enable secure access to the internet for everyone, everywhere.
Over the coming months, we’ll be releasing more features in our suite of
privacy-enabling tools. We are working towards a decentralized marketplace for
VPN service.

This Repository
===============
This open source repository is a mono-repo containing all of Orchid's open
source technology including Ethereum smart contracts, server software, and
client applications. More specifically it contains:

- [Nanopayments contract](dir-ethereum)
- [Android client](app-android)
- [iOS client](app-ios)
- [macOS client](app-macos)
- [Windows client](app-windows)
- [Linux client](app-linux)
- [Orchid server](srv-shared)

How to Get Involved
===================
The core maintainers welcome pull requests that improve on or fix:

- Build the [Android client](app-android) from source and report any dependency issues or bugs identified
- Beta test the [Linux client](app-linux) from the latest [release](releases)
  - Create issues for bugs identified, ideally with a fix identified if possible

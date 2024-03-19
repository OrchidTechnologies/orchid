# Orchid

Orchid is a platform that enables an onion routing network incentivized by OXT and a multi-hop VPN client. The Orchid community believes in Open Source software and that Orchid can enable a brighter, freer and empowered future.

The heart of the platform is a decentralized marketplace "for bandwidth" consisting of providers, a directory of providers, and client applications.

## How does it work?

**Providers** provide the relay service by running their own servers *(`/srv-daemon`)*. The relays then advertise themselves to the decentralized directory running on Ethereum.

The **directory** runs on Etherereum *(`/dir-ethereum`)* and provides all necessary information of available relays for the client to use to connect to.

The client VPN **application** *(`/app-`, `/vpn-`, `/cli-shared`)* is used to connect to the directory, fetch an available relay, and to establish the VPN connection with.

**Payments** are made for accessing the network via *(streaming) probablistic nanopayments*, an L2 Ethereum scaling solution best described as being between *one-to-many payment channels* and *probablistic roll-ups*. 

>[!NOTE]
> The payment solution was a culmination of thorough economic incentive research, design and practical integration. If it interests you for your integration into your own project, you can find the modularized integration in *(`/lot-ethereum`)*.


## Compiling Orchid

Orchid is simple to compile as every library dependency of Orchid is included as a git submodule, and is compiled by the Orchid build system so there there is no need for a lengthy DEPS lists. This means there are **no external steps** you often see with other C/C++ projects!

>[!IMPORTANT]
> Don't forget to run `git submodule update --init --recursive`


### Requirements

* Make sure you have the requisite build tooling installed in addition to the standard set of C/C++ development tools (`autotools`, `bison`/`flex`, `make`, etc.).
* We specifically require `clang` *(sorry, no gcc for now!)* and `ldd` *(neither `binutils ld` nor `gold` were sufficient!)*.
* Some of the build scripts for our dependencies require `Python` *(3.x)*
* One build script requires using `meson`/`ninja`
* A couple libraries are written in `Rust`

>[!NOTE]
> *Directions for installing and configuring any of the above toolchains is out of scope of these instructions as they are different for every operating system, Linux distribution, and often have specific versions for specific distributions. If you're a developer and don't already have these installed, you'll need to refer to the documentation for those tools.*

If you experience any issues while building, it's usually fixed by simply installing whatever is noted as missing.

Optionally, there are build scripts available for limited scenarios that may work for you *(`env/setup-mac.sh` for Mac, `env/setup-lnx.sh` for Ubuntu)*.

## Building yourself

Go into any subfolder *(e.g. `app-{android,ios}`, `cli-shared/srv-daemon`)* and run `make`.

If you experience any issues (e.g. memory / disk space, command not found, etc) feel free to file a new issue.

## Using Docker

Run `env/docker.sh` instead of `make`. You do still need to have checked out the full source code (including the submodules!).

## Join the community

If you have technical issues related to build problems of this repo, please file an issue on Github.

If you have any questions or want to meet others in the Orchid community however, visit us on:

* [Discord](https://discord.com/invite/GDbxmjxX9F)
* [Telegram](https://www.t.me/OrchidOfficial)
* [X/Twitter](https://x.com/OrchidProtocol)
* [Reddit](https://www.reddit.com/r/orchid/)
* [Facebook](https://www.facebook.com/OrchidProtocol)
* [Youtube](https://www.youtube.com/channel/UCIH_BKBlNemsCzDhPYZBlHw)
* [Linkedin](https://www.linkedin.com/company/orchid-labs/)
* [Github](https://github.com/OrchidTechnologies)


---

**Orchid software is [AGPLv3](https://www.gnu.org/licenses/agpl-3.0.en.html) licensed open source that builds off of many off-the-shelf transport protocols (WebRTC, layered UDP, etc) and can be modified for your own needs.**


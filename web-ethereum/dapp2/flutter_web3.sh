#!/bin/bash

cd $(dirname "$0")

# Create our patched version of the flutter_web3 package.
# https://github.com/y-pakorn/flutter_web3/issues/56
#
if [ -d flutter_web3 ]
then
    echo "flutter_web3 package exists."
else
    echo "Fetching and patching flutter_web3 package."
    git clone https://github.com/y-pakorn/flutter_web3.git 
    cd flutter_web3
    git checkout 0e589c069
    git apply ../flutter_web3.patch
    cd ..
fi

# JS Lib required by flutter_web3
if [ -d ethers ]
then
    echo "ethers already exists."
else
    echo "Fetching ethers js"
    mkdir ethers
    curl 'https://cdn.ethers.io/lib/ethers-5.4.umd.min.js' > 'ethers/ethers-5.4.umd.min.js'
    curl 'https://raw.githubusercontent.com/ethers-io/ethers.js/main/LICENSE.md' > 'ethers/ethers-5.4.umd.min.js.LICENSE.txt'
    cp ethers/*.js ethers/*.LICENSE.txt build/web/
fi

# Build our WalletConnect JS integration
cd walletconnect
sh build.sh
cp dist/*.js dist/*.LICENSE.txt ../build/web/
cd ..


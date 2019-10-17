# Deploying the Orchid DAPP

## Building the Site
```sh
cd tst-ethereum/web3/fund_dapp/
bash scripts/npm-install.sh # Install Dependencies
bash scripts/build.sh
```

The web application is now available in the `web/` directory

## Uploading to the Server
  IPFS requires that at least one server is running, accessible, and has a copy of the files stored in IPFS.
  Orchid Labs fulfills this requirement by running an EC2 server at dapp.orchid.com.
  Uploading to the server will require that your SSH key has been granted access.
  
```sh
rsync -avzh --progress --delete web ubuntu@dapp.orchid.com:~
```

## Update IPFS

```sh
ssh ubuntu@dapp.orchid.com
ipfs add -r web
```

There should be output similar to the following

> $ ipfs add -r web
> added QmTEDfHEgjMG2mhZEqCLuScsUEjim4ddjnu67F3BE7Lrey web/accordion-style.css
> added QmXDb2LagBnbknPQvt9Wp8ipvUSntQF1dh4AJmqAdmnNGh web/app.js
> added QmfPMAPWS7Urwsr9PpCcnvJ6gzVD46KCH1yJnaTsttU6Hn web/assets/name_logo.png
> added QmVqekncLDHjYTyTdguHRVPGs5zw8nKVLSu6qqVGdt45pK web/assets/wallet.png
> added QmXJprhmQevaTUjsoWix3vm1BYa9eubohBwkjf47zbbbpW web/bundle.js
> added QmYgE4hsr5e8tQoBThRfscB5Sy21aPurdsHBDQ8HscaD3E web/button-style.css
> added QmNkkc9tZCpAacUGEQ1bV872NTZAUbMm7M6tmAnM2mv6hW web/form-style.css
> added QmcB2GkHbwcwbQ1YjJyZEqXuVYXQGPeMPRzg6ULLjn8LK5 web/index.html
> added QmXcc7XWfEDUF8fK6Fo549BNuBHAbyRqnhHT4jw3FuQMHj web/orchid-contracts.js
> added QmQtg5GVDk4CP1mu1iobWPSMGNoUbR8Fn94b9gtNYhtaH8 web/orchid.js
> added QmPwcxjB9FvNnRNdkBx2sau3c4KxaACDb2E5LAAQSmtZze web/assets
> added QmbCkegpiz58p3bAg48VfxiqFa88tfMX476kD9H4y69ACk web
>  2.86 MiB / 2.86 MiB [===============================================================================================================================================================================================================] 100.00%

The `added QmbCkegpiz58p3bAg48VfxiqFa88tfMX476kD9H4y69ACk web` is the one that matters.
Make a note of the hash in the middle.

The DAPP can be accessed at `http://gateway.ipfs.io/ipfs/<hash>` (i.e. http://gateway.ipfs.io/ipfs/QmbCkegpiz58p3bAg48VfxiqFa88tfMX476kD9H4y69ACk)

## Publish to IPNS

From the dapp.orchid.com EC2 instance, run the following command to publish the site to IPNS

```sh
ipfs name publish <hash>
```

Be sure to replace `<hash>` with the hash you received earlier on (i.e. `QmbCkegpiz58p3bAg48VfxiqFa88tfMX476kD9H4y69ACk`).

This will show output similar to the following

> $ ipfs name publish QmbCkegpiz58p3bAg48VfxiqFa88tfMX476kD9H4y69ACk
> Published to QmPq88cdgHaBhUY6pU5sCjk8xua68P5YAzsc9aCdhai6KV: /ipfs/QmbCkegpiz58p3bAg48VfxiqFa88tfMX476kD9H4y69ACk

Make a note of the hash that the site was published to (`QmPq88cdgHaBhUY6pU5sCjk8xua68P5YAzsc9aCdhai6KV`)

You should now be able to access the DAPP at `http://gateway.ipfs.io/ipns/<hash>` (i.e. http://gateway.ipfs.io/ipns/QmPq88cdgHaBhUY6pU5sCjk8xua68P5YAzsc9aCdhai6KV)

## Update DNS

For convenience, there is a dapp.orchid.com DNS TXT record managed by AWS Route53.
This needs to be updated to have a value of `dnslink=/ipns/<hash>`,
where `<hash>` is the value obtained in the previous step (i.e. `dnslink=/ipns/QmPq88cdgHaBhUY6pU5sCjk8xua68P5YAzsc9aCdhai6KV`).
Making this change will require having a proper set of AWS IAM User credentials.

This allows accessing the DAPP at http://gateway.ipfs.io/ipns/dapp.orchid.com

## dapp.orchid.com DNS Record

dapp.orchid.com is a DNS A record that points to the EC2 instance hosting our site.
By running an IPFS daemon that listens on port 80 on this host, requests to dapp.orchid.com get properly routed to the site running on IPFS.

# Orchid funding test: min web.

## Install

```bash
npm install -g browserify # once
npm install --ignore-scripts # on package.json changes
```

## Build

```bash
scripts/build.sh
# browserify web/app.js web/contracts.js web/orchid.js -o web/bundle.js  
```

## Serve the files

e.g.
```bash
php -S 192.168.1.2:8123
```
URL example:
```
http://192.168.1.2:8123/web/?pot=0x405BC10E04e3f487E9925ad5815E4406D78B769e&amount=2
```


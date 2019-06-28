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
php -S 192.168..2:8123
```


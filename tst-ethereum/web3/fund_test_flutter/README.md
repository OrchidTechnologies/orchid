# Orchid funding test: Flutter for Web

## Install

```bash
flutter pub get
```

## Build the JS bundle

```bash
scripts/install-npm.sh
scripts/build.sh
```

## Run the development server

```bash
flutter pub global run webdev serve --auto restart
```

Or production mode and bound to a specific interface for device testing:

```bash
flutter pub global run webdev serve --release --auto restart --log-requests --hostname 192.168.1.2:8123
```


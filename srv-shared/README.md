# orchidd: Compiling the Orchid Server
## Linux (Ubuntu)

```
sudo apt-get update
sudo apt-get install \
     bison \
     flex \
     gettext \
     gperf \
     groff \
     ninja-build \
     python3-pip \
     python3-setuptools \
     tcl
sudo pip3 install meson==0.51.2l
git clone https://github.com/OrchidTechnologies/orchid.git
cd orchid/
git submodule update --init --recursive
make -C srv-shared
```

## macOS
```
/usr/bin/ruby -e \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install meson autoconf automake libtool
brew link --force gettext
pip install pyyaml
git clone https://github.com/OrchidTechnologies/orchid.git
cd orchid/
git submodule update --init --recursive
make -C srv-shared
```


# Building for iOS

Orchid for iOS is built from the command line, not from the XCode GUI.  It
depends on many other open source libraries.  Rather than assume that your
laptop environment has the right versions of things, we compile all of the code
that we need directly from the source for the iOS platform.

So, before you can build the application, you will need to download the sources
of the dependencies.  You do that with

```bash
git submodule update --init --recursive'
```

The git servers providing the sources live at various places around the
Internet.  You can see these locations directly by viewing the `submodule`
stanzas in the file `.git/config`.  If, in the course of pulling down these
sources, a server is found to be offline, you'll need a workaround.  For
example,
some of the dependencies live at `git.savannah.gnu.org`, or at
`git.savannah.nongnu.org`.  If one of these sites down while you are trying to
get those submodules that are hosted there, you will have to get the software
from somewhere else.  One straighforward way to do that is to tell `git` that
you want to use a different location than the one specified in the local
`.git/config` file. Here's an example of how you could override the official
locations of `gnulib` and `libiconv` with a temporary change to your personal
`~/.gitconfig` file:

## From the command line:
```bash
git config --global url."https://github.com/coreutils/gnulib.git"].insteadOf "git://git.savannah.gnu.org/gnulib.git"
git config --global url. "https://gitlab.com/pffang/libiconv.git"].insteadOf "https://git.savannah.gnu.org/git/libiconv.git"
```

## Or, by directly editing your `~/.gitconfig` file to add the following
stanzas:
```config
[url "https://github.com/coreutils/gnulib.git"]
	insteadOf = git://git.savannah.gnu.org/gnulib.git

[url "https://gitlab.com/pffang/libiconv.git"]
	insteadOf = https://git.savannah.gnu.org/git/libiconv.git
```

Once you have the submodules downloaded, you'll need to configure the developer
signing identity that Apple will use. To set up this part of the build, copy
`identity.mk.in` to `identity.mk`. Then edit the `identity.mk` file. You'll
need your Apple developer information. Get your Team ID from here:
https://developer.apple.com/account/#/membership.

## Install Prerequisites
We need to ensure that you have the build tools on your MacOS-based machine to
complete the build successfully. If you don't have `homebrew` installed,
please follow the instructions at https://brew.sh:

```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Once homebrew is installed, you can use it to install the rest of the software
tools that you'll need.  You'll have to have a python3 around, and proably a
python2.

```bash
brew install python3
```

The system python should be fine for python2.

```bash
pip install pyyaml
brew install gettext
brew link --force gettext
brew install libgpg-error
pip3 install meson
pip3 install ninja
```

## Running `make`
Okay, we're ready to build the application:

```bash
make all-app-ios
```

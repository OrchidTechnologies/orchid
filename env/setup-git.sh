#!/bin/bash
set -e
# XXX: GNU Savannah's https:// endpoints are flakey, so temporarily use (insecure) git:// endpoints :(
git config --global url."git://git.savannah.gnu.org/".insteadOf "https://git.savannah.gnu.org/git/"
git config --global url."git://git.savannah.nongnu.org/".insteadOf "https://git.savannah.nongnu.org/git/"
git config --global advice.detachedHead false

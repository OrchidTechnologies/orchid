# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


.DELETE_ON_ERROR:
.SECONDARY:
.SECONDEXPANSION:
.SUFFIXES:

MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

SHELL := /bin/bash

empty := 
space := $(empty) #
comma := ,
percent := %

pwd := .
pwds := 

define directory
$(patsubst %/,%,$(dir $(1)))
endef

define include
$(eval pwds := $(pwd) $(pwds))$(eval temp := $(pwd))$(eval pwd := $(pwd)/$(call directory,$(1)))$(eval include $(temp)/$(1))$(eval pwd := $(word 1,$(pwds)))$(eval pwds := $(wordlist 2,$(words $(pwd)),$(pwds)))
endef

define loop
$(foreach i,$(2),$(eval $(call $(1),$(i))))
endef

define first
$(firstword $(subst /,$(space),$(1)))
endef

define rest
$(eval temp := $(subst /,$(space),$(1)))
$(subst $(space),/,$(wordlist 2,$(words $(temp)),$(temp)))
endef

# XXX: implement a split and then reimplement specific in terms of it

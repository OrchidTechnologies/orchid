# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


export PATH := $(CURDIR)/$(pwd)/path:$(PATH)
path = $(1)

.PHONY:
all:

include $(pwd)/uname.mk

version := $(shell $(pwd)/version.sh)
monotonic := $(word 1,$(version))
revision := $(word 2,$(version))
package := $(word 3,$(version))
version := $(word 4,$(version))

export SOURCE_DATE_EPOCH := $(monotonic)

archs := 
each = $(call loop,_,$(archs))

cflags := 
qflags := 
rflags := 
lflags := 
wflags := 
xflags := 

source := 
linked := 
header := 
sysroot := 

output := out-$(target)
archive := 

qflags += -gfull -Os
cflags += -DNDEBUG
qflags += -fno-omit-frame-pointer

cflags += -D_FORTIFY_SOURCE=2
# XXX: -fstack-protector-{strong,all}
# XXX: -param=ssp-buffer-size=4
# XXX: -fsanitize={shado,safe}-stack
# XXX: -fstack-clash-protection

cflags += -D__STDC_CONSTANT_MACROS
cflags += -D__STDC_FORMAT_MACROS

cflags += -Wall
cflags += -Werror
cflags += -Wno-unknown-warning-option

cflags += -Wno-deprecated-coroutine
cflags += -Wno-deprecated-volatile
cflags += -Wno-range-loop-analysis

cflags += -Wno-bitwise-op-parentheses
cflags += -Wno-dangling-else
cflags += -Wno-empty-body
cflags += -Wno-logical-op-parentheses
cflags += -Wno-misleading-indentation
cflags += -Wno-missing-selector-name
cflags += -Wno-overloaded-shift-op-parentheses
cflags += -Wno-potentially-evaluated-expression
# XXX: cflags += -Wno-shift-op-parentheses
cflags += -Wno-tautological-constant-out-of-range-compare
cflags += -Wno-tautological-overlap-compare

cflags += -fmessage-length=0
cflags += -ferror-limit=0
cflags += -ftemplate-backtrace-limit=0
cflags += -fmacro-backtrace-limit=0
cflags += -fdiagnostics-show-note-include-stack

beta := false

usr := /usr/local

include $(pwd)/checks.mk

include ../default.mk
-include ../local.mk
include ../setup.mk

ifeq ($(filter nostrip,$(debug)),)
lflags += -Wl,-s
endif

ifeq ($(filter nocompress,$(debug)),)
zflags := -9
else
zflags := -0
endif


objc := false
include $(pwd)/target-$(target).mk

ifeq ($(machine),)
machine := $(default)
endif

ifneq ($(target),win)
# XXX: this breaks libgcrypt due to cet.h being ELF-specific
more/x86_64 += -fcf-protection=full
endif

# XXX: this broke ARM iOS/macOS exception handling in coroutines
# XXX: consider using =pac-ret+leaf
#more/arm64 += -mbranch-protection=standard


define depend
$(foreach arch,$(archs),$(eval $(output)/$(arch)/$(1): $(patsubst @/%,$(output)/$(arch)/%,$(2))))
endef

define preamble
$(eval temp := $(subst /,$(space),$*))
$(eval arch := $(firstword $(temp)))
$(eval folder := $(subst $(space),/,$(wordlist 2,$(words $(temp)),$(temp))))
endef
specific = $(eval $(value preamble))


cflags += -I@/extra
cflags += -I$(output)/extra

cflags += -I@/usr/include


# I doubt this will ever become important, but just in case: v8 had this idea ;P
#qflags += -D__DATE__= -D__TIME__= -D__TIMESTAMP__= -Wno-builtin-macro-redefined

# -fdebug-compilation-dir .
# -no-canonical-prefixes

# XXX: I don't remember what this was actually for
qflags += -ffile-prefix-map=./=
# XXX: I need to verify the lack of trailing slash
qflags += -ffile-prefix-map=$(CURDIR)=.

rflags += --remap-path-prefix=$(CURDIR)/$(output)/cargo/=~/.cargo/

# putting -fno-ident directly into qflags breaks cmake
qflags += --config=$(CURDIR)/$(pwd)/fnoident.cfg


$(output)/%/extra/revision.hpp: force
	@mkdir -p $(dir $@)
ifeq ($(filter nodiff,$(debug)),)
	@env/revision.sh $(if $(filter nolist,$(debug)),--) $(cc) $(more/$*) $(wflags) | xxd -i >$@.new
else
	@echo >$@.new
endif
	@if [[ ! -e $@ ]] || ! diff -q $@ $@.new >/dev/null; then mv -f $@.new $@; else rm -f $@.new; fi

# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pwd := ./$(patsubst %/,%,$(patsubst $(CURDIR)/%,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))

wireshark := 
c_wireshark := 

wireshark += $(wildcard $(pwd)/wireshark/epan/*.c)
wireshark += $(wildcard $(pwd)/wireshark/epan/crypt/*.c)
wireshark += $(wildcard $(pwd)/wireshark/epan/dfilter/*.c)
wireshark += $(wildcard $(pwd)/wireshark/epan/dissectors/*.c)
wireshark += $(wildcard $(pwd)/wireshark/epan/ftypes/*.c)
wireshark += $(wildcard $(pwd)/wireshark/epan/wmem/*.c)

wireshark += $(wildcard $(pwd)/wireshark/wiretap/*.c)
wireshark += $(wildcard $(pwd)/wireshark/wsutil/*.c)

wireshark += $(pwd)/wireshark/cfile.c
wireshark += $(pwd)/wireshark/frame_tvbuff.c
wireshark += $(pwd)/wireshark/version_info.c

ifeq ($(target),and)
# XXX: end??ent was added with SDK level 26
# we should attempt to call it, if possible
cflags_privileges += -D'endpwent()='
cflags_privileges += -D'endgrent()='

# XXX: ws_pipe uses getdtablesize(), which
# is a broken API not supported on Android
wireshark := $(filter-out \
    %/ws_pipe.c \
,$(wireshark))
endif

ifneq ($(target),w32)
wireshark := $(filter-out \
    %/file_util.c \
    %/win32-utils.c \
,$(wireshark))

c_wireshark += -DHAVE_ALLOCA_H
c_wireshark += -DHAVE_ARPA_INET_H
c_wireshark += -DHAVE_FCNTL_H
c_wireshark += -DHAVE_GRP_H
c_wireshark += -DHAVE_MKSTEMPS
c_wireshark += -DHAVE_PWD_H
c_wireshark += -DHAVE_UNISTD_H
endif

ifneq ($(msys),darwin)
wireshark := $(filter-out \
    %/cfutils.c \
,$(wireshark))
endif

wireshark := $(filter-out \
    %/exntest.c \
    %/tvbtest.c \
    %_test.c \
,$(wireshark))

source += $(wireshark)
cflags += -I$(pwd)/wireshark
c_wireshark += -I$(pwd)/extra

c_wireshark += -D'DATA_DIR=""'
c_wireshark += -D'EXTCAP_DIR=""'
c_wireshark += -D'PLUGIN_PATH_ID=""'

c_wireshark += -D'PACKAGE="wireshark"'
c_wireshark += -D'VERSION="0.0.0"'
c_wireshark += -D'VERSION_MAJOR=0'
c_wireshark += -D'VERSION_MINOR=0'
c_wireshark += -D'VERSION_MICRO=0'

c_wireshark += -Wno-pointer-sign

c_wireshark += -I$(pwd)/wireshark/epan
c_wireshark += -I$(pwd)/wireshark/epan/dfilter
c_wireshark += -I$(pwd)/wireshark/epan/dissectors
c_wireshark += -I$(pwd)/wireshark/epan/ftypes
c_wireshark += -I$(pwd)/wireshark/tools/lemon
c_wireshark += -I$(pwd)/wireshark/wiretap


$(output)/$(pwd)/wireshark/epan/ps.c: $(pwd)/wireshark/tools/rdps.py $(pwd)/wireshark/epan/print.ps
	@mkdir -p $(dir $@)
	$^ $@

source += $(output)/$(pwd)/wireshark/epan/ps.c


$(output)/$(pwd)/wireshark/epan/dissectors.c: $(pwd)/wireshark/tools/make-regs.py $(filter $(pwd)/wireshark/epan/dissectors/%.c,$(wireshark))
	@mkdir -p $(dir $@)
	@echo [EX] $(target) $<
	@python3 $< dissectors $@ $(filter %.c,$^)

source += $(output)/$(pwd)/wireshark/epan/dissectors.c


$(output)/$(pwd)/wireshark/epan/dissectors/packet-ncp2222.c: $(pwd)/wireshark/tools/ncp2222.py
	@mkdir -p $(dir $@)
	python $< -o $@

source += $(output)/$(pwd)/wireshark/epan/dissectors/packet-ncp2222.c


$(output)/$(pwd)/%.c $(output)/$(pwd)/%_lex.h: pwd := $(pwd)
$(output)/$(pwd)/%.c $(output)/$(pwd)/%_lex.h: $(pwd)/%.l
	@mkdir -p $(dir $(output)/$(pwd)/$*)
	flex -t --header-file=$(output)/$(pwd)/$*_lex.h $< >$(output)/$(pwd)/$*.c

$(output)/$(pwd)/%.c $(output)/$(pwd)/%.h: pwd := $(pwd)
$(output)/$(pwd)/%.c $(output)/$(pwd)/%.h: $(pwd)/%.y
	@mkdir -p $(dir $(output)/$(pwd)/$*)
	bison --name-prefix=ascend --output=$(output)/$(pwd)/$*.c --defines=$(output)/$(pwd)/$*.h $<

$(output)/$(pwd)/wireshark/tools/lemon/lemon: $(pwd)/wireshark/tools/lemon/lemon.c
	@mkdir -p $(dir $@)
	gcc -o $@ $<

$(output)/$(pwd)/%.c $(output)/$(pwd)/%.h: pwd := $(pwd)
$(output)/$(pwd)/%.c $(output)/$(pwd)/%.h: $(pwd)/%.lemon $(output)/$(pwd)/wireshark/tools/lemon/lemon
	@mkdir -p $(dir $(output)/$(pwd)/$*)
	$(output)/$(pwd)/wireshark/tools/lemon/lemon -T$(pwd)/wireshark/tools/lemon/lempar.c -d$(dir $(output)/$(pwd)/$*) $(pwd)/$*.lemon

source += $(output)/$(pwd)/wireshark/epan/dtd_preparse.c
source += $(output)/$(pwd)/wireshark/epan/diam_dict.c
source += $(output)/$(pwd)/wireshark/epan/radius_dict.c
source += $(output)/$(pwd)/wireshark/epan/uat_load.c
source += $(output)/$(pwd)/wireshark/wiretap/k12text.c

source += $(output)/$(pwd)/wireshark/epan/dtd_parse.c
$(output)/$(output)/$(pwd)/wireshark/epan/dtd_parse.o: $(output)/$(pwd)/wireshark/epan/dtd_grammar.h
source += $(output)/$(pwd)/wireshark/epan/dtd_grammar.c

$(output)/$(pwd)/wireshark/epan/dfilter/dfilter.o: $(output)/$(pwd)/wireshark/epan/dfilter/scanner_lex.h
cflags_dfilter := -I$(output)/$(pwd)/wireshark/epan/dfilter
source += $(output)/$(pwd)/wireshark/epan/dfilter/scanner.c
$(output)/$(output)/$(pwd)/wireshark/epan/dfilter/scanner.o: $(output)/$(pwd)/wireshark/epan/dfilter/grammar.h
source += $(output)/$(pwd)/wireshark/epan/dfilter/grammar.c

source += $(output)/$(pwd)/wireshark/wiretap/ascend_scanner.c
$(output)/$(output)/$(pwd)/wireshark/wiretap/ascend_scanner.o: $(output)/$(pwd)/wireshark/wiretap/ascend.h
source += $(output)/$(pwd)/wireshark/wiretap/ascend.c

source += $(output)/$(pwd)/wireshark/wiretap/candump_scanner.c
$(output)/$(output)/$(pwd)/wireshark/wiretap/candump_scanner.o: $(output)/$(pwd)/wireshark/wiretap/candump_parser.h
source += $(output)/$(pwd)/wireshark/wiretap/candump_parser.c


# XXX: this is currently shared by libiconv and libgpg-error; it might be sharable by more stuff
$(output)/usr/include/%.h $(output)/usr/lib/lib%.a: $(output)/$(pwd)/lib%/Makefile $(sysroot)
	$(environ) $(MAKE) -C $(dir $<) install

# libgcrypt {{{
w_libgcrypt := 
w_libgcrypt += --disable-doc

ifeq ($(target),ios)
# XXX: cipher-gcm-armv8-aarch64-ce.S
# ADR/ADRP relocations must be GOT relative; unknown AArch64 fixup kind!
# adrp x5, :got:.Lrconst ; ldr x5, [x5, #:got_lo12:.Lrconst] ;
w_libgcrypt += gcry_cv_gcc_aarch64_platform_as_ok=no
w_libgcrypt += --disable-asm

# XXX: rndlinux.c  ret = getentropy (buffer, nbytes);  (syscall() backup)
# error: implicit declaration of function 'getentropy' is invalid in C99
w_libgcrypt += ac_cv_func_getentropy=no
endif

w_libgcrypt += --with-libgpg-error-prefix=$(CURDIR)/$(output)/usr
$(output)/$(pwd)/libgcrypt/Makefile: $(output)/usr/include/gpg-error.h
$(output)/$(pwd)/libgcrypt/Makefile: $(output)/usr/lib/libgpg-error.a

# XXX: one of the test cases uses system() (not allowed on iOS) and there is no --disable-tests
$(output)/$(pwd)/%/src/gcrypt.h $(output)/$(pwd)/%/src/.libs/libgcrypt.a: $(output)/$(pwd)/%/Makefile
	for sub in compat mpi cipher random src; do $(environ) $(MAKE) -C $(dir $<)/$${sub}; done

cflags += -I$(output)/$(pwd)/libgcrypt/src
linked += $(output)/$(pwd)/libgcrypt/src/.libs/libgcrypt.a
header += $(output)/$(pwd)/libgcrypt/src/gcrypt.h
# }}}
# libgpg-error {{{
w_libgpg_error := 
w_libgpg_error += --disable-doc
w_libgpg_error += --disable-languages
w_libgpg_error += --disable-nls
w_libgpg_error += --disable-tests

ifeq ($(target),and)
# XXX: host_triplet armv7a-unknown-linux-androideabi contains unexpected "v7a" suffix
# error including `syscfg/lock-obj-pub.linux-androideabi.h': No such file or directory
m_libgpg_error := sed -i -e 's/\(host_triplet = arm\)[a-z0-9]*-/\1-/' src/Makefile
endif

linked += $(output)/usr/lib/libgpg-error.a
header += $(output)/usr/include/gpg-error.h
# }}}
# glib {{{
w_glib := 
w_glib += -Dlibmount=false
w_glib += -Diconv=gnu

m_glib := sed -i -e 's@^\(build all:.*\) tests/child-test@\1@; s@^\(build all:.*\) tests/gio-test@\1@;' build.ninja

deps := 
deps += glib/gmodule/libgmodule-2.0.a
deps += glib/glib/libglib-2.0.a
deps += glib/subprojects/proxy-libintl/libintl.a
deps := $(patsubst %,$(output)/$(pwd)/%,$(deps))

$(output)/$(pwd)/glib/build.ninja: $(output)/usr/include/iconv.h $(output)/usr/lib/libiconv.a

$(patsubst %.a,%$(percent)a,$(deps)): $(output)/$(pwd)/glib/build%ninja
	cd $(dir $<) && ninja

linked += $(deps)

header += $(output)/$(pwd)/glib/build.ninja
cflags += -I$(output)/$(pwd)/glib/glib

cflags += -I$(pwd)/glib
cflags += -I$(pwd)/glib/glib
cflags += -I$(pwd)/glib/gmodule

#cflags += $(shell pkg-config --cflags glib-2.0)
#lflags += $(shell pkg-config --libs glib-2.0)
# }}}
# libiconv {{{
w_libiconv := LDFLAGS="$(wflags)"

export GNULIB_SRCDIR := $(CURDIR)/$(pwd)/gnulib
export GNULIB_TOOL := $(GNULIB_SRCDIR)/gnulib-tool

# XXX: autogen.sh fails (without failing) before this step
a_libiconv := cd preload && make -f Makefile.devel all

linked += $(output)/usr/lib/libiconv.a
header += $(output)/usr/include/iconv.h
# }}}

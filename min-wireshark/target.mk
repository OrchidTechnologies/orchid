# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pwd/wireshark := $(pwd)/wireshark

archive += $(pwd/wireshark)/epan
linked += $(pwd/wireshark)/epan.a

wireshark := 
cflags/$(pwd/wireshark)/ := 

wireshark += $(wildcard $(pwd/wireshark)/epan/*.c)
wireshark += $(wildcard $(pwd/wireshark)/epan/crypt/*.c)
wireshark += $(wildcard $(pwd/wireshark)/epan/dfilter/*.c)
wireshark += $(wildcard $(pwd/wireshark)/epan/dissectors/*.c)
wireshark += $(wildcard $(pwd/wireshark)/epan/ftypes/*.c)
wireshark += $(wildcard $(pwd/wireshark)/epan/wmem/*.c)

wireshark += $(wildcard $(pwd/wireshark)/wiretap/*.c)
wireshark += $(wildcard $(pwd/wireshark)/wsutil/*.c)

wireshark += $(pwd/wireshark)/cfile.c
wireshark += $(pwd/wireshark)/frame_tvbuff.c
wireshark += $(pwd/wireshark)/version_info.c

ifeq ($(target),and)
# XXX: end??ent was added with SDK level 26
# we should attempt to call it, if possible
cflags/$(pwd/wireshark)/wsutil/privileges.c += -D'endpwent()='
cflags/$(pwd/wireshark)/wsutil/privileges.c += -D'endgrent()='

# XXX: ws_pipe uses getdtablesize(), which
# is a broken API not supported on Android
wireshark := $(filter-out \
    %/ws_pipe.c \
,$(wireshark))
endif

ifeq ($(target),win)
cflags/$(pwd/wireshark)/ += -D_UNICODE
cflags/$(pwd/wireshark)/ += -DUNICODE

cflags/$(pwd/wireshark)/ += -DSTRSAFE_NO_DEPRECATE
cflags/$(pwd/wireshark)/ += -include malloc.h
cflags/$(pwd/wireshark)/ += -Wno-format
cflags/$(pwd/wireshark)/ += -Wno-missing-braces

cflags/$(pwd/wireshark)/epan/dissectors/packet-epl-profile-parser.c += -include stdlib.h
cflags/$(pwd/wireshark)/epan/dissectors/packet-smb2.c += -D_MSC_VER
cflags/$(pwd/wireshark)/wsutil/getopt_long.c += -DNO_OLDNAMES
cflags/$(pwd/wireshark)/wsutil/filesystem.c += -Wno-unused-function
else
wireshark := $(filter-out \
    %/file_util.c \
    %/win32-utils.c \
,$(wireshark))

cflags/$(pwd/wireshark)/ += -DHAVE_ALLOCA_H
cflags/$(pwd/wireshark)/ += -DHAVE_ARPA_INET_H
cflags/$(pwd/wireshark)/ += -DHAVE_GRP_H
cflags/$(pwd/wireshark)/ += -DHAVE_PWD_H

cflags/$(pwd/wireshark)/ += -DHAVE_MKSTEMPS
cflags/$(pwd/wireshark)/ += -DHAVE_STRPTIME

wireshark := $(filter-out \
    %/strptime.c \
,$(wireshark))

cflags/$(pwd/wireshark)/epan/addr_resolv.c += -include netdb.h
endif

cflags/$(pwd/wireshark)/ += -DHAVE_FCNTL_H
cflags/$(pwd/wireshark)/ += -DHAVE_UNISTD_H

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
cflags += -I$(pwd)/extra
cflags += -iquote$(pwd)/extra
cflags += -I$(pwd/wireshark)

cflags/$(pwd/wireshark)/ += -D'DATA_DIR=""'
cflags/$(pwd/wireshark)/ += -D'EXTCAP_DIR=""'
cflags/$(pwd/wireshark)/ += -D'PLUGIN_PATH_ID=""'

cflags/$(pwd/wireshark)/ += -D'PACKAGE="wireshark"'
cflags/$(pwd/wireshark)/ += -D'VERSION="0.0.0"'
cflags/$(pwd/wireshark)/ += -D'VERSION_MAJOR=0'
cflags/$(pwd/wireshark)/ += -D'VERSION_MINOR=0'
cflags/$(pwd/wireshark)/ += -D'VERSION_MICRO=0'

cflags/$(pwd/wireshark)/ += -Wno-pointer-sign

# XXX: fwrite used without check; submit patch
cflags/$(pwd/wireshark)/ += -Wno-unused-result

cflags/$(pwd/wireshark)/ += -I$(pwd/wireshark)/epan
cflags/$(pwd/wireshark)/ += -I$(pwd/wireshark)/epan/dfilter
cflags/$(pwd/wireshark)/ += -I$(pwd/wireshark)/epan/dissectors
cflags/$(pwd/wireshark)/ += -I$(pwd/wireshark)/epan/ftypes
cflags/$(pwd/wireshark)/ += -I$(pwd/wireshark)/tools/lemon
cflags/$(pwd/wireshark)/ += -I$(pwd/wireshark)/wiretap


$(output)/$(pwd/wireshark)/epan/ps.c: $(pwd/wireshark)/tools/rdps.py $(pwd/wireshark)/epan/print.ps
	@mkdir -p $(dir $@)
	$^ $@

source += $(output)/$(pwd/wireshark)/epan/ps.c


ifeq ($(meson),darwin)
source += $(pwd/wireshark)/../wireshark.c
else
$(output)/$(pwd/wireshark)/epan/dissectors.c: $(pwd/wireshark)/tools/make-regs.py $(filter $(pwd/wireshark)/epan/dissectors/%.c,$(wireshark))
	@mkdir -p $(dir $@)
	@echo [EX] $(target) $<
	@python3 $< dissectors $@ $(filter %.c,$^)

source += $(output)/$(pwd/wireshark)/epan/dissectors.c
endif


$(output)/$(pwd/wireshark)/epan/dissectors/packet-ncp2222.c: $(pwd/wireshark)/tools/ncp2222.py
	@mkdir -p $(dir $@)
	python $< -o $@

source += $(output)/$(pwd/wireshark)/epan/dissectors/packet-ncp2222.c


$(output)/$(pwd)/%.c $(output)/$(pwd)/%_lex.h: pwd := $(pwd)
$(output)/$(pwd)/%.c $(output)/$(pwd)/%_lex.h: $(pwd)/%.l
	@mkdir -p $(dir $(output)/$(pwd)/$*)
	flex -t --header-file=$(output)/$(pwd)/$*_lex.h $< >$(output)/$(pwd)/$*.c

$(output)/$(pwd)/%.c $(output)/$(pwd)/%.h: pwd := $(pwd)
$(output)/$(pwd)/%.c $(output)/$(pwd)/%.h: $(pwd)/%.y
	@mkdir -p $(dir $(output)/$(pwd)/$*)
	bison --name-prefix=$(notdir $*) --output=$(output)/$(pwd)/$*.c --defines=$(output)/$(pwd)/$*.h $<

$(output)/$(pwd/wireshark)/tools/lemon/lemon: $(pwd/wireshark)/tools/lemon/lemon.c
	@mkdir -p $(dir $@)
	gcc -o $@ $<

$(output)/$(pwd)/%.c $(output)/$(pwd)/%.h: $(pwd)/%.lemon $(output)/$(pwd/wireshark)/tools/lemon/lemon
	@mkdir -p $(dir $@)
	@echo [LM] $(target) $<
	@$(word 2,$^) -T$(pwd/wireshark)/tools/lemon/lempar.c -d$(dir $@) $(word 1,$^)
	@touch $(basename $@).h

source += $(output)/$(pwd/wireshark)/epan/dtd_preparse.c
source += $(output)/$(pwd/wireshark)/epan/diam_dict.c
source += $(output)/$(pwd/wireshark)/epan/radius_dict.c
source += $(output)/$(pwd/wireshark)/epan/uat_load.c
source += $(output)/$(pwd/wireshark)/wiretap/k12text.c

cflags/$(pwd/wireshark)/epan/dfilter/dfilter.c += -I$(output)/$(pwd/wireshark)/epan/dfilter

define parser
source += $(output)/$(pwd/wireshark)/$(1)$(2).c
$(call depend,$(output)/$(pwd/wireshark)/$(1)$(2).c.o,$(output)/$(pwd/wireshark)/$(1)$(3).h)
source += $(output)/$(pwd/wireshark)/$(1)$(3).c
$(call depend,$(output)/$(pwd/wireshark)/$(1)$(3).c.o,$(output)/$(pwd/wireshark)/$(1)$(2)_lex.h)
endef

$(eval $(call parser,epan/dfilter/,scanner,grammar))
$(eval $(call parser,epan/dtd_,parse,grammar))
$(eval $(call parser,epan/protobuf_lang,_scanner,))
$(eval $(call parser,wiretap/ascend,_scanner,))
$(eval $(call parser,wiretap/busmaster_,scanner,parser))
$(eval $(call parser,wiretap/candump_,scanner,parser))


# libgcrypt {{{
w_libgcrypt := 
w_libgcrypt += --disable-doc

ifeq ($(target),ios)
# XXX: cipher-gcm-armv8-aarch64-ce.S
# ADR/ADRP relocations must be GOT relative; unknown AArch64 fixup kind!
# adrp x5, :got:.Lrconst ; ldr x5, [x5, #:got_lo12:.Lrconst] ;
w_libgcrypt += gcry_cv_gcc_aarch64_platform_as_ok=no
w_libgcrypt += --disable-asm
endif

ifneq ($(filter ios mac,$(target)),)
# XXX: rndlinux.c  ret = getentropy (buffer, nbytes);  (syscall() backup)
# error: implicit declaration of function 'getentropy' is invalid in C99
w_libgcrypt += ac_cv_func_getentropy=no
endif

w_libgcrypt += --with-libgpg-error-prefix=@/usr
$(call depend,$(pwd)/libgcrypt/Makefile,@/usr/include/gpg-error.h)
$(call depend,$(pwd)/libgcrypt/Makefile,@/usr/lib/libgpg-error.a)

.PRECIOUS: $(output)/%/$(pwd)/libgcrypt/src/gcrypt.h
# XXX: one of the test cases uses system() (not allowed on iOS) and there is no --disable-tests
$(output)/%/$(pwd)/libgcrypt/src/gcrypt.h $(output)/%/$(pwd)/libgcrypt/src/.libs/libgcrypt.a: $(output)/%/$(pwd)/libgcrypt/Makefile
	for sub in compat mpi cipher random src; do $(MAKE) -C $(dir $<)/$${sub} CC_FOR_BUILD=clang; done

cflags += -I@/$(pwd)/libgcrypt/src
linked += $(pwd)/libgcrypt/src/.libs/libgcrypt.a
header += @/$(pwd)/libgcrypt/src/gcrypt.h
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
# XXX: libgpg-error doesn't come with an aarch64 android lock-obj-pub implementation
# I have independently confirmed the correct implementation is a 40 byte object of 0s
m_libgpg_error := sed -i -e 's/^\(host_triplet = arm\)[a-z0-9]*-/\1-/; s/^\(host_triplet =\) aarch64-.*/\1 x86_64-unknown-linux-gnu/' src/Makefile
endif

linked += usr/lib/libgpg-error.a
header += @/usr/include/gpg-error.h

define _
$(output)/$(1)/usr/include/%.h $(output)/$(1)/usr/lib/lib%.a: $(output)/$(1)/$(pwd)/lib%/Makefile $(sysroot)
	$$(MAKE) -C $$(dir $$<) install CC_FOR_BUILD=clang
endef
$(each)
# }}}

$(call include,glib/target.mk)

# c-ares {{{
$(output)/%/$(pwd)/c-ares/include/ares_build.h: $(output)/%/$(pwd)/c-ares/Makefile
	touch $@
	$(MAKE) -C $(dir $@)
$(output)/%/$(pwd)/c-ares/src/lib/.libs/libcares.a: $(output)/%/$(pwd)/c-ares/include/ares_build.h
	$(MAKE) -C $(patsubst %/include/ares_build.h,%,$<)/src

cflags/$(pwd/wireshark)/ += -I@/$(pwd)/c-ares/include
header += @/$(pwd)/c-ares/include/ares_build.h
linked += $(pwd)/c-ares/src/lib/.libs/libcares.a
cflags/$(pwd/wireshark)/ += -I$(pwd)/c-ares/include
cflags += -DCARES_STATICLIB
# }}}

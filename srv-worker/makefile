# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# GNU Affero General Public License, Version 3 {{{ */
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# }}}


args := 

distro := ubuntu jammy 11
include env/target.mk

binary := $(output)/$(machine)/worker$(exe)

.PHONY: all
all: $(binary)

.PHONY: debug
debug: $(binary)
	lldb-14 -o 'b malloc_error_break' -o 'run $(args)' $<

.PHONY: test
test: $(binary)
	strace -ff $< 2>&1 | grep -Ev '(] |^)(<|(qmap|mprotect|munmap)\()'

source += $(wildcard $(pwd)/source/*.cpp)
source += $(pwd)/libc.cpp

cflags += -I$(pwd)/source

lflags += -nodefaultlibs
lflags += -static-pie
lflags += -lm
lflags := $(filter-out -pthread,$(lflags))
qflags += -femulated-tls
cflags += -fno-plt
lflags += -fno-plt

lflags += -lstdc++
lflags += -lgcc
lflags += -lgcc_eh


# linked += {{{
ifeq ($(machine),x86_64)
linked += libc/cacheinfo.o
linked += libc/dl-cet.o
linked += libc/varshift.o

linked += libc/float1282mpn.o
linked += libc/mpn2float128.o
linked += libc/strtof128.o
linked += libc/strtof128_l.o
linked += libc/strtof128_nan.o

linked += libc/memchr-avx2.o
linked += libc/memchr-avx2-rtm.o
linked += libc/memchr-evex.o
linked += libc/memchr-evex-rtm.o
linked += libc/memchr-sse2.o
linked += libc/memcmp-avx2-movbe.o
linked += libc/memcmp-avx2-movbe-rtm.o
linked += libc/memcmp-evex-movbe.o
linked += libc/memcmp-sse2.o
linked += libc/memcmp-sse4.o
linked += libc/memcmp-ssse3.o
linked += libc/memcpy-ssse3.o
linked += libc/memcpy-ssse3-back.o
linked += libc/memcpy_chk-nonshared.o
linked += libc/memmove-avx-unaligned-erms.o
linked += libc/memmove-avx-unaligned-erms-rtm.o
linked += libc/memmove-avx512-no-vzeroupper.o
linked += libc/memmove-avx512-unaligned-erms.o
linked += libc/memmove-evex-unaligned-erms.o
linked += libc/memmove-sse2-unaligned-erms.o
linked += libc/memmove-ssse3.o
linked += libc/memmove-ssse3-back.o
linked += libc/memmove_chk-nonshared.o
linked += libc/memset-avx2-unaligned-erms.o
linked += libc/memset-avx2-unaligned-erms-rtm.o
linked += libc/memset-avx512-no-vzeroupper.o
linked += libc/memset-avx512-unaligned-erms.o
linked += libc/memset-evex-unaligned-erms.o
linked += libc/memset-sse2-unaligned-erms.o
linked += libc/rawmemchr-avx2.o
linked += libc/rawmemchr-avx2-rtm.o
linked += libc/rawmemchr-evex.o
linked += libc/rawmemchr-evex-rtm.o
linked += libc/rawmemchr-sse2.o
linked += libc/stpcpy-avx2.o
linked += libc/stpcpy-avx2-rtm.o
linked += libc/stpcpy-evex.o
linked += libc/stpcpy-sse2.o
linked += libc/stpcpy-sse2-unaligned.o
linked += libc/stpcpy-ssse3.o
linked += libc/strcasecmp_l-avx.o
linked += libc/strcasecmp_l-nonascii.o
linked += libc/strcasecmp_l-sse2.o
linked += libc/strcasecmp_l-sse4_2.o
linked += libc/strcasecmp_l-ssse3.o
linked += libc/strcat-avx2.o
linked += libc/strcat-avx2-rtm.o
linked += libc/strcat-evex.o
linked += libc/strcat-sse2.o
linked += libc/strcat-sse2-unaligned.o
linked += libc/strcat-ssse3.o
linked += libc/strchr-avx2.o
linked += libc/strchr-avx2-rtm.o
linked += libc/strchr-evex.o
linked += libc/strchr-sse2-no-bsf.o
linked += libc/strchr-sse2.o
linked += libc/strchrnul-avx2.o
linked += libc/strchrnul-avx2-rtm.o
linked += libc/strchrnul-evex.o
linked += libc/strchrnul-sse2.o
linked += libc/strcmp-avx2.o
linked += libc/strcmp-avx2-rtm.o
linked += libc/strcmp-evex.o
linked += libc/strcmp-sse2.o
linked += libc/strcmp-sse2-unaligned.o
linked += libc/strcmp-sse4_2.o
linked += libc/strcmp-ssse3.o
linked += libc/strcpy-avx2.o
linked += libc/strcpy-avx2-rtm.o
linked += libc/strcpy-evex.o
linked += libc/strcpy-sse2.o
linked += libc/strcpy-sse2-unaligned.o
linked += libc/strcpy-ssse3.o
linked += libc/strcspn-c.o
linked += libc/strcspn-sse2.o
linked += libc/strlen-avx2.o
linked += libc/strlen-avx2-rtm.o
linked += libc/strlen-evex.o
linked += libc/strlen-sse2.o
linked += libc/strncase_l-avx.o
linked += libc/strncase_l-nonascii.o
linked += libc/strncase_l-sse2.o
linked += libc/strncase_l-sse4_2.o
linked += libc/strncase_l-ssse3.o
linked += libc/strncat-avx2.o
linked += libc/strncat-avx2-rtm.o
linked += libc/strncat-c.o
linked += libc/strncat-evex.o
linked += libc/strncat-sse2-unaligned.o
linked += libc/strncat-ssse3.o
linked += libc/strncmp-avx2.o
linked += libc/strncmp-avx2-rtm.o
linked += libc/strncmp-evex.o
linked += libc/strncmp-sse2.o
linked += libc/strncmp-sse4_2.o
linked += libc/strncmp-ssse3.o
linked += libc/strncpy-avx2.o
linked += libc/strncpy-avx2-rtm.o
linked += libc/strncpy-c.o
linked += libc/strncpy-evex.o
linked += libc/strncpy-sse2-unaligned.o
linked += libc/strncpy-ssse3.o
linked += libc/strnlen-avx2.o
linked += libc/strnlen-avx2-rtm.o
linked += libc/strnlen-evex.o
linked += libc/strnlen-sse2.o
linked += libc/strrchr-avx2.o
linked += libc/strrchr-avx2-rtm.o
linked += libc/strrchr-evex.o
linked += libc/strrchr-sse2.o
linked += libc/strspn-c.o
linked += libc/strspn-sse2.o
linked += libc/strstr-sse2-unaligned.o
linked += libc/wcschr-avx2.o
linked += libc/wcschr-avx2-rtm.o
linked += libc/wcschr-evex.o
linked += libc/wcschr-sse2.o
linked += libc/wcslen-avx2.o
linked += libc/wcslen-avx2-rtm.o
linked += libc/wcslen-evex.o
linked += libc/wcslen-sse2.o
linked += libc/wcslen-sse4_1.o
linked += libc/wcsnlen-avx2.o
linked += libc/wcsnlen-avx2-rtm.o
linked += libc/wcsnlen-c.o
linked += libc/wcsnlen-evex.o
linked += libc/wcsnlen-sse4_1.o
linked += libc/wmemchr-avx2.o
linked += libc/wmemchr-avx2-rtm.o
linked += libc/wmemchr-evex.o
linked += libc/wmemchr-evex-rtm.o
linked += libc/wmemchr-sse2.o
linked += libc/wmemcmp-avx2-movbe.o
linked += libc/wmemcmp-avx2-movbe-rtm.o
linked += libc/wmemcmp-evex-movbe.o
linked += libc/wmemcmp-c.o
linked += libc/wmemcmp-sse4.o
linked += libc/wmemcmp-ssse3.o
endif

ifeq ($(machine),arm64)
linked += libc/dl-bti.o
linked += libc/getauxval.o
linked += libc/strchrnul.o
linked += libc/sysdep.o

linked += libc/memchr_generic.o
linked += libc/memchr_nosimd.o
linked += libc/memcpy_a64fx.o
linked += libc/memcpy_advsimd.o
linked += libc/memcpy_falkor.o
linked += libc/memcpy_generic.o
linked += libc/memcpy_thunderx.o
linked += libc/memcpy_thunderx2.o
linked += libc/memcpy_chk.o
linked += libc/memset_a64fx.o
linked += libc/memset_emag.o
linked += libc/memset_falkor.o
linked += libc/memset_generic.o
linked += libc/memset_kunpeng.o
linked += libc/strlen_asimd.o
linked += libc/strlen_mte.o
endif

ifeq ($(machine),armhf)
linked += libc/getauxval.o
linked += libc/libc-do-syscall.o
linked += libc/sysdep.o

linked += libc/memchr_neon.o
linked += libc/memchr_noneon.o
linked += libc/memcpy_neon.o
linked += libc/memcpy_vfp.o
endif

linked += libc/dl-reloc-static-pie.o
linked += libc/libc-start.o

linked += libc/abort.o
linked += libc/assert.o
linked += libc/atexit.o
linked += libc/backtrace.o
linked += libc/backtracesyms.o
linked += libc/cancellation.o
linked += libc/chk_fail.o
linked += libc/cxa_atexit.o
linked += libc/errno.o
linked += libc/errno-loc.o
linked += libc/exit.o
linked += libc/_exit.o
linked += libc/fortify_fail.o
linked += libc/libc_fatal.o
linked += libc/msort.o
linked += libc/qsort.o
linked += libc/stack_chk_fail.o

linked += libc/SYS_libc.o
linked += libc/argz-addsep.o
linked += libc/argz-create.o
linked += libc/argz-ctsep.o
linked += libc/brk.o
linked += libc/check_fds.o
linked += libc/ctype.o
linked += libc/ctype-info.o
linked += libc/dcgettext.o
linked += libc/dcigettext.o
linked += libc/elision-conf.o
linked += libc/enbl-secure.o
linked += libc/errlist.o
linked += libc/explodename.o
linked += libc/filedoalloc.o
linked += libc/fileops.o
linked += libc/finddomain.o
linked += libc/genops.o
linked += libc/getdents64.o
linked += libc/getpagesize.o
linked += libc/getrlimit64.o
linked += libc/global-locale.o
linked += libc/hash-string.o
linked += libc/init-first.o
linked += libc/init-misc.o
linked += libc/iofclose.o
linked += libc/iofgets_u.o
linked += libc/iofopen.o
linked += libc/iofwide.o
linked += libc/iogetdelim.o
linked += libc/iogetline.o
linked += libc/isatty.o
linked += libc/l10nflist.o
linked += libc/lc-ctype.o
linked += libc/libc-cleanup.o
linked += libc/libc-tls.o
linked += libc/libc_dlerror_result.o
linked += libc/libc_early_init.o
linked += libc/loadarchive.o
linked += libc/loadmsgcat.o
linked += libc/localealias.o
linked += libc/localename.o
linked += libc/lowlevellock.o
linked += libc/nptl-stack.o
linked += libc/nptl_deallocate_tsd.o
linked += libc/nptl_nthreads.o
linked += libc/plural-exp.o
linked += libc/plural.o
linked += libc/prof-freq.o
linked += libc/profil.o
linked += libc/pthread_keys.o
linked += libc/pthread_mutex_conf.o
linked += libc/pthread_setcancelstate.o
linked += libc/pthread_sigmask.o
linked += libc/rtld_static_init.o
linked += libc/sbrk.o
linked += libc/sched_getp.o
linked += libc/sched_gets.o
linked += libc/sched_primax.o
linked += libc/sched_primin.o
linked += libc/sched_sets.o
linked += libc/scratch_buffer_set_array_size.o
linked += libc/setitimer.o
linked += libc/sigjmp.o
linked += libc/sigprocmask.o
linked += libc/single_threaded.o
linked += libc/stdfiles.o
linked += libc/_strerror.o
linked += libc/strops.o
linked += libc/tcgetattr.o
linked += libc/tlsdesc.o
linked += libc/tpp.o
linked += libc/tsearch.o
linked += libc/vars.o
linked += libc/vtables.o
linked += libc/wfiledoalloc.o
linked += libc/wfileops.o
linked += libc/wgenops.o

linked += libc/alloc_buffer_alloc_array.o
linked += libc/alloc_buffer_create_failure.o
linked += libc/alt_digit.o
linked += libc/era.o
linked += libc/gmtime.o
linked += libc/lc-time-cleanup.o
linked += libc/localtime.o
linked += libc/mktime.o
linked += libc/offtime.o
linked += libc/strftime.o
linked += libc/strftime_l.o
linked += libc/tzfile.o
linked += libc/tzset.o

linked += libc/div.o
linked += libc/s_ldexp.o
linked += libc/s_scalbn.o

linked += libc/memchr.o
linked += libc/memcmp.o
linked += libc/memcpy.o
linked += libc/memmem.o
linked += libc/memmove.o
linked += libc/memmove_chk.o
linked += libc/mempcpy.o
linked += libc/memset.o
linked += libc/rawmemchr.o
linked += libc/stpcpy.o
linked += libc/strcasecmp.o
linked += libc/strcasecmp_l.o
linked += libc/strcat.o
linked += libc/strchr.o
linked += libc/strchrnul.o
linked += libc/strcmp.o
linked += libc/strcpy.o
linked += libc/strcspn.o
linked += libc/strdup.o
linked += libc/strlen.o
linked += libc/strncase_l.o
linked += libc/strncat.o
linked += libc/strncmp.o
linked += libc/strncpy.o
linked += libc/strndup.o
linked += libc/strnlen.o
linked += libc/strrchr.o
linked += libc/strsep.o
linked += libc/strspn.o
linked += libc/strstr.o
linked += libc/strtok_r.o
linked += libc/wcrtomb.o
linked += libc/wcschr.o
linked += libc/wcschrnul.o
linked += libc/wcslen.o
linked += libc/wcsmbsload.o
linked += libc/wcsnlen.o
linked += libc/wcsnrtombs.o
linked += libc/wmemchr.o
linked += libc/wmemcpy.o
linked += libc/wmemcpy_chk.o
linked += libc/wmemmove.o
linked += libc/wmemmove_chk.o
linked += libc/wmempcpy.o
linked += libc/wmemset.o

linked += libc/mbrlen.o
linked += libc/mbrtowc.o
linked += libc/mbsnrtowcs.o
linked += libc/mbsrtowcs.o
linked += libc/mbsrtowcs_l.o
linked += libc/mbtowc.o

linked += libc/add_n.o
linked += libc/addmul_1.o
linked += libc/atoi.o
linked += libc/cmp.o
linked += libc/fpioconst.o
linked += libc/grouping.o
linked += libc/_itoa.o
linked += libc/itoa-digits.o
linked += libc/itoa-udigits.o
linked += libc/lshift.o
linked += libc/mb_cur_max.o
linked += libc/mpn2dbl.o
linked += libc/mpn2flt.o
linked += libc/mpn2ldbl.o
linked += libc/mul.o
linked += libc/mul_1.o
linked += libc/mul_n.o
linked += libc/rshift.o
linked += libc/strtod.o
linked += libc/strtod_l.o
linked += libc/strtod_nan.o
linked += libc/strtof.o
linked += libc/strtof_l.o
linked += libc/strtof_nan.o
linked += libc/strtol.o
linked += libc/strtol_l.o
linked += libc/strtold.o
linked += libc/strtold_l.o
linked += libc/strtold_nan.o
linked += libc/strtoul.o
linked += libc/strtoul_l.o
linked += libc/sub_n.o
linked += libc/submul_1.o
linked += libc/tens_in_limb.o

linked += libc/madvise.o
linked += libc/mmap.o
linked += libc/mmap64.o
linked += libc/mprotect.o
linked += libc/mremap.o
linked += libc/munmap.o

ifeq (,)
linked += libc/libc_multiple_threads.o
linked += libc/write.o
endif

linked += libc/C-address.o
linked += libc/C-collate.o
linked += libc/C-ctype.o
linked += libc/C-identification.o
linked += libc/C-measurement.o
linked += libc/C-messages.o
linked += libc/C-monetary.o
linked += libc/C-name.o
linked += libc/C-numeric.o
linked += libc/C-paper.o
linked += libc/C-telephone.o
linked += libc/C-time.o
linked += libc/C_name.o

linked += libc/catgets.o
linked += libc/findlocale.o
linked += libc/freelocale.o
linked += libc/loadlocale.o
linked += libc/newlocale.o
linked += libc/open_catalog.o
linked += libc/setlocale.o
linked += libc/uselocale.o
linked += libc/xlocale.o

linked += libc/dl-addr.o
linked += libc/dl-addr-obj.o
linked += libc/dl-cache.o
linked += libc/dl-call-libc-early-init.o
linked += libc/dl-close.o
linked += libc/dl-debug.o
linked += libc/dl-debug-symbols.o
linked += libc/dl-deps.o
linked += libc/dl-error.o
linked += libc/dl-exception.o
linked += libc/dl-execstack.o
linked += libc/dl-find_object.o
linked += libc/dl-init.o
linked += libc/dl-iteratephdr.o
linked += libc/dl-libc.o
linked += libc/dl-load.o
linked += libc/dl-lookup.o
linked += libc/dl-lookup-direct.o
linked += libc/dl-minimal-malloc.o
linked += libc/dl-misc.o
linked += libc/dl-object.o
linked += libc/dl-open.o
linked += libc/dl-printf.o
linked += libc/dl-profile.o
linked += libc/dl-profstub.o
linked += libc/dl-reloc.o
linked += libc/dl-runtime.o
linked += libc/dl-scope.o
linked += libc/dl-setup_hash.o
linked += libc/dl-sort-maps.o
linked += libc/dl-support.o
linked += libc/dl-sym.o
linked += libc/dl-sysdep.o
linked += libc/dl-thread_gscope_wait.o
linked += libc/dl-tls.o
linked += libc/dl-tlsdesc.o
linked += libc/dl-trampoline.o
linked += libc/dl-tunables.o
linked += libc/dl-version.o

linked += libc/dladdr.o
linked += libc/dladdr1.o
linked += libc/dlclose.o
linked += libc/dlerror.o
linked += libc/dlinfo.o
linked += libc/dlmopen.o
linked += libc/dlopen.o
linked += libc/dlsym.o
linked += libc/dlvsym.o

linked += libc/bsd-_setjmp.o
linked += libc/__longjmp.o
linked += libc/longjmp.o
linked += libc/setjmp.o

linked += libc/alloca_cutoff.o
linked += libc/environ.o
linked += libc/setenv.o

linked += libc/gconv.o
linked += libc/gconv_builtin.o
linked += libc/gconv_cache.o
linked += libc/gconv_charset.o
linked += libc/gconv_close.o
linked += libc/gconv_conf.o
linked += libc/gconv_db.o
linked += libc/gconv_dl.o
linked += libc/gconv_open.o
linked += libc/gconv_simple.o
linked += libc/gconv_trans.o

linked += libc/asprintf.o
linked += libc/btowc.o
linked += libc/dbl2mpn.o
linked += libc/divrem.o
linked += libc/fprintf.o
linked += libc/fxprintf.o
linked += libc/funlockfile.o
linked += libc/iofflush.o
linked += libc/iopadn.o
linked += libc/iovsprintf.o
linked += libc/iowpadn.o
linked += libc/isoc99_sscanf.o
linked += libc/isoc99_vsscanf.o
linked += libc/itowa-digits.o
linked += libc/lc-monetary.o
linked += libc/lc-numeric.o
linked += libc/ldbl2mpn.o
linked += libc/printf.o
linked += libc/printf-parsemb.o
linked += libc/printf-parsewc.o
linked += libc/printf_fp.o
linked += libc/printf_fphex.o
linked += libc/readonly-area.o
linked += libc/reg-modifier.o
linked += libc/reg-printf.o
linked += libc/reg-type.o
linked += libc/scratch_buffer_grow_preserve.o
linked += libc/snprintf.o
linked += libc/sprintf.o
linked += libc/towctrans.o
linked += libc/vasprintf.o
linked += libc/vasprintf_chk.o
linked += libc/vfprintf-internal.o
linked += libc/vfprintf_chk.o
linked += libc/vfscanf-internal.o
linked += libc/vfwprintf-internal.o
linked += libc/vprintf_chk.o
linked += libc/vsnprintf.o
linked += libc/vsnprintf_chk.o
linked += libc/wcsrtombs.o
linked += libc/wctrans.o

linked += libc/ctype_l.o
linked += libc/localeconv.o
linked += libc/wcfuncs_l.o
linked += libc/wctob.o
linked += libc/wmemcmp.o

ifeq (,)
linked += libc/close_nocancel.o
linked += libc/pread64_nocancel.o
linked += libc/open64_nocancel.o
linked += libc/fcntl_nocancel.o
linked += libc/write_nocancel.o
linked += libc/read_nocancel.o
endif
# }}}


cflags/$(pwd)/source/main.cpp += -Wno-deprecated-enum-enum-conversion

$(call include,cv8/target.mk)


cflags += -D_LIBCPP_HAS_NO_STDIN=

w_icu4c += ac_cv_var_timezone=no
w_icu4c += ac_cv_var___timezone=no
w_icu4c += ac_cv_var_tzname=no
w_icu4c += ac_cv_var__tzname=no
w_icu4c += ac_cv_func_tzset=no


w_jemalloc += --disable-cxx
w_jemalloc += --disable-libdl
w_jemalloc += --disable-stats
w_jemalloc += --disable-syscall
w_jemalloc += --enable-debug
w_jemalloc += --with-malloc-conf=tcache:false

w_jemalloc += ac_cv_func_sbrk=no
w_jemalloc += force_tls=0

jemalloc := lib/libjemalloc_pic.a
$(output)/%/$(pwd)/jemalloc/$(jemalloc): $(output)/%/$(pwd)/jemalloc/Makefile
	$(MAKE) -C $(dir $<) $(jemalloc)
linked += $(pwd)/jemalloc/$(jemalloc)


ifeq ($(machine),x86_64)
lib := $(output)/sysroot/usr/lib/$(host/$(machine))
else
lib := $(output)/sysroot/usr/$(host/$(machine))/lib
endif

$(output)/$(machine)/libc.: $(output)/sysroot
	@rm -rf $(basename $@)
	@mkdir -p $(basename $@)
	cd $(basename $@) && $(ar/$(machine)) -x $(CURDIR)/$(lib)/libc.a
	@touch $@

$(output)/$(machine)/libc/%.o: $(output)/$(machine)/libc.
	@


$(call include,ssl/target.mk)

cflags += -I$(pwd)/capnproto/c++/src
cflags += -I$(pwd)/workerd/src
#source += $(wildcard $(pwd)/workerd/src/workerd/api/crypto-impl-aes.c++)

include env/output.mk

$(output)/%/worker$(exe): $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cxx) $(more/$*) $(wflags) -o $@ $^ $(lflags) -Wl,--color-diagnostics=always -fcolor-diagnostics 2>&1 | nl
	@openssl sha256 -r $@
	@ls -la $@

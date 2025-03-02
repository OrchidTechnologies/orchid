# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pwd/v8 := $(pwd)/v8

$(call include,icu/target.mk)
$(call include,zlb/target.mk)
$(call include,zlb/google.mk)


v8sub := codegen compiler/backend debug deoptimizer diagnostics execution maglev regexp

v8all := $(patsubst ./%,$(pwd/v8)/src/%,$(shell cd $(pwd/v8)/src && find . \
    $(foreach sub,$(v8sub),-path "./$(sub)" -prune -o) \
    -path "./builtins/riscv" -prune -o \
    -path "./d8" -prune -o \
    -path "./heap/base/asm" -prune -o \
    -path "./heap/cppgc/asm" -prune -o \
    -path "./inspector" -prune -o \
    -path "./torque" -prune -o \
    -path "./third_party" -prune -o \
    -path "./tracing" -prune -o \
    -path "./wasm/fuzzing" -prune -o \
    -path "./wasm/interpreter" -prune -o \
    \
    ! -path "./builtins/generate-bytecodes-builtins-list.cc" \
    ! -path "./regexp/gen-regexp-special-case.cc" \
    ! -path "./snapshot/mksnapshot.cc" \
    ! -path "./protobuf/protobuf-compiler-main.cc" \
    \
    ! -path "./init/setup-isolate-deserialize.cc" \
    ! -path "./snapshot/snapshot-external.cc" \
    \
    ! -path "./base/platform/platform-*.cc" \
    ! -path "./libplatform/tracing/recorder-*.cc" \
    \
    ! -path "./base/ubsan.cc" \
    ! -path "./extensions/vtunedomain-support-extension.cc" \
    ! -path "./heap/cppgc/caged-heap.cc" \
    ! -path "./heap/conservative-stack-visitor.cc" \
    ! -path "./libplatform/tracing/trace-event-listener.cc" \
    \
    ! -path "./trap-handler/handler-inside-posix.cc" \
    ! -path "./trap-handler/handler-outside-simulator.cc" \
-name "*.cc" -print | LC_COLLATE=C sort))

v8all += $(pwd/v8)/src/torque/class-debug-reader-generator.cc

v8all += $(foreach sub,$(v8sub),$(wildcard $(pwd)/v8/src/$(sub)/*.cc))
v8all += $(wildcard $(pwd)/v8/src/regexp/experimental/*.cc)
v8all += $(pwd)/v8/src/tracing/trace-event.cc
v8all += $(pwd)/v8/src/tracing/traced-value.cc
v8all += $(pwd)/v8/src/tracing/tracing-category-observer.cc

v8all := $(filter-out %/deoptimizer-cfi-builtins.cc,$(v8all))
v8all := $(filter-out %/deoptimizer-cfi-empty.cc,$(v8all))
v8all := $(filter-out %/system-jit-win.cc,$(v8all))

v8src := $(filter-out \
    %_android.cc \
    %_fuchsia.cc \
    %-mac.cc \
    %-macos.cc \
    %_posix.cc \
    %-posix.cc \
    %_win.cc \
    %-win.cc \
    %-win64.cc \
    %_zos.cc \
,$(v8all))

# XXX: this is a mess that I need to clean up

vflags := 

ifeq ($(machine),x86_64)
vflags += -DV8_TARGET_ARCH_X64
v8src += $(foreach sub,$(v8sub),$(wildcard $(pwd)/v8/src/$(sub)/x64/*.cc))
v8src += $(wildcard $(pwd)/v8/src/codegen/shared-ia32-x64/*.cc)
v8src += $(wildcard $(pwd)/v8/src/compiler/backend/x64/*.cc)
v8src += $(wildcard $(pwd)/v8/src/heap/base/asm/x64/*.cc)
v8src += $(wildcard $(pwd)/v8/src/heap/cppgc/asm/x64/*.cc)
endif

ifeq ($(machine),arm64)
vflags += -DV8_TARGET_ARCH_ARM64
v8src += $(foreach sub,$(v8sub),$(wildcard $(pwd)/v8/src/$(sub)/arm64/*.cc))
v8src += $(wildcard $(pwd)/v8/src/codegen/arm64/*.cc)
v8src += $(wildcard $(pwd)/v8/src/compiler/backend/arm64/*.cc)
v8src += $(wildcard $(pwd)/v8/src/heap/base/asm/arm64/*.cc)
v8src += $(wildcard $(pwd)/v8/src/heap/cppgc/asm/arm64/*.cc)
endif

ifeq ($(machine),armhf)
vflags += -DV8_TARGET_ARCH_ARM
v8src += $(foreach sub,$(v8sub),$(wildcard $(pwd)/v8/src/$(sub)/arm/*.cc))
v8src += $(wildcard $(pwd)/v8/src/codegen/arm/*.cc)
v8src += $(wildcard $(pwd)/v8/src/compiler/backend/arm/*.cc)
v8src += $(wildcard $(pwd)/v8/src/heap/base/asm/arm/*.cc)
v8src += $(wildcard $(pwd)/v8/src/heap/cppgc/asm/arm/*.cc)
endif

vflags += -DV8_HAVE_TARGET_OS

include $(pwd)/target-$(target).mk

# XXX: vflags += -D_LIBCPP_ENABLE_NODISCARD
vflags += -D__ASSERT_MACROS_DEFINE_VERSIONS_WITHOUT_UNDERSCORES=0

vflags += -DGOOGLE3
vflags += -DOFFICIAL_BUILD
vflags += -DNVALGRIND

# XXX: vflags += -DCPPGC_CAGED_HEAP
vflags += -DDYNAMIC_ANNOTATIONS_ENABLED=0
vflags += -DOBJECT_PRINT
vflags += -DENABLE_HANDLE_ZAPPING
vflags += -DENABLE_MINOR_MC
vflags += -DVERIFY_HEAP

# XXX: this seems to be broken now?
# look at 51bad4ef1d2b8cebca9ea1dbe3cc30e80dabf2cd
#vflags += -DV8_31BIT_SMIS_ON_64BIT_ARCH

vflags += -DV8_ADVANCED_BIGINT_ALGORITHMS
vflags += -DV8_ATOMIC_MARKING_STATE
vflags += -DV8_ATOMIC_OBJECT_FIELD_WRITES
vflags += -DV8_DEPRECATION_WARNINGS
vflags += -DV8_ENABLE_CONTINUATION_PRESERVED_EMBEDDER_DATA
vflags += -DV8_ENABLE_LAZY_SOURCE_POSITIONS
vflags += -DV8_ENABLE_REGEXP_INTERPRETER_THREADED_DISPATCH
vflags += -DV8_ENABLE_WEBASSEMBLY
vflags += -DV8_IMMINENT_DEPRECATION_WARNINGS
vflags += -DV8_INTL_SUPPORT
vflags += -DV8_SNAPSHOT_COMPRESSION
vflags += -DV8_TYPED_ARRAY_MAX_SIZE_IN_HEAP=64
#vflags += -DV8_USE_EXTERNAL_STARTUP_DATA
vflags += -DV8_WIN64_UNWINDING_INFO

ifeq ($(bits/$(machine)),64)
#vflags += -DV8_COMPRESS_POINTERS
#vflags += -DV8_COMPRESS_POINTERS_IN_MULTIPLE_CAGES
#vflags += -DV8_SHORT_BUILTIN_CALLS
endif

vflags += -DV8_ENABLE_SPARKPLUG
vflags += -DV8_ENABLE_MAGLEV
vflags += -DV8_ENABLE_TURBOFAN

ifeq ($(machine),x86_64)
vflags += -DV8_ENABLE_WASM_SIMD256_REVEC
else
v8src := $(filter-out $(pwd/v8)/src/compiler/revectorizer.cc,$(v8src))
v8src := $(filter-out $(pwd/v8)/src/compiler/turboshaft/wasm-revec-%,$(v8src))
endif

cflags += -DICU_UTIL_DATA_IMPL=ICU_UTIL_DATA_STATIC

vflags += -DUCHAR_TYPE=char16_t

ifeq ($(target),win)
vflags += -DUNICODE
endif

vflags += -I$(pwd/v8)
vflags += -I$(output)/$(pwd/v8)
vflags += -I$(pwd)/extra

source += $(v8src)

cflags += $(vflags)
# XXX: they almost certainly already fixed this
# (this fixes the build in CI with local clang)
vflags += -include cstdint


# XXX: this now needs to be per target (due to -m$(bits))

$(output)/$(pwd/v8)/gen-regexp-special-case: $(pwd)/v8/src/regexp/gen-regexp-special-case.cc $(pwd)/fatal.cc $(output)/icu4c/lib/libicuuc.a $(output)/icu4c/lib/libicudata.a
	@mkdir -p $(dir $@)
	clang++ -std=c++20 -pthread -o $@ $^ $(vflags) $(icu4c) -ldl -m$(bits/$(machine))

$(output)/$(pwd/v8)/special-case.cc: $(output)/$(pwd/v8)/gen-regexp-special-case
	@mkdir -p $(dir $@)
	$< $@

source += $(output)/$(pwd/v8)/special-case.cc


# XXX: this now needs to be per target (due to -m$(bits))

$(output)/$(pwd/v8)/generate-bytecodes-builtins-list: $(pwd)/v8/src/builtins/generate-bytecodes-builtins-list.cc $(pwd)/v8/src/interpreter/bytecodes.cc $(pwd)/v8/src/interpreter/bytecode-operands.cc $(pwd)/fatal.cc
	@mkdir -p $(dir $@)
	clang++ -std=c++20 -pthread -o $@ $^ $(vflags) -m$(bits/$(machine))

$(output)/$(pwd/v8)/builtins-generated/bytecodes-builtins-list.h: $(output)/$(pwd/v8)/generate-bytecodes-builtins-list
	@mkdir -p $(dir $@)
	$< $@

header += $(output)/$(pwd/v8)/builtins-generated/bytecodes-builtins-list.h


torque := $(patsubst ./%,%,$(sort $(shell cd $(pwd)/v8 && find . -name '*.tq')))

# XXX: because I stopped using -DV8_INTL_SUPPORT
#torque := $(filter-out $(shell sed $(pwd)/v8/BUILD.gn -e '/^if (v8_enable_i18n_support) {/,/^}/!d;/tq"/!d;s/^ *"//;s/".*//'),$(torque))

# XXX: this now needs to be per target (due to -m$(bits))

$(output)/$(pwd/v8)/torque: $(wildcard $(pwd)/v8/src/torque/*.cc) $(pwd)/fatal.cc
	@rm -rf $(dir $@)
	@mkdir -p $(dir $@)
	clang++ -std=c++20 -pthread -o $@ $^ $(vflags) -m$(bits/$(machine))

tqsrc := $(patsubst %.tq,%-tq-csa.cc,$(torque))
tqsrc += class-debug-readers.cc
tqsrc += class-verifiers.cc
tqsrc += debug-macros.cc
tqsrc += exported-macros-assembler.cc
tqsrc += $(patsubst %.cc,%.h,$(tqsrc))
tqsrc += $(patsubst %.tq,%-tq.cc,$(torque))
tqsrc += $(patsubst %.tq,%-tq.inc,$(torque))
tqsrc += $(patsubst %.tq,%-tq-inl.inc,$(torque))
tqsrc += bit-fields.h
tqsrc += builtin-definitions.h
tqsrc += class-forward-declarations.h
tqsrc += csa-types.h
tqsrc += enum-verifiers.cc
tqsrc += factory.cc
tqsrc += factory.inc
tqsrc += interface-descriptors.inc
tqsrc += instance-types.h
tqsrc += objects-body-descriptors-inl.inc
tqsrc += objects-printer.cc
tqsrc += visitor-lists.h
tqsrc := $(patsubst %,$(output)/$(pwd/v8)/torque-generated/%,$(tqsrc))

#$(error - $(filter-out $(shell find $(output)/$(pwd/v8)/torque-generated -name '*.h' -o -name '*.cc' -o -name '*.inc'),$(tqsrc)))
#$(error + $(filter-out $(tqsrc),$(shell find $(output)/$(pwd/v8)/torque-generated -name '*.h' -o -name '*.cc' -o -name '*.inc')))

$(call patternize,$(tqsrc)): $(output)/$(pwd/v8)/torque $(patsubst %,$(pwd)/v8/%,$(torque))
	@for tq in $(tqsrc); do echo "$${tq}"; done | sed -e 's@\(.*\)/.*@\1@' | uniq | while read -r line; do mkdir -p "$${line}"; done
	$< -o $(dir $<)/torque-generated -v8-root $(pwd/v8) $(patsubst ./%,%,$(torque))
	find $(dir $<)/torque-generated -type f -exec touch {} +

archive += $(output)/$(pwd/v8)/torque-generated/

source += $(filter %.cc,$(tqsrc))
header += $(filter %.h %.inc,$(tqsrc))


cflags += -I$(pwd/v8)/src
cflags += -I$(pwd/v8)/include
cflags += -I$(pwd)/extra

# XXX: this is un-breaking something the -iquote for sed hacks is breaking in cppgc
cflags += -iquote$(pwd/v8)/include

# XXX: v8 is using internal ICU API ListFormatter::createInstance
cflags += -DU_SHOW_INTERNAL_API

# XXX: -fno-exceptions -fno-rtti

# this might have to become global if that bitfield is exported
cflags/$(pwd/v8)/ += -Wno-enum-constexpr-conversion

# https://bugs.chromium.org/p/chromium/issues/detail?id=1016945
cflags/$(pwd/v8)/ += -Wno-builtin-assume-aligned-alignment

# XXX: they might have already changed many of these cases
cflags/$(pwd/v8)/ += -Wno-unused-but-set-variable

cflags/$(pwd/v8)/ += -Wno-unneeded-internal-declaration

cflags += -Wno-invalid-offsetof

archive += $(pwd/v8)/

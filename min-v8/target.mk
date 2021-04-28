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


v8sub := codegen compiler/backend debug deoptimizer diagnostics execution

v8all := $(patsubst %,$(pwd/v8)/src/%,$(shell cd $(pwd/v8)/src && find . \
    $(foreach sub,$(v8sub),-path "./$(sub)" -prune -o) \
    -path "./d8" -prune -o \
    -path "./heap/base/asm" -prune -o \
    -path "./heap/cppgc/asm" -prune -o \
    -path "./torque" -prune -o \
    -path "./third_party" -prune -o \
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
-name "*.cc" -print))

v8all += $(foreach temp,$(wildcard $(pwd/v8)/third_party/inspector_protocol/crdtp/*.cc),$(if $(findstring test,$(temp)),,$(temp)))
v8all += $(pwd/v8)/src/torque/class-debug-reader-generator.cc

v8all += $(foreach sub,$(v8sub),$(wildcard $(pwd)/v8/src/$(sub)/*.cc))
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
,$(v8all))

vflags += -DV8_TARGET_ARCH_X64
v8src += $(foreach sub,$(v8sub),$(wildcard $(pwd)/v8/src/$(sub)/x64/*.cc))
v8src += $(wildcard $(pwd)/v8/src/codegen/shared-ia32-x64/*.cc)
v8src += $(wildcard $(pwd)/v8/src/compiler/backend/x64/*.cc)
v8src += $(wildcard $(pwd)/v8/src/heap/base/asm/x64/*.cc)
v8src += $(wildcard $(pwd)/v8/src/heap/cppgc/asm/x64/*.cc)

vflags += -DV8_HAVE_TARGET_OS

include $(pwd)/target-$(target).mk

source += $(v8src)


# XXX: vflags += -D_LIBCPP_ENABLE_NODISCARD
vflags += -D__ASSERT_MACROS_DEFINE_VERSIONS_WITHOUT_UNDERSCORES=0

vflags += -DOFFICIAL_BUILD
vflags += -DNVALGRIND

# XXX: vflags += -DCPPGC_CAGED_HEAP
vflags += -DDYNAMIC_ANNOTATIONS_ENABLED=0
vflags += -DOBJECT_PRINT
vflags += -DENABLE_GDB_JIT_INTERFACE
vflags += -DENABLE_HANDLE_ZAPPING
vflags += -DENABLE_MINOR_MC
vflags += -DVERIFY_HEAP

vflags += -DV8_31BIT_SMIS_ON_64BIT_ARCH
vflags += -DV8_ATOMIC_MARKING_STATE
vflags += -DV8_ATOMIC_OBJECT_FIELD_WRITES
vflags += -DV8_COMPRESS_POINTERS
vflags += -DV8_COMPRESS_POINTERS_IN_ISOLATE_CAGE
vflags += -DV8_DEPRECATION_WARNINGS
vflags += -DV8_ENABLE_LAZY_SOURCE_POSITIONS
vflags += -DV8_ENABLE_REGEXP_INTERPRETER_THREADED_DISPATCH
vflags += -DV8_ENABLE_WEBASSEMBLY
vflags += -DV8_IMMINENT_DEPRECATION_WARNINGS
vflags += -DV8_INTL_SUPPORT
vflags += -DV8_SNAPSHOT_COMPRESSION
vflags += -DV8_TYPED_ARRAY_MAX_SIZE_IN_HEAP=64
#vflags += -DV8_USE_EXTERNAL_STARTUP_DATA
vflags += -DV8_WIN64_UNWINDING_INFO

cflags += -DICU_UTIL_DATA_IMPL=ICU_UTIL_DATA_STATIC

ifeq ($(target),win)
vflags += -DUCHAR_TYPE=wchar_t
else
vflags += -DUCHAR_TYPE=uint16_t
endif

ifeq ($(target),win)
vflags += -DUNICODE
endif

vflags += -I$(pwd/v8)
vflags += -I$(output)/$(pwd/v8)


$(output)/$(pwd/v8)/gen-regexp-special-case: $(pwd)/v8/src/regexp/gen-regexp-special-case.cc $(pwd)/fatal.cc $(output)/icu4c/lib/libicuuc.a $(output)/icu4c/lib/libicudata.a
	@mkdir -p $(dir $@)
	clang++ -std=c++14 -pthread -o $@ $^ $(vflags) $(icu4c) -ldl

$(output)/$(pwd/v8)/special-case.cc: $(output)/$(pwd/v8)/gen-regexp-special-case
	@mkdir -p $(dir $@)
	$< $@

source += $(output)/$(pwd/v8)/special-case.cc


$(output)/$(pwd/v8)/generate-bytecodes-builtins-list: $(pwd)/v8/src/builtins/generate-bytecodes-builtins-list.cc $(pwd)/v8/src/interpreter/bytecodes.cc $(pwd)/v8/src/interpreter/bytecode-operands.cc $(pwd)/fatal.cc
	@mkdir -p $(dir $@)
	clang++ -std=c++14 -pthread -o $@ $^ $(vflags)

$(output)/$(pwd/v8)/builtins-generated/bytecodes-builtins-list.h: $(output)/$(pwd/v8)/generate-bytecodes-builtins-list
	@mkdir -p $(dir $@)
	$< $@

header += $(output)/$(pwd/v8)/builtins-generated/bytecodes-builtins-list.h


torque := $(sort $(shell cd $(pwd)/v8 && find . -name '*.tq'))

$(output)/$(pwd/v8)/torque: $(wildcard $(pwd)/v8/src/torque/*.cc) $(pwd)/v8/src/base/functional.cc $(pwd)/fatal.cc
	@rm -rf $(dir $@)
	@mkdir -p $(dir $@)
	clang++ -std=c++14 -pthread -o $@ $^ $(vflags)

tqsrc := $(patsubst %.tq,%-tq-csa.cc,$(torque))
#tqsrc += class-debug-readers.cc
tqsrc += class-verifiers.cc
#tqsrc += debug-macros.cc
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
tqsrc += field-offsets.h
tqsrc += instance-types.h
tqsrc += objects-body-descriptors-inl.inc
tqsrc += objects-printer.cc
tqsrc := $(patsubst %,$(output)/$(pwd/v8)/torque-generated/%,$(tqsrc))

#$(error - $(filter-out $(subst /./,/,$(shell find $(output)/$(pwd/v8)/torque-generated -name '*.h' -o -name '*.cc' -o -name '*.inc')),$(subst /./,/,$(tqsrc))))
#$(error + $(filter-out $(subst /./,/,$(tqsrc)),$(subst /./,/,$(shell find $(output)/$(pwd/v8)/torque-generated -name '*.h' -o -name '*.cc' -o -name '*.inc'))))

$(call patternize,$(tqsrc)): $(output)/$(pwd/v8)/torque $(patsubst %,$(pwd)/v8/%,$(torque))
	@for tq in $(tqsrc); do echo "$${tq}"; done | sed -e 's@\(.*\)/.*@\1@' | uniq | while read -r line; do mkdir -p "$${line}"; done
	$< -o $(dir $<)/torque-generated -v8-root $(pwd/v8) $(patsubst ./%,%,$(torque))
	find $(dir $<)/torque-generated -type f -exec touch {} +

source += $(filter %.cc,$(tqsrc))
header += $(filter %.h %.inc,$(tqsrc))


inspector := $(patsubst %,$(output)/$(pwd/v8)/src/inspector/protocol/%, \
    Console.cpp \
    Debugger.cpp \
    HeapProfiler.cpp \
    Profiler.cpp \
    Protocol.cpp \
    Runtime.cpp \
    Schema.cpp \
)

source += $(inspector)

# XXX: this should just be the header files
$(filter $(pwd)/v8/src/inspector/%,$(v8src)): $(inspector)

$(call patternize,$(inspector)): $(pwd/v8)/third_party/inspector_protocol/code_generator.py $(pwd/v8)/src/inspector/inspector_protocol_config.json
	@mkdir -p $(output)/$(pwd/v8)/{include,src}/inspector
	cd $(pwd/v8) && PYTHONDONTWRITEBYTECODE=1 third_party/inspector_protocol/code_generator.py --output_base $(CURDIR)/$(output)/$(pwd/v8)/src/inspector --jinja_dir .. --config src/inspector/inspector_protocol_config.json --inspector_protocol_dir third_party/inspector_protocol


cflags += $(vflags)
cflags += -I$(pwd/v8)/include
cflags += -I$(pwd/v8)/src
cflags += -I$(pwd)/extra

# XXX: -fno-exceptions -fno-rtti

# XXX: consider making this a global decision
#chacks/$(pwd/v8)/src/./profiler/heap-snapshot-generator.cc += s/V8_CC_MSVC/1/
cflags += -mno-ms-bitfields

# https://bugs.chromium.org/p/v8/issues/detail?id=11692
cflags/$(pwd/v8)/src/./runtime/runtime-classes.cc += -Wno-unused-variable

# XXX: https://bugs.chromium.org/p/v8/issues/detail?id=11691
cflags/$(pwd/v8)/ += -Wno-implicit-int-float-conversion

# https://bugs.chromium.org/p/chromium/issues/detail?id=1016945
cflags/$(pwd/v8)/ += -Wno-builtin-assume-aligned-alignment

# XXX: v8's compile is ridiculously non-deterministic?! this seems to fix it
cflags/$(pwd/v8)/src/./heap/ += -include src/heap/cppgc/heap.h


archive += $(pwd/v8)
linked += $(pwd/v8).a

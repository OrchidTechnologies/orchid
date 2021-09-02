# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pwd/protobuf := $(pwd)/protobuf

cflags += -I$(pwd/protobuf)/src

source += $(foreach temp,$(wildcard \
    $(pwd/protobuf)/src/google/protobuf/*.cc \
    $(pwd/protobuf)/src/google/protobuf/io/*.cc \
    $(pwd/protobuf)/src/google/protobuf/stubs/*.cc \
),$(if $(findstring mock,$(temp))$(findstring test,$(temp)),,$(temp)))

ifeq ($(target),win)
# XXX: I don't even know what they are trying to accomplish exactly here :(
chacks/$(pwd/protobuf)/src/google/protobuf/io/zero_copy_stream_impl.cc += s/ifndef _MSC_VER/if 0/;
endif

cflags += -DHAVE_PTHREAD

protoc := $(output)/protoc

$(output)/protobuf/%.o: $(pwd/protobuf)/src/google/protobuf/%.cc
	@mkdir -p $(dir $@)
	clang++ -stdlib=libc++ -c -std=c++11 -o $@ -DHAVE_PTHREAD -I$(pwd/protobuf)/src -Isrc $<

$(protoc): $(patsubst $(pwd/protobuf)/src/google/protobuf/%.cc,$(output)/protobuf/%.o,$(shell echo $(pwd/protobuf)/src/google/protobuf/{,compiler/{,cpp/,csharp/,java/,js/,objectivec/,php/,python/,ruby/},io/,stubs/}!(*test*|*mock*).cc))
	@mkdir -p $(dir $@)
	clang++ -stdlib=libc++ -o $@ $^

pflags := 
pflags += -I$(pwd)/protobuf/src

define protobuf
$(foreach ext,cc h,$$(output)/pb$(1)/%.pb.$(ext)): $(2)/%.proto $$(protoc)
	@mkdir -p $$(dir $$@)
	$$(protoc) $$< --cpp_out=$$(output)/pb$(1) $$(pflags)
pflags += -I$(2)
cflags += -I$(output)/pb$(1)
endef

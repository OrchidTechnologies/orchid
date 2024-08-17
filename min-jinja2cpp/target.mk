# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


cflags += -I$(pwd)/expected-lite/include
cflags += -I$(pwd)/optional-lite/include
cflags += -I$(pwd)/string-view-lite/include
cflags += -I$(pwd)/variant-lite/include

cflags += -I$(pwd)/rapidjson/include

cflags += -I$(pwd)/Jinja2Cpp/include

cflags += -DJINJA2CPP_WITH_JSON_BINDINGS_BOOST

source += $(wildcard $(pwd)/Jinja2Cpp/src/*.cpp)
source += $(pwd)/Jinja2Cpp/src/binding/boost_json_serializer.cpp

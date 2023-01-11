# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pwd/pcre2 := $(pwd)/pcre2

cflags += -DPCRE2_CODE_UNIT_WIDTH=8
cflags += -DPCRE2_STATIC

cflags += -I$(pwd)/extra

cflags/$(pwd)/ += -include $(pwd/pcre2)/src/config.h.generic

source += $(pwd)/pcre2_chartables.c
cflags/$(pwd)/pcre2_chartables.c += -I$(pwd/pcre2)/src

source += $(pwd/pcre2)/src/pcre2_auto_possess.c
source += $(pwd/pcre2)/src/pcre2_compile.c
source += $(pwd/pcre2)/src/pcre2_config.c
source += $(pwd/pcre2)/src/pcre2_context.c
source += $(pwd/pcre2)/src/pcre2_dfa_match.c
source += $(pwd/pcre2)/src/pcre2_error.c
source += $(pwd/pcre2)/src/pcre2_find_bracket.c
source += $(pwd/pcre2)/src/pcre2_jit_compile.c
source += $(pwd/pcre2)/src/pcre2_match.c
source += $(pwd/pcre2)/src/pcre2_match_data.c
source += $(pwd/pcre2)/src/pcre2_newline.c
source += $(pwd/pcre2)/src/pcre2_pattern_info.c
source += $(pwd/pcre2)/src/pcre2_script_run.c
source += $(pwd/pcre2)/src/pcre2_string_utils.c
source += $(pwd/pcre2)/src/pcre2_study.c
source += $(pwd/pcre2)/src/pcre2_substring.c
source += $(pwd/pcre2)/src/pcre2_tables.c
source += $(pwd/pcre2)/src/pcre2_ucd.c
source += $(pwd/pcre2)/src/pcre2_valid_utf.c
source += $(pwd/pcre2)/src/pcre2_xclass.c

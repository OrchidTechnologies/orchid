# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


object := $(source)
object := $(patsubst %.c,$(output)/%.o,$(object))
object := $(patsubst %.cc,$(output)/%.o,$(object))
object := $(patsubst %.cpp,$(output)/%.o,$(object))
object := $(patsubst %.m,$(output)/%.o,$(object))
object := $(patsubst %.mm,$(output)/%.o,$(object))

c_ = $(foreach dir,$(subst /, ,$*),$(c_$(dir))) $(cflags_$(basename $(notdir $<)))

$(output)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo [CC] $<
	@$(cycc) -MD -c -o $@ -x c $< $(cflags) $(c_)

$(output)/%.o: %.m
	@mkdir -p $(dir $@)
	@echo [CC] $<
	@$(cycc) -fobjc-arc -MD -c -o $@ $< $(cflags) $(c_)

$(output)/%.o: %.mm
	@mkdir -p $(dir $@)
	@echo [CC] $<
	@$(cycc) -std=gnu++17 -fobjc-arc -MD -c -o $@ $< $(cflags) $(c_)

$(output)/%.o: %.cc
	@mkdir -p $(dir $@)
	@echo [CC] $<
	@$(cycc) -std=c++11 -ObjC++ -MD -c -o $@ $< $(cflags) $(c_)

$(output)/%.o: %.cpp
	@mkdir -p $(dir $@)
	@echo [CC] $<
	@$(cycc) -std=c++2a -ObjC++ -MD -c -o $@ $< $(cflags) $(c_)

.PHONY: clean
clean:
	rm -rf $(cleans)

-include $(patsubst %.o,%.d,$(sort $(object)))

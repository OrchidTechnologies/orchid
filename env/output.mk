# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2019  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


checks_ := $(subst $(space),$(comma),$(strip $(checks)))
checks = $(checks_),$(subst $(space),$(comma),$(checks/./$<))

# XXX: this is not a very accurate filter expression
filter := 
filter += source/.*\.[ch]pp
filter := (^|/)($(subst $(space),|,$(patsubst %,%,($(strip $(filter))))))$$

.PHONY: printenv
printenv:
	printenv

object := $(foreach _,$(sort $(source)),$(_).o)

code = $(patsubst @/%,$(output)/$(arch)/%,$(header)) $(sysroot)

# XXX: replace cflags with cflags/ once I fix pwd to not begin with ./
# in this model, cflags would be something controlled only by the user
flags_ = $(if $(filter ./,$(1)),,$(call flags_,$(dir $(patsubst %/,%,$(1)))) $(cflags/$(1)))
flags- = $(call flags_,$(patsubst ./$(output)/%,%,$(patsubst ./$(output)/$(arch)/%,./$(output)/%,./$(dir $<))))
flags = $(qflags) $(patsubst -I@/%,-I$(output)/$(arch)/%,$(filter -I%,$(cflags/./$<) $(flags-) $(cflags)) $(filter-out -I%,$(cflags) $(flags-) $(cflags/./$<)))

$(output)/%.c.o: $$(specific) $$(folder).c $$(code)
	$(specific)
	@mkdir -p $(dir $@)
	@echo [CC] $(target)/$(arch) $<
	$(job)@$(prefix) $(cc) $(more/$(arch)) -MD -MP -c -o $@ $< $(flags)

$(output)/%.m.o: $$(specific) $$(folder).m $$(code)
	$(specific)
	@mkdir -p $(dir $@)
	@echo [CC] $(target)/$(arch) $<
	$(job)@$(prefix) $(cc) $(more/$(arch)) -fobjc-arc -MD -MP -c -o $@ $< $(flags)

$(output)/%.mm.o: $$(specific) $$(folder).mm $$(code)
	$(specific)
	@mkdir -p $(dir $@)
	@echo [CC] $(target)/$(arch) $<
	$(job)@$(prefix) $(cxx) $(more/$(arch)) -std=gnu++17 -fobjc-arc -MD -MP -c -o $@ $< $(flags) $(xflags)

$(output)/%.cc.o: $$(specific) $$(folder).cc $$(code)
	$(specific)
	@mkdir -p $(dir $@)
	@echo [CC] $(target)/$(arch) $<
	$(job)@$(prefix) $(cxx) $(more/$(arch)) -std=c++17 -MD -MP -c -o $@ $< $(flags) $(xflags)

$(output)/%.cpp.o: $$(specific) $$(folder).cpp $$(code)
	$(specific)
	@mkdir -p $(dir $@)
ifeq ($(filter notidy,$(debug)),)
	@if [[ $< =~ $(filter) && ! $< =~ .*/(lwip|monitor)\.cpp ]]; then \
	    echo [CT] $(target)/$(arch) $<; \
	    $(tidy) $< --quiet --warnings-as-errors='*' --header-filter='$(filter)' --config='{Checks: "$(checks)", CheckOptions: [{key: "performance-move-const-arg.CheckTriviallyCopyableMove", value: 0}, {key: "bugprone-exception-escape.IgnoredExceptions", value: "broken_promise"}]}' -- \
	        $(wordlist 2,$(words $(cxx)),$(cxx)) $(more/$(arch)) -std=c++2a $(flags) $(xflags); \
	fi
endif
	@echo [CC] $(target)/$(arch) $<
	$(job)@sed -e '1{x;s!.*!#line 1 "$<"!;p;x;};$(chacks/./$<)' $< | $(prefix) $(cxx) $(more/$(arch)) -std=c++2a -MD -MP -c -o $@ -x c++ - -iquote$(dir $<) $(flags) $(xflags)

$(output)/%.rc.o: $$(specific) $$(folder).rc $$(code)
	$(specific)
	@mkdir -p $(dir $@)
	@echo [RC] $(target)/$(arch) $<
	$(job)@$(prefix) $(windres/$(arch)) -o $@ $< $(filter -I%,$(flags) $(xflags))

define _
$(shell env/meson.sh $(1) $(output) '$(CURDIR)' '$(meson) $(meson/$(1))' '$(ar/$(1))' '$(strip/$(1))' '$(windres/$(1))' '$(cc) $(more/$(1))' '$(cxx) $(more/$(1))' '$(objc) $(more/$(1))' '$(qflags)' '$(wflags)' '$(xflags)' '$(mflags)')
endef
$(each)

%/configure: %/configure.ac
	env/autogen.sh $(dir $@)

$(output)/%/Makefile: $$(specific) $$(folder)/configure $(sysroot) $$(call head,$$(folder))
	$(specific)
	@rm -rf $(dir $@)
	@mkdir -p $(dir $@)
	cd $(dir $@) && $(CURDIR)/$< --host=$(host/$(arch)) --prefix=$(CURDIR)/$(output)/$(arch)/usr \
	    CC="$(cc) $(more/$(arch))" CFLAGS="$(qflags)" CXX="$(cxx) $(more/$(arch))" CXXFLAGS="$(qflags) $(xflags)" \
	    RANLIB="$(ranlib/$(arch))" AR="$(ar/$(arch))" PKG_CONFIG="$(CURDIR)/env/pkg-config" \
	    CPPFLAGS="$(patsubst -I@/%,-I$(CURDIR)/$(output)/$(arch)/%,$(p_$(subst -,_,$(notdir $(patsubst %/configure,%,$<)))))" \
	    LDFLAGS="$(wflags) $(patsubst -L@/%,-L$(CURDIR)/$(output)/$(arch)/%,$(l_$(subst -,_,$(notdir $(patsubst %/configure,%,$<)))))" \
	    --enable-static --disable-shared $(subst =@/,=$(CURDIR)/$(output)/$(arch)/,$(w_$(subst -,_,$(notdir $(patsubst %/configure,%,$<)))))
	cd $(dir $@); $(m_$(subst -,_,$(notdir $(patsubst %/configure,%,$<))))

$(output)/%/build.ninja: $$(specific) $$(folder)/meson.build $(output)/$$(arch)/meson.txt $(sysroot) $$(call head,$$(folder))
	$(specific)
	@rm -rf $(dir $@)
	@mkdir -p $(dir $@)
	cd $(dir $<) && meson --cross-file $(CURDIR)/$(output)/$(arch)/meson.txt $(CURDIR)/$(dir $@) \
	    -Ddefault_library=static $(w_$(subst -,_,$(notdir $(patsubst %/meson.build,%,$<))))
	cd $(dir $@); $(m_$(subst -,_,$(notdir $(patsubst %/meson.build,%,$<))))

ifeq ($(shell which rustup),)
export PATH := $(HOME)/.cargo/bin:$(PATH)
endif

.PHONY: $(output)/%.rustup
$(output)/%.rustup:
	rustup target add $*

ifneq ($(uname-o),Cygwin)
export RUSTC_WRAPPER=$(CURDIR)/env/rustc-wrapper
endif

$(output)/%/librust.a: $$(specific) $$(folder)/Cargo.toml $(output)/$$(triple/$$(arch)).rustup $(sysroot) $$(call head,$$(folder))
	$(specific)
	@mkdir -p $(dir $@)
	cd $(folder) && RUST_BACKTRACE=1 PATH=$${PATH}:$(dir $(word 1,$(cc))) \
	    $(if $(ccrs/$(arch)),$(ccrs/$(arch)),TARGET)_CC='$(cc) $(more/$(arch)) $(qflags)' \
	    $(if $(ccrs/$(arch)),$(ccrs/$(arch)),TARGET)_AR='$(ar/$(arch))' \
	    PKG_CONFIG_ALLOW_CROSS=1 PKG_CONFIG="$(CURDIR)/env/pkg-config" ENV_ARCH="$(arch)" \
	    CARGO_HOME='$(call path,$(CURDIR)/$(output)/cargo)' CARGO_INCREMENTAL=0 \
	    cargo build --verbose --lib --release --target $(triple/$(arch)) \
	    --target-dir $(call path,$(CURDIR)/$(output)/$(arch)/$(folder))
	cp -f $(output)/$(arch)/$(folder)/$(triple/$(arch))/release/deps/lib$(subst -,_,$(notdir $(folder))).a $@

.PHONY: clean
clean:
	git clean -fXd

define _
-include $(patsubst %.o,$(output)/$(1)/%.d,$(object))
endef
$(each)

define _
$(output)/%/$(1).a: $(patsubst %,$(output)/$$(percent)/%,$(filter $(1)/%,$(object)))
	@rm -f $$@
	@echo [AR] $$@
	@$$(ar/$$*) -rs $$@ $$^
object := $(filter-out $(1)/%.o,$(object))
endef
$(foreach archive,$(archive),$(eval $(call _,$(archive))))

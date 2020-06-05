# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2019  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


checks := 
# XXX: this check simply doesn't work. I'm fixing it :/
#checks += bugprone-exception-escape
checks += bugprone-forwarding-reference-overload
checks += bugprone-misplaced-widening-cast
checks += bugprone-move-forwarding-reference
checks += bugprone-parent-virtual-call
checks += bugprone-suspicious-missing-comma
checks += bugprone-too-small-loop-variable
checks += bugprone-undefined-memory-manipulation
checks += bugprone-unhandled-self-assignment
checks += bugprone-use-after-move
# XXX: move all of our global statics with function local
#checks += cert-err58-cpp
checks += cert-err60-cpp
checks += cppcoreguidelines-interfaces-global-init
checks += cppcoreguidelines-narrowing-conversions
checks += cppcoreguidelines-no-malloc
checks += cppcoreguidelines-owning-memory
# XXX: somehow string constants with iostreams trigger this
#checks += cppcoreguidelines-pro-bounds-array-to-pointer-decay
#checks += cppcoreguidelines-pro-bounds-constant-array-index
#checks += cppcoreguidelines-pro-bounds-pointer-arithmetic
checks += cppcoreguidelines-pro-type-const-cast
checks += cppcoreguidelines-pro-type-cstyle-cast
#checks += cppcoreguidelines-pro-type-member-init
#checks += cppcoreguidelines-pro-type-reinterpret-cast
checks += cppcoreguidelines-pro-type-static-cast-downcast
checks += cppcoreguidelines-pro-type-vararg
checks += cppcoreguidelines-slicing
# XXX: it isn't clear to me whether this is overkill or not
#checks += cppcoreguidelines-special-member-functions
# XXX: boost native_to_big is not marked constexpr, for Tag
# https://github.com/boostorg/endian/issues/34
#checks += fuchsia-statically-constructed-objects
checks += fuchsia-virtual-inheritance
checks += google-build-namespaces
checks += misc-definitions-in-headers
checks += misc-noexcept-moveconstructor
checks += misc-non-copyable-objects
# XXX: the r20 clang-tidy doesn't seem to do this correctly
#checks += misc-non-private-member-variables-in-classes
checks += misc-static-assert
checks += misc-throw-by-value-catch-by-reference
checks += misc-unconventional-assign-operator
checks += modernize-deprecated-headers
checks += modernize-deprecated-ios-base-aliases
checks += modernize-make-shared
checks += modernize-make-unique
checks += modernize-redundant-void-arg
checks += modernize-replace-auto-ptr
checks += modernize-return-braced-init-list
checks += modernize-unary-static-assert
checks += modernize-use-bool-literals
checks += modernize-use-emplace
checks += modernize-use-equals-default
checks += modernize-use-equals-delete
# XXX: this check is super verbose on clang 9
#checks += modernize-use-nodiscard
checks += modernize-use-noexcept
checks += modernize-use-nullptr
checks += modernize-use-override
checks += performance-for-range-copy
checks += performance-implicit-conversion-in-loop
checks += performance-inefficient-string-concatenation
checks += performance-move-const-arg
checks += performance-move-constructor-init
checks += performance-noexcept-move-constructor
checks += performance-unnecessary-copy-initialization
checks += performance-unnecessary-value-param
checks += readability-const-return-type
checks += readability-container-size-empty
checks += readability-deleted-default
checks += readability-implicit-bool-conversion
checks += readability-inconsistent-declaration-parameter-name
checks += readability-isolate-declaration
checks += readability-redundant-member-init
checks += readability-redundant-smartptr-get
checks += readability-redundant-string-cstr
#checks += readability-redundant-string-init
checks += readability-static-definition-in-anonymous-namespace
checks += readability-uniqueptr-delete-release
# XXX: boost asio reactor::per_descriptor_data reactor_data_
checks += -clang-analyzer-optin.cplusplus.UninitializedObject
ifeq ($(target),and)
# XXX: boost multiprecision on android
checks += -clang-analyzer-core.UndefinedBinaryOperatorResult
endif
ifeq ($(target),win)
# XXX: boost asio threading on win32
checks += -clang-analyzer-cplusplus.NewDelete
checks += -clang-analyzer-cplusplus.NewDeleteLeaks
# XXX: -Wno-nonportable-include-path isn't working
checks += -clang-diagnostic-nonportable-include-path
endif
checks := $(subst $(space),$(comma),$(strip $(checks)))

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
	$(job)@$(prefix) $(cxx) $(more/$(arch)) -std=c++14 -MD -MP -c -o $@ $< $(flags) $(xflags)

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
	$(job)@$(prefix) $(cxx) $(more/$(arch)) -std=c++2a -MD -MP -c -o $@ $< $(flags) $(xflags)

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

$(output)/%/librust.a: $$(specific) $$(folder)/Cargo.toml $(output)/$$(triple/$$(arch)).rustup $(sysroot) $$(call head,$$(folder))
	$(specific)
	@mkdir -p $(dir $@)
	cd $(folder) && RUST_BACKTRACE=1 RUSTC_WRAPPER=$(CURDIR)/env/rustc-wrapper PATH=$${PATH}:$(dir $(word 1,$(cc))) \
	    $(if $(ccrs/$(arch)),$(ccrs/$(arch)),TARGET)_CC='$(cc) $(more/$(arch)) $(qflags)' AR='$(ar/$(arch))' \
	    PKG_CONFIG_ALLOW_CROSS=1 PKG_CONFIG="$(CURDIR)/env/pkg-config" ENV_ARCH="$(arch)" \
	    CARGO_HOME='$(CURDIR)/$(output)/cargo' cargo build --verbose --lib --release \
	    --target $(triple/$(arch)) --target-dir $(CURDIR)/$(output)/$(arch)/$(folder)
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
object := $(filter-out $(1)/%.o,$(object)) $(1).a
endef
$(foreach archive,$(archive),$(eval $(call _,$(archive))))

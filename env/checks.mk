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
# XXX: ./vpn/source/client.hpp:78:12: note: Excessive padding in 'struct orc::Client::Locked_' (32 padding bytes, where 0 is optimal). Optimal fields order: spent_, balance_, recipient_, updated_, benefit_, serial_, ring_, pending_, commit_, consider reordering the fields or adding explicit padding members
checks += -clang-analyzer-optin.performance.Padding
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

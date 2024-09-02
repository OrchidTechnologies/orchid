# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


checks := 

checks += bugprone-*
checks/bugprone-argument-comment.StrictMode := true
checks += -bugprone-branch-clone
checks += -bugprone-easily-swappable-parameters
# XXX: I should enable this check and do a comprehensive audit
checks += -bugprone-empty-catch
# XXX: this is higher priority but I'm not ready for this yet
checks += -bugprone-exception-escape
checks/bugprone-exception-escape.IgnoredExceptions := "broken_promise"
checks += -bugprone-lambda-function-name
checks += -bugprone-macro-parentheses
checks += -bugprone-reserved-identifier
# XXX: look into these cases and maybe use new(std::nothrow)
checks += -bugprone-unhandled-exception-at-new

checks += cert-*
# XXX: this check won't tell me where the issue was :(
checks += -cert-dcl16-c
checks += -cert-dcl37-c
checks += -cert-dcl51-cpp
checks += -cert-dcl58-cpp
checks += -cert-env33-c
checks += -cert-err58-cpp

checks += clang-analyzer-*
# XXX: this flags something in boost multiprecision (of course)
checks += -clang-analyzer-core.BitwiseShift

checks += cppcoreguidelines-*
checks += -cppcoreguidelines-avoid-c-arrays
checks += -cppcoreguidelines-avoid-capturing-lambda-coroutines
# this check is the exact opposite of a good guideline :/
checks += -cppcoreguidelines-avoid-const-or-ref-data-members
checks += -cppcoreguidelines-avoid-do-while
checks += -cppcoreguidelines-avoid-goto
# this check is probably more worthwhile working with amateurs
checks += -cppcoreguidelines-avoid-magic-numbers
checks/cppcoreguidelines-avoid-magic-numbers.IgnorePowersOf2IntegerValues := true
checks += -cppcoreguidelines-avoid-reference-coroutine-parameters
# this check would be less annoying if it ignored "next statement uses &variable"
checks += -cppcoreguidelines-init-variables
# XXX: I didn't pay any attention to whether this check was interesting or not
checks += -cppcoreguidelines-macro-usage
# this was accidentally helpful, actually, but isn't an acceptable decision :/
checks += -cppcoreguidelines-misleading-capture-default-by-value
# this check doesn't handle unused parameters; am I doing this wrong?!
checks += -cppcoreguidelines-missing-std-forward
checks += -cppcoreguidelines-non-private-member-variables-in-classes
# XXX: the code which most hates this apparently does allow for memory leaks :(
checks += -cppcoreguidelines-prefer-member-initializer
# this check flags all const char[] -> const char *, including __FUNCTION__ :/
checks += -cppcoreguidelines-pro-bounds-array-to-pointer-decay
checks += -cppcoreguidelines-pro-bounds-pointer-arithmetic
checks += -cppcoreguidelines-pro-type-reinterpret-cast
checks += -cppcoreguidelines-pro-type-union-access
# XXX: this check is interesting, but I'm unsure about move/forward confusion
checks += -cppcoreguidelines-rvalue-reference-param-not-moved
checks/cppcoreguidelines-rvalue-reference-param-not-moved.IgnoreUnnamedParams := true
# this check makes utility classes super frustrating :/
checks += -cppcoreguidelines-special-member-functions
# this check makes separates definitions of related variables
checks += -cppcoreguidelines-use-default-member-init

# XXX: I'm using a lot of statically constructed objects
#checks += fuchsia-statically-constructed-objects
checks += fuchsia-virtual-inheritance

checks += google-build-*

checks += misc-*
# I love the idea of this check, but boost does this a lot
checks += -misc-header-include-cycle
checks += -misc-include-cleaner
checks += -misc-misplaced-const
checks += -misc-no-recursion
# this check doesn't allow for any protected members :/
checks += -misc-non-private-member-variables-in-classes
checks/misc-non-private-member-variables-in-classes.IgnoreClassesWithAllMemberVariablesBeingPublic := 1
checks += -misc-unused-parameters

checks += modernize-*
checks += -modernize-avoid-c-arrays
# XXX: I don't want this, but it also crashes on boost::multiprecision::abs
checks += -modernize-use-constraints
checks += -modernize-use-default-member-init
checks += -modernize-use-nodiscard
checks += -modernize-use-trailing-return-type
# XXX: I like this idea, but don't want to do it today
checks += -modernize-use-using

checks += performance-*
checks/performance-move-const-arg.CheckTriviallyCopyableMove := 0
# XXX: I am pretty sure I just disagree with this optimization
checks += -performance-avoid-endl

checks += readability-const-return-type
checks += readability-container-size-empty
checks += readability-deleted-default
checks += readability-implicit-bool-conversion
checks += readability-inconsistent-declaration-parameter-name
checks += readability-isolate-declaration
checks += readability-redundant-member-init
checks += readability-redundant-smartptr-get
checks += readability-redundant-string-cstr
checks += readability-redundant-string-init
checks += readability-static-definition-in-anonymous-namespace
checks += readability-uniqueptr-delete-release

ifeq ($(target),win)
# XXX: boost::asio::detail::do_throw_error should be [[noreturn]]
# (though, marking it [[noreturn]] didn't actually make it work)
checks += -clang-analyzer-cplusplus.NewDelete
# XXX: this accidentally flags correct includes due to my workarounds
checks += -clang-diagnostic-nonportable-include-path
endif

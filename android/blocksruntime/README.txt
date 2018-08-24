
Blocks Runtime
==============

This project provides a convenient way to install the BlocksRuntime library
from the compiler-rt project (see <http://compiler-rt.llvm.org/>).

Several systems (Linux, FreeBSD, MacPorts, etc.) provide the clang compiler
either preinstalled or as an available package which has Blocks support
(provided the `-fblocks` compiler option is used).

Unfortunately, those installer packages do not provide the Blocks runtime
library.

On the other hand, the compiler-rt library can be downloaded and does contain
the Blocks runtime support if properly enabled in the cmake build file.

By default, however, the compiler-rt library also builds a compiler runtime
support library which is undesirable.

This project contains only the BlocksRuntime files (in the `BlocksRuntime`
subdirectory) along with tests (in the `BlocksRuntime/tests` subdirectory) and
the original `CREDITS.TXT`, `LICENSE.TXT` and `README.txt` from the top-level
`compiler-rt` project (which have been placed in the `BlocksRuntime`
subdirectory).  Note that in 2014-02 the compiler-rt project moved the
BlocksRuntime sources from the `BlocksRuntime` directory to the
`lib/BlocksRuntime` directory and moved the tests from the `BlocksRuntime/tests`
directory to the `test/BlocksRuntime` directory.  The files themselves, however,
remain unchanged and are still the same as they were in 2010-08.

This runtime can also be used with the `gcc-apple-4.2` compiler built using the
MacPorts.org apple-gcc42 package on Mac OS X.



License
-------

The compiler-rt project (and hence the BlocksRuntime since it's a part of that
project) has a very liberal dual-license of either the UIUC or MIT license.
The MIT license is fully GPL compatible (and pretty much compatible with just
about everything), so there should be no problems linking the
`libBlocksRuntime.a` library with your executable.  (Note that on the FSF's site
<http://www.gnu.org/licenses/license-list.html>, you find the MIT license under
the 'X11 License' section.)  See the `LICENSE.TXT` file in the `BlocksRuntime`
subdirectory for all the details.



Building
--------

Since there are only two files to build, a makefile didn't seem warranted.  A
special `config.h` file has been created to make the build work.  Build the
`libBlocksRuntime.a` library by running:

        ./buildlib

The `gcc` compiler will be used by default, but you can do `CC=clang ./buildlib`
for example to use the `clang` compiler instead.  Note that neither `make` nor
`cmake` are needed (but `ar` and `ranlib` will be used but they can also be
changed with the `AR` and `RANLIB` environment variables similarly to the way
the compiler can be changed).

**IMPORTANT** Mac OS X Note:  If you are building this library on Mac OS X
(presumably to use with a `clang` or `gcc-apple-4.2` built with MacPorts or
otherwise obtained), you probably want a fat library with multiple architectures
in it.  You can do that with the `CFLAGS` variable like so:

        CFLAGS='-O2 -arch x86_64 -arch ppc64 -arch i386 -arch ppc' ./buildlib

The `buildlib-osx` script will attempt to make an intelligent guess about
building an OS X library and then run `buildlib`.  If you're using Mac OS X you
can do this to build a FAT OS X library:

        ./buildlib-osx

The `buildlib` (and `buildlib-osx`) script takes a single optional `-shared`
argument.  If given it will attempt to also build a shared library instead
of just a static one in case you have a policy situation where use of a static
library has been forbidden.



Testing
-------

Skip this step at your peril!  It's really quite painless.  You see it's
possible that the underlying blocks ABI between the blocks runtime files
provided in this project and the blocks ABI used by your version of the clang
compiler to implement the `-fblocks` option have diverged in an incompatible
way.  If this has happened, at least some of the tests should fail in
spectacular ways (i.e. bus faults).  For that reason skipping this step is not
recommended.

You must have the clang compiler with `-fblocks` support installed for this step
(if you don't have a clang compiler with `-fblocks` support available, why
bother installing the Blocks runtime in the first place?)  
Run the tests like so:

        ./checktests

By default `checktests` expects the `clang` compiler to be available in the
`PATH` and named `clang`.  If you are using `gcc-apple-4.2` or your `clang` is
named something different (such as `clang-mp-2.9` or `clang-mp-3.0`) run the
tests like this instead (replacing `clang-mp-3.0` with your compiler's name):

        CC=clang-mp-3.0 ./checktests

Problems are indicated with a line that starts `not ok`.  You will see a few
of these.  The ones that are marked with `# TODO` are expected to fail for the
reason shown.  The `copy-block-literal-rdar6439600.c` expected failure is a real
failure.  No it's not a bug in the Blocks runtime library, it's actually a bug
in the compiler.  You may want to examine the `copy-block-literal-rdar6439600.c`
source file to make sure you fully grok the failure so you can avoid getting
burned by it in your code.  There may be a fix in the clang project by now (but
as of the clang 3.2 release it still seems to fail), however it may be a while
until it rolls downhill to your clang package.

If you are using `CC=gcc-apple-4.2`, you will probably get two additional expect
failure compiler bugs in the `cast.c` and `josh.C` tests.  These extra failures
are not failures in the blocks runtime itself, just `gcc` not accepting some
source files that `clang` accepts.  You can still use the `libBlocksRuntime.a`
library just fine.

Note that if you have an earlier version of `clang` (anything before version 2.8
see `clang -v`) then `clang++` (C++ support) is either incomplete or missing and
the few C++ tests (`.C` extension) will be automatically skipped (if `clang++`
is missing) or possibly fail in odd ways (if `clang++` is present but older than
version 2.8).

Note that the `./checktests` output is TAP (Test Anything Protocol) compliant
and can therefore be run with Perl's prove utility like so:

        prove -v checktests

Optionally first setting `CC` like so:

        CC=gcc-apple-4.2 prove -v checktests

Omit the `-v` option for more succinct output.



ARM Hard Float Bug
------------------

When running on a system that uses the ARM hard float ABI (e.g. RaspberryPi),
the clang compiler has a bug.  When passing float arguments to a vararg function
they must also be passed on the stack, not just in hardware floating point
registers.  The clang compiler does this correctly for normal vararg functions,
but fails to do this for block vararg functions.

If you really need this, a workaround is to call a normal vararg function that
takes a block and `...` arguments.  It can then package up the `...` arguments
into a `va_list` and then call the block it was passed as an argument passing
the block the `va_list`.  This works fine and avoids the `clang` bug even
though it's fugly.

The `checktests` script marks this test (`variadic.c`) as expect fail when
running the tests on an ARM hard float ABI system if it's able to detect that
the ARM hard float ABI is in use.



clang -fblocks failure
----------------------

If clang is not using the integrated assembler (option `-integrated-as`) then it
will incorrectly pass options such as `-fblocks` down to the assembler which
will probably not like it.  One example of an error caused by this bug is:

        gcc: error: unrecognized command line option '-fblocks'

In this case clang is not using the integrated assembler (which is not supported
on all platforms) and passes the `-fblocks` option down to the gcc assembler
which does not like that option at all.

The following references talk about this:

- <http://thread.gmane.org/gmane.comp.compilers.llvm.devel/56563>
- <http://llvm.org/bugs/show_bug.cgi?id=12920>

The ugly workaround for this problem is to compile the sources using both the
`-S` and `-fblocks` options to produce a `.s` file which can then be compiled
into whatever is desired without needing to use the `-fblocks` option.

If `checktests` detects this situation it will emit a line similar to this:

        WARNING: -S required for -fblocks with clang

If this is the case, then rules to compile `.c` into `.s` and then compile `.s`
into `.o` (or whatever) will be needed instead of the usual compile `.c` into
`.o` (or whatever).

Note that this workaround is required to use `-fblocks` with the version of
clang included with cygwin.



Installing
----------

Assuming that you have built the library (with `./buildlib`) and are satisfied
it works (`./checktests`) then it can be installed with:

        sudo ./installlib

The default installation `prefix` is `/usr/local`, but can be changed to
`/myprefix` like so:

        sudo env prefix=/myprefix ./installlib

The include file (`Block.h`) is installed into `$prefix/include` and the library
(`libBlocksRuntime.a`) into `$prefix/lib` by default.  (Those can also be
changed by setting and exporting `includedir` and/or `libdir` in the same way
`prefix` can be changed.)

If you want to see what will be installed without actually installing use:

        ./installlib --dry-run

Note that `DESTDIR` is supported by the `installlib` script if that's needed.
Just set `DESTDIR` before running `installlib` the same way `prefix` can be set.

Note that if the shared library exists it will also be installed.  Add a single
optional `-shared` or `-static` option to install only one or the other.



Sample Code
-----------

After you have installed the Blocks runtime header and library, you can check
to make sure everything's working by building the `sample.c` file.  The
instructions are at the top of the file (use `head sample.c` to see them) or
just do this (replace `clang` with the name of the compiler you're using):

        clang -o sample -fblocks sample.c -lBlocksRuntime && ./sample

If the above line outputs `Hello world 2` then your Blocks runtime support is
correctly installed and fully usable.  Have fun!

Note that if you have the problem described above in the section named
"clang -fblocks failure", then you'll need to do this instead:

        clang -S -o sample.s -fblocks sample.c && \
        clang -o sample sample.s -lBlocksRuntime && ./sample

Note that it's possible to use the Blocks runtime without installing it into
the system directories.  You simply need to add an appropriate `-I` option to
find the `Block.h` header when you compile your source(s).  And a `-L` option to
find the `libBlocksRuntime.a` library when you link your executable.  Since
`libBlocksRuntime.a` is a static library no special system support will be
needed to run the resulting executable.



Glibc Problem
-------------

The `unistd.h` header from older versions of `glibc` has an incompatibility with
the `-fblocks` option.  See <http://mackyle.github.io/blocksruntime/#glibc> for
a workaround.

This problem was corrected with commit 84ae135d3282dc362bed0a5c9a575319ef336884
(<http://repo.or.cz/w/glibc.git/commit/84ae135d>) on 2013-11-21 and first
appears in `glibc-2.19` released on 2014-02-07.  Since `ldd` is part of `glibc`
you can check to see what version of `glibc` you have with:

        ldd --version



Documentation
-------------

You can find information on the Blocks language extension at these URLs

- <http://clang.llvm.org/docs/LanguageExtensions.html#blocks>
- <http://clang.llvm.org/docs/BlockLanguageSpec.html>
- <http://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Blocks>
- <http://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Blocks/Blocks.pdf>

#!/bin/bash

here=$(which "$0")
if test -L "${here}"; then
    here=$(readlink "${here}")
fi
here=${here%/*}

args=()
for arg in "$@"; do case "${arg}" in
    (--print-errors);;
    (--short-errors);;
    (*) args+=("${arg}")
esac; done

echo "${args[*]}" >>/tmp/pkg-config.log

case "${args[*]}" in
    ("--exists libpng") ;;
    ("--libs libpng") echo "-lpng16 -lz";;

    ("--exists pixman-1 >= 0.36.0") ;;

    # glib only really needs zlib for gio
    ("--modversion zlib") echo "1.2.13";;
    ("--cflags zlib") echo "";;
    ("--libs zlib") echo "";;

    (*) exec "${ENV_CURDIR}/${ENV_OUTPUT}/${ENV_ARCH}/usr/bin/pkg-config" "$@";;
esac

#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
data="$STRHOME/examples/data"
mkdir -p "$data"

function add_file {
  file=$1
  name=$(basename $file)
  echo "Generating file $name in data"
  [ -f "$file" ] || dd if=/dev/urandom of="$file" bs=1K count=1 status=none
}

# Add a few test files to the examples data dir
add_file "$data/foo_file.dat"
add_file "$data/bar_file.dat"
add_file "$data/baz_file.dat"


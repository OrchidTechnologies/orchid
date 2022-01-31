#!/bin/sh
#
# Generate a quick and dirty static API for our asssets
#

cd $(dirname "$0")

run() {

generate() {
  body=$(
  for f in $files
  do
      name=$(basename $f | tr '[:upper:]' '[:lower:]' | sed 's/[- ]/_/g' | sed 's/\..\{3,4\}$//')
      echo "  static const ${name}_path = '$f';"
      echo "  final $name = ${constructor}(${name}_path);"
  done)
cat <<-END
class $classname {
  ${classname}();

$body
}

END
}

cat <<END
//
// Do not modify: Generated by generate-assets.sh.
//
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

class OrchidAsset {
  static final svg = OrchidAssetSvg();
  static final image = OrchidAssetImage();
  static final token = OrchidAssetSvgToken();
  static final chain = OrchidAssetSvgChain();
}

END

files=assets/images/*.png
classname="OrchidAssetImage"
constructor="Image.asset"
generate

# For the few cases where we need direct access to the highest res image.
files=assets/images/3.0x/*.png
classname="OrchidAssetImage3x"
constructor="Image.asset"
generate

files=assets/svg/*.svg
classname="OrchidAssetSvg"
constructor="SvgPicture.asset"
generate

files=assets/svg/chains/*.svg
classname="OrchidAssetSvgChain"
constructor="SvgPicture.asset"
generate

files=assets/svg/tokens/*.svg
classname="OrchidAssetSvgToken"
constructor="SvgPicture.asset"
generate
}

outfile=lib/orchid/orchid_asset.dart
run > $outfile
echo "Generated to: $outfile"


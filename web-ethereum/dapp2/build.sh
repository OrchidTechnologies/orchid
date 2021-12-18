FLUTTER=../../app-shared/flutter/bin/flutter
rm -rf build
#$FLUTTER build web --web-renderer canvaskit --dart-define mock=true
$FLUTTER build web --web-renderer canvaskit

# remove base tag
sed -i '' 's/<base href="\/">//' build/web/index.html

# move js to hash named file
uuid=$(uuidgen)
sed -i '' "s/main.dart.js/${uuid}.main.dart.js/g" build/web/index.html
mv build/web/main.dart.js "build/web/${uuid}.main.dart.js"


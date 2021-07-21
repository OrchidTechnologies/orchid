
# Workaround to use the Flutter Intl plugin temporarily to extract strings.
# (cd lib/l10n; ln -s app_en.arb intl_en.arb)
# rm -rf lib/generated lib/l10n/intl_en.arb

# Generate localizations
../app-shared/flutter/bin/flutter gen-l10n

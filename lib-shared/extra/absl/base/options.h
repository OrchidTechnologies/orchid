#include_next <absl/base/options.h>
// XXX: maybe only #ifdef __APPLE__?
// iOS 11 does NOT have std::variant
#undef ABSL_OPTION_USE_STD_ANY
#define ABSL_OPTION_USE_STD_ANY 0
#undef ABSL_OPTION_USE_STD_OPTIONAL
#define ABSL_OPTION_USE_STD_OPTIONAL 0
#undef ABSL_OPTION_USE_STD_VARIANT
#define ABSL_OPTION_USE_STD_VARIANT 0

#ifdef __MINGW32__
#include <malloc.h>
#undef alloca
#endif
#include_next "rtc_base/string_utils.h"
#ifdef __MINGW32__
#undef alloca
#ifdef __GNUC__
#define alloca(x) __builtin_alloca((x))
#else
#define alloca _alloca
#endif
#endif

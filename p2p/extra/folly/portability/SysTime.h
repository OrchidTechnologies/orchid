#ifdef __MINGW32__
#include <folly/portability/Windows.h>
#define timezone orc_timezone
#define gettimeofday orc_gettimeofday
#endif
#include_next <folly/portability/SysTime.h>
#ifdef __MINGW32__
#undef timezone
#undef gettimeofday
#endif

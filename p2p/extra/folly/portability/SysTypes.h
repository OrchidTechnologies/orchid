#ifdef __MINGW32__
#include <sys/types.h>
#include <basetsd.h>
#define SSIZE_T int
#endif
#include_next <folly/portability/SysTypes.h>
#ifdef __MINGW32__
#undef SSIZE_T
#endif

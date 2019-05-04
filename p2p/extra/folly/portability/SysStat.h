#ifdef __MINGW32__
#include <sys/stat.h>
#else
#include_next <folly/portability/SysStat.h>
#endif

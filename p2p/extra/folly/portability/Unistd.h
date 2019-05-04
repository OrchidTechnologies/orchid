#ifdef __MINGW32__
#include <cstdint>
#include <sys/locking.h>
#include <folly/portability/SysTypes.h>
#undef X_OK
#define close orc_close
#endif
#include_next <folly/portability/Unistd.h>
#ifdef __MINGW32__
#undef X_OK
#define X_OK 1
#undef orc_close
#endif

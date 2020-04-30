// XXX: time.cc needs to check defined(V8_OS_POSIX) in a few places
#include <pthread_time.h>
#undef _POSIX_THREAD_CPUTIME

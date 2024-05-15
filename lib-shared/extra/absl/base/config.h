#include_next "absl/base/config.h"
#ifdef _WIN32
// XXX fix thread_local on Win32
#undef ABSL_HAVE_THREAD_LOCAL
#endif

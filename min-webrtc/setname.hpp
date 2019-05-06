#include "rtc_base/platform_thread_types.h"
#include <pthread.h>
#define __try if (true)
#define __except(x) if (false)
#define RaiseException(...) \
    pthread_setname_np(pthread_self(), name); \
    (void) threadname_info

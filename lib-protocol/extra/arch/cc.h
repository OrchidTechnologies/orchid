#define LWIP_DONT_PROVIDE_BYTEORDER_FUNCTIONS
#ifdef __ANDROID__
#define SOCKLEN_T_DEFINED
#endif
#include <sys/time.h>
#include <sys/types.h>
#ifdef __ANDROID__
#define fd_set lwip_set
#endif
#include_next "arch/cc.h"
#ifdef __ANDROID__
#undef fd_set
#endif

#include <sys/time.h>
#include <sys/types.h>
#ifndef __APPLE__
#define fd_set lwip_set
#endif
#include_next "arch/cc.h"
#ifndef __APPLE__
#undef lwip_set
#endif

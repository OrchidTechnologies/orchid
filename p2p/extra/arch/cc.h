#include <sys/time.h>
#include <sys/types.h>
#define fd_set lwip_set
#include_next "arch/cc.h"
#undef lwip_set

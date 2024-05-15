#include "lwip.hpp"
#include "log.hpp"

#include <lwip/opt.h>
#include <lwip/sockets.h>
#include <lwip/sys.h>

#ifndef TCP_NODELAY
#define TCP_NODELAY    0x01    /* don't delay send to coalesce packets */
#endif

/* commands for fnctl */
#ifndef F_GETFL
#define F_GETFL 3
#endif
#ifndef F_SETFL
#define F_SETFL 4
#endif

/* File status flags and file access modes for fnctl,
   these are bits in an int. */
#ifndef O_NONBLOCK
#define O_NONBLOCK  1 /* nonblocking I/O */
#endif

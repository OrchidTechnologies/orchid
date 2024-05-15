#ifndef __MINGW32__
#include <arpa/inet.h>
#include <netinet/tcp.h>
#endif

#define SIN_ZERO_LEN sizeof(((struct sockaddr_in *) NULL)->sin_zero)

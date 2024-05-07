#include <errno.h>
#include <fcntl.h>
#include <stdio.h>

#ifdef __APPLE__
#include <sys/filio.h>
typedef int msg_iovlen_t;
#else
typedef size_t msg_iovlen_t;
#endif

#ifdef __MINGW32__
#include <winsock2.h>
#include <ws2tcpip.h>

#include "lwip/netif.h"
#define IFNAMSIZ NETIF_NAMESIZE
struct ifreq {
  char ifr_name[IFNAMSIZ];
};

struct iovec {
  void  *iov_base;
  size_t iov_len;
};

struct msghdr {
  void         *msg_name;
  socklen_t     msg_namelen;
  struct iovec *msg_iov;
  msg_iovlen_t  msg_iovlen;
  void         *msg_control;
  socklen_t     msg_controllen;
  int           msg_flags;
};

#define F_GETFL 32
#define F_SETFL 33

#define IOV_MAX 0xFFFF
#define O_NONBLOCK 0x40000000

#define SHUT_RD 0
#define SHUT_WR 1
#define SHUT_RDWR 2

#define MSG_DONTWAIT 0x100000
#define MSG_TRUNC 0x200000

#else
#include <net/if.h>
#include <sys/errno.h>
#include <sys/socket.h>
#endif

#ifdef __linux__
#include <asm/ioctls.h>
#include <asm/socket.h>
#define TCP_KEEPALIVE 0xFF
#ifndef __ANDROID__
#include <bits/xopen_lim.h>
#endif
#else
#define IPPROTO_UDPLITE 136
#define MSG_MORE 0x400000
#define SO_BINDTODEVICE 0x100b
#define SO_NO_CHECK 0x100a
#endif

#define LWIP_SELECT_MAXNFDS FD_SETSIZE

#define inet_addr_from_ip4addr(target_inaddr, source_ipaddr) \
    ((target_inaddr)->s_addr = ip4_addr_get_u32(source_ipaddr))
#define inet_addr_to_ip4addr(target_ipaddr, source_inaddr) \
    (ip4_addr_set_u32(target_ipaddr, (source_inaddr)->s_addr))

#define LWIP_TCPIP_CORE_LOCKING    1

#define MEM_LIBC_MALLOC 1
#define MEMP_MEM_MALLOC 1
#define MEMP_NUM_NETCONN 32

#define LWIP_UDP 1

#define LWIP_TCP 1
#define TCP_WND 0xffff
#define LWIP_TCP_SACK_OUT 1
#define TCP_MSS 512
#define TCP_SND_BUF 0xffff
#define LWIP_TCP_TIMESTAMPS 1

#define LWIP_NETIF_API 1
#define LWIP_HAVE_LOOPIF 1
#define LWIP_NETIF_LOOPBACK 1

#define LWIP_SOCKET 1
#define LWIP_COMPAT_SOCKETS 0
#define LWIP_TCP_KEEPALIVE 0
#define LWIP_SOCKET_POLL 0

struct netif *hook_ip4_route_src(const void *src, const void *dest);
#define LWIP_HOOK_IP4_ROUTE_SRC hook_ip4_route_src

void sys_check_core_locking(void);
#define LWIP_ASSERT_CORE_LOCKED  sys_check_core_locking

#define TCP_KEEPIDLE_DEFAULT 12000UL
#define TCP_KEEPINTVL_DEFAULT 12000UL
#define TCP_KEEPCNT_DEFAULT 9

#define LWIP_DEBUG 1
#if 0
#define LWIP_DBG_TYPES_ON LWIP_DBG_ON
#define NETIF_DEBUG LWIP_DBG_ON
#define SOCKETS_DEBUG LWIP_DBG_ON
#define API_LIB_DEBUG LWIP_DBG_ON
#define IP_DEBUG LWIP_DBG_ON
#endif

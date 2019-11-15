#define LWIP_SOCKET 1
#define LWIP_COMPAT_SOCKETS 0
#define LWIP_NETIF_API 1
#define LWIP_TCP 1
#define LWIP_UDP 1
#define LWIP_HAVE_LOOPIF 1
#define LWIP_NETIF_LOOPBACK 1
struct netif *hook_ip4_route_src(const void *src, const void *dest);
#define LWIP_HOOK_IP4_ROUTE_SRC hook_ip4_route_src
#define LWIP_SOCKET_POLL 0
#define MEM_LIBC_MALLOC 1
#define MEMP_MEM_MALLOC 1
#define MEMP_NUM_NETCONN 32
#define LWIP_TCPIP_CORE_LOCKING    1
void sys_check_core_locking(void);
#define LWIP_ASSERT_CORE_LOCKED()  sys_check_core_locking()

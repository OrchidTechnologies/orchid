#include <stdint.h>
#include <stdbool.h>

#include <netinet/ip.h>
#include <netinet/ip6.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>

#include <ifaddrs.h>


#define alloc(type) calloc(1, sizeof(type))
#define alloc_with_extra(type, extra) calloc(1, sizeof(type) + extra)
#define lenof(x) (sizeof(x)/sizeof(x[0]))
#define memdup(m, len) memcpy(malloc(len), m, len)
#define memeq(a, b, len) (memcmp(a, b, len) == 0)
#define PACKED __attribute__((__packed__))
#define in_addr_t_toa(x) inet_ntoa((in_addr){.s_addr = x})
#define INET_ADDR(a,b,c,d) (a | (b<<8) | (c<<16) | (d<<24))

#define TERMINATE_HOST INET_ADDR(10,7,0,3)
#define TERMINATE_PORT 4612


typedef in_port_t port_t;
typedef struct ip ip;
typedef struct udphdr udphdr;
typedef struct tcphdr tcphdr;
typedef struct in_addr in_addr;
typedef struct in6_addr in6_addr;
typedef struct sockaddr sockaddr;
typedef struct sockaddr_storage sockaddr_storage;
typedef struct sockaddr_in sockaddr_in;
typedef struct sockaddr_in6 sockaddr_in6;
typedef struct ifaddrs ifaddrs;

sa_family_t address_family(const ip *p);

void start_listener(void);
bool on_tunnel_packet(const uint8_t *packet, size_t length);

// defined by the caller
void write_tunnel_packet(const uint8_t *packet, size_t length);

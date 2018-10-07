#include <assert.h>
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <strings.h>
#include <fcntl.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <netdb.h>
#include <Block.h>
#include <pthread.h>

#include "orchid.h"
#include "tun_client.h"
#include "khash.h"


#ifdef ANDROID
#include <android/log.h>
#define log(...) __android_log_print(ANDROID_LOG_VERBOSE, "orchid", __VA_ARGS__)
#elif defined __APPLE__
#import <os/log.h>
#define log(...) os_log(OS_LOG_DEFAULT, __VA_ARGS__)
#else
#define log(...) printf(__VA_ARGS__)
#endif

typedef struct {
    uint32_t length;
    uint32_t alloc;
    ipv4_mapping mappings[];
} ipv4_mapping_array;

#define KHASH_MAP_INIT_UINT16(name, khval_t)                                \
KHASH_INIT(name, uint16_t, khval_t, 1, kh_int_hash_func, kh_int_hash_equal)

typedef ipv4_mapping_array* ipv4_mapping_array_p;
KHASH_MAP_INIT_UINT16(portmapping_v4, ipv4_mapping_array_p);
typedef khash_t(portmapping_v4) portmap_v4;

portmap_v4 *portmap4;


uint16_t checksum(const uint8_t *b, uint16_t len, uint64_t sum)
{
    const uint32_t *p = (const uint32_t *)b;
    while (len >= sizeof(*p)) {
        sum += *p++;
        len -= sizeof(*p);
    }
    b = (const uint8_t *)p;
    if (len & 2) {
        sum += *(uint16_t *)b;
        b += sizeof(uint16_t);
    }
    if (len & 1) {
        sum += *(uint8_t *)b;
    }
    while (sum >> 16) {
        sum = (sum & 0xFFFF) + (sum >> 16);
    }
    return (uint16_t)((~sum) & 0xFFFF);
}

uint16_t ip_checksum(const ip *p)
{
    return checksum((const uint8_t *)p, sizeof(ip), 0);
}

uint32_t ip_addr_checksum(const ip *p)
{
    register uint32_t sum = 0;
    sum += (p->ip_src.s_addr>>16) & 0xFFFF;
    sum += (p->ip_src.s_addr) & 0xFFFF;
    sum += (p->ip_dst.s_addr>>16) & 0xFFFF;
    sum += (p->ip_dst.s_addr) & 0xFFFF;
    return sum;
}

uint16_t udp_checksum(const ip *p)
{
    const udphdr *udp = (const udphdr*)((const uint8_t*)p + sizeof(ip));
    assert(udp->uh_sum == 0);
    register uint32_t sum = ip_addr_checksum(p);
    sum += htons(IPPROTO_UDP);
    sum += udp->uh_ulen;
    sum = checksum((const uint8_t *)udp, ntohs(udp->uh_ulen), sum);
    return ((uint16_t)sum == 0x0000) ? 0xFFFF : (uint16_t)sum;
}

uint16_t tcp_checksum(const ip *p)
{
    const tcphdr *tcp = (const tcphdr*)((const uint8_t*)p + sizeof(ip));
    uint16_t tcp_len = ntohs(p->ip_len) - sizeof(ip);
    assert(tcp->th_sum == 0);
    register uint32_t sum = ip_addr_checksum(p);
    sum += htons(IPPROTO_TCP);
    sum += htons(tcp_len);
    sum = checksum((const uint8_t *)tcp, tcp_len, sum);
    return ((uint16_t)sum == 0x0000) ? 0xFFFF : (uint16_t)sum;
}

uint16_t fixup16_cksum(uint16_t cksum, uint16_t odatum, uint16_t ndatum)
{
    /*
     * RFC 1624:
     *    HC' = ~(~HC + ~m + m')
     *
     * Note: 1's complement sum is endian-independent (RFC 1071, page 2).
     */
    uint32_t sum = ~cksum & 0xffff;
    sum += (~odatum & 0xffff) + ndatum;
    sum = (sum >> 16) + (sum & 0xffff);
    sum += (sum >> 16);
    return ~sum & 0xffff;
}

uint16_t fixup32_cksum(uint16_t cksum, uint32_t odatum, uint32_t ndatum)
{
    /*
     * Checksum 32-bit datum as as two 16-bit.  Note, the first
     * 32->16 bit reduction is not necessary.
     */
    uint32_t sum = ~cksum & 0xffff;
    sum += (~odatum & 0xffff) + (ndatum & 0xffff);
    sum += (~odatum >> 16) + (ndatum >> 16);
    sum = (sum >> 16) + (sum & 0xffff);
    sum += (sum >> 16);
    return ~sum & 0xffff;
}

void change_tcp_port(tcphdr *tcp, port_t *oldv, port_t newv)
{
    port_t oldvv = *oldv;
    *oldv = newv;
    tcp->th_sum = fixup16_cksum(tcp->th_sum, oldvv, newv);
}

void change_tcp_ip_addr(ip* p, in_addr_t *oldv, in_addr_t newv)
{
    tcphdr *tcp = (tcphdr*)((uint8_t*)p + sizeof(ip));
    in_addr_t oldvv = *oldv;
    *oldv = newv;
    p->ip_sum = fixup32_cksum(p->ip_sum, oldvv, newv);
    tcp->th_sum = fixup32_cksum(tcp->th_sum, oldvv, newv);
}

sa_family_t address_family(const ip *p)
{
    switch (p->ip_v) {
    case 4: return AF_INET;
    case 6: return AF_INET6;
    }
    return AF_UNSPEC;
}

const char* address_to_string(const sockaddr_storage *ss)
{
    static char addr[NI_MAXHOST];
    socklen_t ss_len = 0;
    switch (ss->ss_family) {
    case AF_INET: ss_len = sizeof(sockaddr_in); break;
    case AF_INET6: ss_len = sizeof(sockaddr_in6); break;
    }
    int e = getnameinfo((const sockaddr*)ss, ss_len, addr, sizeof(addr), NULL, 0, NI_NUMERICHOST);
    if (!e) {
        log("getnameinfo failed %d %s\n", e, gai_strerror(e));
        return NULL;
    }
    return addr;
}

#ifndef TH_ECE
#define TH_ECE 0x40
#endif
#ifndef TH_CWR
#define TH_CWR 0x80
#endif

const char* tcp_flags(unsigned char flags)
{
    static char buf[33];
    buf[0] = '\0';
    char *p = NULL;
#define ADD_FLAG(f) \
    if (flags & TH_ ## f) { \
        if (p) strcat(buf, "|"); \
        p = strcat(buf, #f); \
    }
    ADD_FLAG(FIN);
    ADD_FLAG(SYN);
    ADD_FLAG(RST);
    ADD_FLAG(PUSH);
    ADD_FLAG(ACK);
    ADD_FLAG(URG);
    ADD_FLAG(ECE);
    ADD_FLAG(CWR);
    return buf;
}

void reuseport(int s)
{
    const int option = 1;
    setsockopt(s, SOL_SOCKET, SO_REUSEPORT, &option, sizeof(option));
}

void nonblock(int s)
{
    fcntl(s, F_SETFL, fcntl(s, F_GETFL) | O_NONBLOCK);
}

typedef void (^thread_body)(void);
void thread(thread_body tb);

void* call_thread_body(void *userdata)
{
    thread_body tb = (thread_body)userdata;
    tb();
    Block_release(tb);
    return NULL;
}

void start_thread(thread_body tb)
{
    pthread_t t;
    tb = Block_copy(tb);
    pthread_create(&t, NULL, call_thread_body, tb);
}

void listener_thread(int fd)
{
    for (;;) {
        sockaddr_storage addr;
        socklen_t addr_len = sizeof(addr);
        int c = accept(fd, (sockaddr*)&addr, &addr_len);
        if (c == -1) {
            switch (errno) {
            case EAGAIN: return;
            case ECONNABORTED: continue;
            case EMFILE:
                // XXX: TODO: close the most idle sockets
                return;
            }
            log("TCP accept error %d %s", errno, strerror(errno));
            return;
        }
        log("accept socket: %d", c);

        assert(addr.ss_family == AF_INET); // TODO: IPv6
        sockaddr_in *sin = (sockaddr_in*)&addr;
        port_t src_port = ntohs(sin->sin_port);
        uint32_t index = ntohl(sin->sin_addr.s_addr - TERMINATE_HOST);

        khint_t k = kh_get(portmapping_v4, portmap4, src_port);
        ipv4_mapping *m = NULL;
        if (k != kh_end(portmap4)) {
            ipv4_mapping_array_p mappings = kh_val(portmap4, k);
            if (index < mappings->length) {
                m = &mappings->mappings[index];
            }
        }
        if (!m) {
            log("unknown TCP session %s:%d\n", inet_ntoa(sin->sin_addr), src_port);
            close(c);
            continue;
        }
        log("accepted %d -> %s:%d", m->src_port, in_addr_t_toa(m->dst_ip), m->dst_port);
        tun_client_tcp_accepted(m, c);
    }
}

void start_listener(void)
{
    int listen_fd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (listen_fd == -1) {
        if (errno == EMFILE) {
            assert(false);
        }
    }
    signal(SIGPIPE, SIG_IGN);

    sockaddr_in listen_sin = {
        .sin_family = AF_INET,
        .sin_port = htons(TERMINATE_PORT),
        .sin_addr.s_addr = TERMINATE_HOST,
    };
    reuseport(listen_fd);

#ifdef __APPLE__
    ifaddrs *interfaces = NULL;
    if (!getifaddrs(&interfaces)) {
        for (ifaddrs *i = interfaces; i; i = i->ifa_next) {
            if (i->ifa_addr->sa_family == AF_INET &&
                ((sockaddr_in*)i->ifa_addr)->sin_addr.s_addr == listen_sin.sin_addr.s_addr) {
                int index = if_nametoindex(i->ifa_name);
                setsockopt(listen_fd, IPPROTO_IP, IP_BOUND_IF, &index, sizeof(index));
                //log("bound to %s %d", i->ifa_name, r);
                break;
            }
        }
        freeifaddrs(interfaces);
    }
#endif

#ifdef __LINUX__
    setsockopt(fd, SOL_SOCKET, SO_MARK, &fwmark, sizeof(fwmark));
#endif

    int r = bind(listen_fd, (const sockaddr*)&listen_sin, sizeof(listen_sin));
    if (r < 0) {
        log("TCP bind error %d %d %s", r, errno, strerror(errno));
        close(listen_fd);
        return;
    }
    r = listen(listen_fd, 128);
    log("TCP listen %d", r);

    nonblock(listen_fd);

    start_thread(^{ listener_thread(listen_fd); });
}

void mapping_close(ipv4_mapping *m)
{
    khint_t k = kh_get(portmapping_v4, portmap4, m->src_port);
    assert(k != kh_end(portmap4));
    ipv4_mapping_array *mappings = kh_val(portmap4, k);
    for (uint32_t index = 0; index < mappings->length; index++) {
        ipv4_mapping *m2 = &mappings->mappings[index];
        if (m != m2) {
            continue;
        }
        if (mappings->length == 1) {
            kh_del(portmapping_v4, portmap4, k);
            free(mappings);
        } else if (index == mappings->length - 1) {
            mappings->length--;
        } else {
            m->dst_ip = 0;
            m->dst_port = 0;
        }
        return;
    }
    assert(false);
}

bool on_udp_packet(ip *p, size_t length)
{
    return tun_client_udp_packet(p, length);
}

bool on_tcp_packet(ip *p, size_t length)
{
    tcphdr *tcp = (tcphdr*)((uint8_t*)p + sizeof(ip));

    /*
    log("TCP packet %d -> %{public}s:%d flags:0x%08x %{public}s",
        ntohs(tcp->th_sport), inet_ntoa(p->ip_dst), ntohs(tcp->th_dport),
        tcp->th_flags, tcp_flags(tcp->th_flags));
    */

    static bool initialized = false;
    if (!initialized) {
        initialized = true;
        portmap4 = kh_init(portmapping_v4);
    }

    if (p->ip_src.s_addr == TERMINATE_HOST && tcp->th_sport == htons(TERMINATE_PORT)) {
        port_t dst_port = ntohs(tcp->th_dport);

        khint_t k = kh_get(portmapping_v4, portmap4, dst_port);
        ipv4_mapping *m = NULL;
        if (k != kh_end(portmap4)) {
            ipv4_mapping_array_p mappings = kh_val(portmap4, k);
            uint32_t index = ntohl(p->ip_dst.s_addr - TERMINATE_HOST);
            if (index < mappings->length) {
                m = &mappings->mappings[index];
            }
        }
        if (!m) {
            log("unknown TCP session %s:%d\n", inet_ntoa(p->ip_dst), dst_port);
            return false;
        }

        change_tcp_ip_addr(p, &p->ip_src.s_addr, m->dst_ip);
        change_tcp_port(tcp, &tcp->th_sport, htons(m->dst_port));
        change_tcp_ip_addr(p, &p->ip_dst.s_addr, TERMINATE_HOST);
        change_tcp_port(tcp, &tcp->th_dport, htons(m->src_port));
    } else {
        port_t src_port = ntohs(tcp->th_sport);
        uint32_t index = 0;

        ipv4_mapping_array_p mappings = NULL;
        ipv4_mapping *m = NULL;

        if (tcp->th_flags & TH_SYN) {
            int absent;
            khint_t k = kh_put(portmapping_v4, portmap4, src_port, &absent);
            if (!absent) {
                mappings = kh_val(portmap4, k);
                for (index = 0; index < mappings->length; index++) {
                    ipv4_mapping *s = &mappings->mappings[index];
                    if (s->dst_ip == p->ip_dst.s_addr && s->dst_port == ntohs(tcp->th_dport)) {
                        m = s;
                        break;
                    }
                }
            }
            if (!m) {
                if (!mappings) {
                    mappings = alloc_with_extra(ipv4_mapping_array, sizeof(ipv4_mapping));
                    mappings->length = 1;
                    mappings->alloc = 1;
                    assert(index == 0);
                    m = &mappings->mappings[0];
                    kh_val(portmap4, k) = mappings;
                } else {
                    assert(mappings->length <= mappings->alloc);
                    for (index = 0; index < mappings->length; index++) {
                        ipv4_mapping *s = &mappings->mappings[index];
                        if (s->dst_ip == 0 && s->dst_port == 0) {
                            m = s;
                            break;
                        }
                    }
                    if (!m) {
                        if (mappings->length == mappings->alloc) {
                            mappings->alloc *= 2;
                            mappings = realloc(mappings, sizeof(ipv4_mapping_array) + mappings->alloc * sizeof(ipv4_mapping));
                            kh_val(portmap4, k) = mappings;
                        }
                        mappings->length++;
                        assert(index == mappings->length - 1);
                        m = &mappings->mappings[mappings->length - 1];
                        bzero(m, sizeof(ipv4_mapping));
                    }
                }
                m->src_port = src_port;
                m->dst_port = ntohs(tcp->th_dport);
                m->dst_ip = p->ip_dst.s_addr;

                assert(index < mappings->length);
                assert(m == &mappings->mappings[index]);

                change_tcp_ip_addr(p, &p->ip_src.s_addr, TERMINATE_HOST + htonl(index));
                change_tcp_ip_addr(p, &p->ip_dst.s_addr, TERMINATE_HOST);
                change_tcp_port(tcp, &tcp->th_dport, htons(TERMINATE_PORT));

                // HMM: copies, but some callers (NSData*) can be refcounted
                uint8_t *pending_packet = memdup(p, length);

                m->connecting = true;
                tun_client_tcp_connect(m, ^(int error) {
                    m->connecting = false;
                    if (error) {
                        // XXX: craft RST
                        mapping_close(m);
                    } else {
                        write_tunnel_packet(pending_packet, length);
                    }
                    free(pending_packet);
                });
                return true;
            }

            if (m->connecting) {
                return true;
            }

            if (tcp->th_flags & TH_RST) {
                mapping_close(m);
            }
        } else {
            khint_t k = kh_get(portmapping_v4, portmap4, src_port);
            if (k != kh_end(portmap4)) {
                mappings = kh_val(portmap4, k);
                for (index = 0; index < mappings->length; index++) {
                    ipv4_mapping *s = &mappings->mappings[index];
                    if (s->dst_ip == p->ip_dst.s_addr && s->dst_port == ntohs(tcp->th_dport)) {
                        m = s;
                        break;
                    }
                }
            }
            if (!m) {
                // XXX: craft RST?
            }
        }

        change_tcp_ip_addr(p, &p->ip_src.s_addr, TERMINATE_HOST + htonl(index));
        change_tcp_ip_addr(p, &p->ip_dst.s_addr, TERMINATE_HOST);
        change_tcp_port(tcp, &tcp->th_dport, htons(TERMINATE_PORT));
    }

    /*
    log("TCP return %d -> %{public}s:%d flags:0x%08x %{public}s",
        ntohs(tcp->th_sport), inet_ntoa(p->ip_dst), ntohs(tcp->th_dport),
        tcp->th_flags, tcp_flags(tcp->th_flags));
    */
    return false;
}

bool on_tunnel_packet(const uint8_t *packet, size_t length)
{
    if (length < sizeof(ip)) {
        return false;
    }
    ip *p = (ip*)packet;
    switch (address_family(p)) {
    case AF_INET:
        switch (p->ip_p) {
        case IPPROTO_UDP: return on_udp_packet(p, length);
        case IPPROTO_TCP: return on_tcp_packet(p, length);
        }
        break;
    case AF_INET6:
        // TODO: IPv6
        break;
    }

    return false;
}

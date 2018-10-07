//
//  tun_client.c
//  Orchid macOS
//
//  Created by Gregory Hazel on 7/31/18.
//  Copyright © 2018 Example. All rights reserved.
//

#include <Block.h>

#include "tun_client.h"
#include "orchid.h"

// should call connect() and on success/failure call cb(errno)
void tun_client_tcp_connect(ipv4_mapping *m, connection_complete_cb cb)
{
    cb(0);
}

// fd was accepted for the mapping. when finished with fd, close(fd) and call mapping_close(m)
void tun_client_tcp_accepted(ipv4_mapping *m, int fd)
{
}

// return false if the packet should be re-inserted (possibly modified), true if it was processed.
bool tun_client_udp_packet(ip *p, size_t length)
{
    //udphdr *udp = (udphdr*)((uint8_t*)p + sizeof(ip));
    return true;
}

//
//  tun_client.h
//  Orchid macOS
//
//  Created by Gregory Hazel on 7/31/18.
//  Copyright © 2018 Example. All rights reserved.
//

#ifndef tun_client_h
#define tun_client_h

#include "orchid.h"
#include <stdio.h>

typedef void (^connection_complete_cb)(int error);
void tun_client_tcp_connect(ipv4_mapping *m, connection_complete_cb cb);
void tun_client_tcp_accepted(ipv4_mapping *m, int fd);
bool tun_client_udp_packet(ip *p, size_t length);

#endif /* tun_client_h */

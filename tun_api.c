//
//  tun_api.c
//  Orchid macOS
//
//  Created by Gregory Hazel on 7/31/18.
//  Copyright © 2018 Example. All rights reserved.
//

#include <Block.h>

#include "tun_api.h"
#include "orchid.h"

void tun_api_connect(sockaddr_storage *ss, connection_complete_cb cb)
{
    // should call connect() and on success/failure call cb()
    cb(0);
}

/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2019  The Orchid Authors
*/

/* GNU Affero General Public License, Version 3 {{{ */
/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.

 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */


#include <cstdio>
#include <iostream>
#include <future>

#include "crypto.hpp"
#include "jsonrpc.hpp"

#include "test_mpay.h"


namespace orc {

    void test()
    {
        //return Wait([&]() -> task<int> { co_await Schedule(); Endpoint endpoint({"http", "localhost", "8545", "/"}); /* code here */ }() );
    }


    task<int> test_mpay_()
    {
    	co_await Schedule();

        Endpoint endpoint({"http", "localhost", "8545", "/"});

        //endpoint("blah", {"booh"});
        
        co_await endpoint("web3_clientVersion", {});
        //co_await endpoint("eth_getStorageAt", {"0x295a70b2de5e3953354a6a8344e616ed314d7251", "0x6661e9d6d8b923d5bbaab1b96e1dd51ff6ea2a93520fdc9eb75d059238b8c5e9", "0x65a8db"});

        //std::string data = "{\"to\": \"0x9561C133DD8580860B6b7E504bC5Aa500f0f06a7\", \"data\": \"0x38b51ce10000000000000000000000000000000000000000000000000000000000000003\"}";
        //std::cout << data << std::endl;

        auto block(co_await endpoint.Block());

        std::cerr << co_await endpoint("eth_getProof", {
            uint256_t("0x7F0d15C7FAae65896648C8273B6d7E43f58Fa842"),
            {uint256_t("0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421")},
            block,
        }) << std::endl;

        Selector look("look(address)");
        std::cerr << co_await endpoint.Call(block, uint256_t("0xd87e0ee1a59841de2ac78c17209db97e27651985"), look, Number<uint256_t>("0x2b1ce95573ec1b927a90cb488db113b40eeb064a")) << std::endl;

        // 0xc6cecaa40000000000000000000000000000000000000000000000000000000000000003
        // 0x38b51ce1000000000000000000000000142E2fDd2188Bb0005adD957D100cDCc1ad7F55A
        // 0xc6cecaa4000000000000000000000000DE621d026DE07c9a6a25EB341776924455E85422
        // 0xf8f45f0f000000000000000000000000142E2fDd2188Bb0005adD957D100cDCc1ad7F55A

        co_return 0;
    }

    void test_mpay()
    {
        std::cout << "testing micropay!" << std::endl;
        auto t = test_mpay_();
        sync_wait(t);        
        std::cout << "test_mpay(): done" << std::endl;
    }


}



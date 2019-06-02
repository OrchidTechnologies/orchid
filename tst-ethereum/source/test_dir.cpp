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
#include <future>
#include <string>

#include "crypto.hpp"
#include "jsonrpc.hpp"
#include "buffer.hpp"

#include "tests.h"


typedef uint8_t byte;

namespace orc
{

	using boost::multiprecision::cpp_int_backend;
	using boost::multiprecision::unsigned_magnitude;
	using boost::multiprecision::unchecked;

	typedef boost::multiprecision::number<cpp_int_backend<160, 160, unsigned_magnitude, unchecked, void>> uint160_t;

	using std::string;


    inline task<string> deploy(Endpoint& endpoint, const string& address, const string& bin)
    {
   		assert(bin.size() > 0);
        auto trans_hash = co_await endpoint("eth_sendTransaction", {Map{{"from",uint256_t(address)},{"data",bin}, {"gas","4712388"}, {"gasPrice","100000000000"}}} );
        // todo: this currently works on EthereumJS TestRPC v6.0.3, but on a live network you'd need to wait for the transaction to be mined
   		auto result     = co_await endpoint("eth_getTransactionReceipt", {trans_hash.asString()} );
   		string contractAddress = result["contractAddress"].asString();
        co_return contractAddress;
    }

    task<int> test_directory()
    {
        Endpoint endpoint({"http", "localhost", "8545", "/"});

        co_await endpoint("web3_clientVersion", {});


	    // this assumes testrpc started as:
	    // testrpc -d --network-id 10
	    // to get deterministic test accounts (`testAcc` is the first account)
	    // --network-id 10 is needed to workaround
	    // https://github.com/ethereum/web3.js/issues/932 (wtf)

        printf("[%d] Example start\n", __LINE__);


        const string orchid_address = "0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1";
        const string orchid_privkey = "4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d";
        
        
   		string test_contract_bin  	= "6060604052341561000c57fe5b5b6101598061001c6000396000f30060606040526000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff168063cfae32171461003b575bfe5b341561004357fe5b61004b6100d4565b604051808060200182810382528381815181526020019150805190602001908083836000831461009a575b80518252602083111561009a57602082019150602081019050602083039250610076565b505050905090810190601f1680156100c65780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6100dc610119565b604060405190810160405280600381526020017f486921000000000000000000000000000000000000000000000000000000000081525090505b90565b6020604051908101604052806000815250905600a165627a7a72305820ed71008611bb64338581c5758f96e31ac3b0c57e1d8de028b72f0b8173ff93a10029";
   		string test_contract_addr 	= co_await deploy(endpoint, orchid_address, "0x" + test_contract_bin);
        string ERC20_addr 			= co_await deploy(endpoint, orchid_address, "0x" + file_to_string("tok-ethereum/build/ERC20.bin"));
        string OrchidToken_addr 	= co_await deploy(endpoint, orchid_address, "0x" + file_to_string("tok-ethereum/build/OrchidToken.bin"));
        string directory_addr	 	= co_await deploy(endpoint, orchid_address, "0x" + file_to_string("dir-ethereum/build/OrchidDirectory.bin"));
		
		printf("[%d] OrchidToken_addr(%s,%s) \n",   __LINE__, OrchidToken_addr.c_str(), OrchidToken_addr.c_str());
   		printf("[%d] directory_addr(%s,%s) \n",     __LINE__, directory_addr.c_str(),   directory_addr.c_str());
 
        
   		std::cout << "Done." << std::endl;
   		co_return 0;
        
    }



    int test_dir()
    {
        std::cout << "test_dir()" << std::endl;
        auto t = test_directory();
        sync_wait(t);        
        std::cout << "test_dir(): done" << std::endl;
        return 0;
    }

}


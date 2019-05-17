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
#include <fstream>
#include <future>
#include <string>

#include "crypto.hpp"
#include "jsonrpc.hpp"

#include "test_mpay.h"


namespace orc {

	using std::string;


	std::string file_to_string(std::string fn)
	{
		std::ifstream myfile;
		myfile.open(fn.c_str());
		if (myfile.is_open()) {
			std::stringstream buffer;
			buffer << myfile.rdbuf();
			return buffer.str();
		} else {
			printf("failed to open infile %s \n", fn.c_str());
			return "";
		}
		myfile.close();
		return "";
	}

	bool string_to_file(std::string x, std::string fn) {
		bool bresult;
		std::ofstream myfile;
		myfile.open(fn);
		if (myfile.is_open()) {
			myfile << x;
			bresult = true;
		} else {
			printf("failed to open outfile %s \n", fn.c_str());
			bresult = false;
		}
		myfile.close();
		return bresult;
	}

    void test()
    {
        //return Wait([&]() -> task<int> { co_await Schedule(); Endpoint endpoint({"http", "localhost", "8545", "/"}); /* code here */ }() );
    }

    inline task<string> deploy(Endpoint& endpoint, const string& address, const string& bin)
    {
   		assert(bin.size() > 0);
        auto trans_hash = co_await endpoint("eth_sendTransaction", {Map{{"from",uint256_t(address)},{"data",bin}, {"gas","4712388"}, {"gasPrice","100000000000"}}} );
        // todo: this currently works on EthereumJS TestRPC v6.0.3, but on a live network you'd need to wait for the transaction to be mined
   		auto result     = co_await endpoint("eth_getTransactionReceipt", {trans_hash.asString()} );
   		string contractAddress = result["contractAddress"].asString();
        co_return contractAddress;
    }

    task<int> test_lottery()
    {
        Endpoint endpoint({"http", "localhost", "8545", "/"});

        co_await endpoint("web3_clientVersion", {});


	    // this assumes testrpc started as:
	    // testrpc -d --network-id 10
	    // to get deterministic test accounts (`testAcc` is the first account)
	    // --network-id 10 is needed to workaround
	    // https://github.com/ethereum/web3.js/issues/932 (wtf)

        printf("[%d] Example start\n", __LINE__);


        // this is the account which sets up the orchid contracts
        // taken from testrpc
        const string orchid_address = "0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1";
        const string orchid_privkey = "4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d";

        const string server_address = "0xffcf8fdee72ac11b5c542428b35eef5769c409f0";
        const string server_privkey = "6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1";

   		const string client_address = "0x22d491bde2303f2f43325b2108d26f1eaba1e32b";
   		const string client_privkey = "6370fd033278c143179d81c5526140625662b8daa446c22ee2d73db3707e620c";


   		auto is_syncing = co_await endpoint("eth_syncing", {});

   		std::cout << "result: \n" << is_syncing << std::endl;

   		if (is_syncing != false) {
   			std::cout << "Host unavailable/not working" << std::endl;
   			co_return 3;
   		}


   		string test_contract_bin  	= "6060604052341561000c57fe5b5b6101598061001c6000396000f30060606040526000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff168063cfae32171461003b575bfe5b341561004357fe5b61004b6100d4565b604051808060200182810382528381815181526020019150805190602001908083836000831461009a575b80518252602083111561009a57602082019150602081019050602083039250610076565b505050905090810190601f1680156100c65780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6100dc610119565b604060405190810160405280600381526020017f486921000000000000000000000000000000000000000000000000000000000081525090505b90565b6020604051908101604052806000815250905600a165627a7a72305820ed71008611bb64338581c5758f96e31ac3b0c57e1d8de028b72f0b8173ff93a10029";
        string test_contract_addr 	= co_await deploy(endpoint, orchid_address, test_contract_bin);

        string ERC20_addr 			= co_await deploy(endpoint, orchid_address, file_to_string("tok-ethereum/build/ERC20.bin"));

        string OrchidToken_addr 	= co_await deploy(endpoint, orchid_address, file_to_string("tok-ethereum/build/OrchidToken.bin"));

   		{
			auto block(co_await endpoint.Block());
			auto OrchidToken_addr_rv_	= co_await endpoint.eth_call(block, uint256_t(OrchidToken_addr), Selector("get_address(address)"), Number<uint256_t>("0x2b1ce95573ec1b927a90cb488db113b40eeb064a") );
			string OrchidToken_addr_rv 	= OrchidToken_addr_rv_.asString();
	   		std::cout << "OrchidToken_addr: " << OrchidToken_addr << "  " << OrchidToken_addr_rv << std::endl;
   		}


   		/*
        string lottery_addr		 	= co_await deploy(endpoint, orchid_address, file_to_string("lot-ethereum/build/OrchidLottery.bin"));
   		std::cout << "lottery_addr: \n" << lottery_addr << std::endl;

        //lotteryAddr_rv = await c.lottery.methods.get_address().call();

   		auto lottery_addr_rv_		= co_await endpoint.eth_call(uint256_t(lottery_addr), Selector("get_address(address)"), Number<uint256_t>("0x2b1ce95573ec1b927a90cb488db113b40eeb064a") );
   		string lottery_addr_rv  	= lottery_addr_rv_.asString();
   		//string OrchidToken_addr_rv 	= ( co_await endpoint.eth_call(uint256_t(OrchidToken_addr), Selector("get_address()"))).asString();
   		*/

        co_return 0;
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
        std::cout << "test_mpay()" << std::endl;
        auto t = test_lottery();
        sync_wait(t);        
        std::cout << "test_mpay(): done" << std::endl;
    }


}



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
#include <map>

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
	using std::vector;
	using std::map;


    inline task<string> deploy(Endpoint& endpoint, const string& address, const string& bin)
    {
        printf("[%d] deploy [%i] \n", __LINE__, int(bin.size()) );
   		assert(bin.size() > 2);
        auto trans_hash = co_await endpoint("eth_sendTransaction", {Map{{"from",uint256_t(address)},{"data",bin}, {"gas","4712388"}, {"gasPrice","100000000000"}}} );
        // todo: this currently works on EthereumJS TestRPC v6.0.3, but on a live network you'd need to wait for the transaction to be mined
   		auto result     = co_await endpoint("eth_getTransactionReceipt", {trans_hash.asString()} );
   		string contractAddress = result["contractAddress"].asString();
        co_return contractAddress;
    }
    
    //const uint128_t one_eth = 1000000000000000000;

    task<int> fund_medallion(Endpoint& endpoint, Address orchid_address, Address OrchidToken_addr, Address directory_addr, Address server_addr, uint128_t ntokens, Address dst_addr = 0)
    {
        if (dst_addr == 0) dst_addr = server_addr;
        
   		auto block = co_await endpoint.Latest();

   		// send some tokens to the node
	    printf("[%d] transfer: ", __LINE__);  std::cout << std::dec << ntokens  << std::endl;
   		static Selector<uint256_t, Address, uint256_t> transfer("transfer");
   		co_await transfer.Send(endpoint, Address(orchid_address), Address(OrchidToken_addr), Address(server_addr), uint256_t(ntokens) );
   		block = co_await endpoint.Latest();

        Selector<uint256_t,Address> balanceOf("balanceOf");
        auto balance = co_await balanceOf.Call(endpoint, block, Address(OrchidToken_addr), Address(server_addr) );
        printf("[%d] server_balance[]: ", __LINE__); std::cout << std::dec << balance  << std::endl;

   		// approve transfer to the directory contract
	    printf("[%d] approve \n", __LINE__);
   		static Selector<uint256_t, Address, uint256_t> approve("approve");
   		co_await approve.Send(endpoint, Address(server_addr), Address(OrchidToken_addr), Address(directory_addr), uint256_t(ntokens) );
   		block = co_await endpoint.Latest();

	    printf("[%d] push \n", __LINE__);
   		static Selector<uint256_t, Address,uint128_t> push_f("push", uint128_t(300000));
   		co_await push_f.Send(endpoint, Address(server_addr), Address(directory_addr), Address(dst_addr), uint128_t(ntokens) );
   		block = co_await endpoint.Latest();

        Selector<uint256_t> have_f("have");
        auto total = co_await have_f.Call(endpoint, block, Address(directory_addr) );
        printf("[%d] total: ", __LINE__); std::cout << std::dec << total << std::endl;

        Selector<uint256_t, Address> get_amount_f("get_amount");
        auto amount = co_await get_amount_f.Call(endpoint, Address(server_addr), block, Address(directory_addr), Address(dst_addr) );
        printf("[%d] amount: ", __LINE__); std::cout << std::dec << amount << std::endl;
        
        co_return 1;
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


        const string orchid_address = "0x1df62f291b2e969fb0849d99d9ce41e2f137006e";
        const string orchid_privkey = "0xb0057716d5917badaf911b193b12b910811c1497b5bada8d7711f758981c3773";
        
        const int NumNodes = 16;
        //vector<uint128_t>         node_ntokens;
        vector<Address>             node_address;
        map<uint256_t,uint128_t>    node_ntokens;


        for (int i(0); i < NumNodes; i++)
        {
            char buffer[256];
            sprintf(buffer, "f8a8%i", i*3229 + 319);
            auto hvalue     = Hash(std::string(buffer));
		    auto [unused, addr] = Take<Brick<12>, Brick<20>>(Tie(hvalue));
	        Address raddr(addr.num<uint160_t>());
	        uint128_t ntokens = (rand()%16)*(rand()%16)+1;
	        
	        node_address.push_back(raddr);
	        node_ntokens[uint256_t(raddr)] = ntokens;
	        //node_ntokens.push_back(ntokens);
	    }

        
        //uint128_t node_ntokens[] = {100, 10, 37, 3, 1};
        //for (int i(0); i < NumNodes; i++) { node_ntokens[i] *= one_eth; }
        
        const int NumAccounts = 4;
        string server_address[NumAccounts];
        string server_privkey[NumAccounts];

        server_address[0]  = "0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1";
        server_address[1]  = "0xffcf8fdee72ac11b5c542428b35eef5769c409f0";
        server_address[2]  = "0x22d491bde2303f2f43325b2108d26f1eaba1e32b";
        server_address[3]  = "0xe11ba2b4d45eaed5996cd0823791e0c93114882d";

        server_privkey[0]  = "0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d";
        server_privkey[1]  = "0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1";
        server_privkey[2]  = "0x6370fd033278c143179d81c5526140625662b8daa446c22ee2d73db3707e620c";
        server_privkey[3]  = "0x646f1ce2fdad0e6deeeb5c7e8e5543bdde65e86029e2fd9fc169899c440a7913";


        
   		string test_contract_bin  	= "6060604052341561000c57fe5b5b6101598061001c6000396000f30060606040526000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff168063cfae32171461003b575bfe5b341561004357fe5b61004b6100d4565b604051808060200182810382528381815181526020019150805190602001908083836000831461009a575b80518252602083111561009a57602082019150602081019050602083039250610076565b505050905090810190601f1680156100c65780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6100dc610119565b604060405190810160405280600381526020017f486921000000000000000000000000000000000000000000000000000000000081525090505b90565b6020604051908101604052806000815250905600a165627a7a72305820ed71008611bb64338581c5758f96e31ac3b0c57e1d8de028b72f0b8173ff93a10029";
   		string test_contract_addr 	= co_await deploy(endpoint, orchid_address, "0x" + test_contract_bin);
        string ERC20_addr 			= co_await deploy(endpoint, orchid_address, "0x" + file_to_string("tok-ethereum/build/ERC20.bin"));
        string OrchidToken_addr 	= co_await deploy(endpoint, orchid_address, "0x" + file_to_string("tok-ethereum/build/OrchidToken.bin"));
        string directory_addr	 	= co_await deploy(endpoint, orchid_address, "0x" + file_to_string("dir-ethereum/build/TestOrchidDirectory.bin"));
		
		printf("[%d] OrchidToken_addr(%s,%s) \n",   __LINE__, OrchidToken_addr.c_str(), OrchidToken_addr.c_str());
   		printf("[%d] directory_addr(%s,%s) \n",     __LINE__, directory_addr.c_str(),   directory_addr.c_str());

   		auto block = co_await endpoint.Latest();
 
 
        //set the orchid address (todo: figure out contract constructor args)
   		static Selector<uint256_t, Address,uint256_t> set_f("set");
   		co_await set_f.Send(endpoint, Address(orchid_address), Address(directory_addr), Address(OrchidToken_addr), uint256_t(0) );

   		block = co_await endpoint.Latest();

   		static Selector<Address,uint256_t> get_orchid("get_orchid");
   		auto directory_orchid = co_await get_orchid.Call(endpoint, block, Address(directory_addr), uint256_t("4") );
		printf("[%d] directory_orchid: ", __LINE__); std::cout << std::hex << directory_orchid << std::endl;
 
        
   	    Selector<uint256_t,Address> balanceOf("balanceOf");
   		auto origin_balance = co_await balanceOf.Call(endpoint, block, Address(OrchidToken_addr), Address(orchid_address) );
		printf("[%d] origin_balance: ", __LINE__); std::cout << std::dec << origin_balance << std::endl;
 
 
 
        // fund the medallions
        for (int i(0); i < int(node_address.size()); i++)
        {
	        Address saddr = Address(server_address[i%NumAccounts]);
	        Address raddr = node_address[i];
	        //uint128_t ntokens = node_ntokens[i];
	        uint128_t ntokens = node_ntokens[uint256_t(raddr)];
            co_await fund_medallion(endpoint, Address(orchid_address), Address(OrchidToken_addr), Address(directory_addr), saddr, ntokens, raddr);
        }
   		block = co_await endpoint.Latest();
        
        Selector<uint256_t> have_f("have");
        auto tot_ntokens = co_await have_f.Call(endpoint, block, Address(directory_addr) );
        
        // sample

        printf("[%d] Testing scan() \n\n\n", __LINE__);
        Selector<Address, uint128_t> scan_f("scan");

        Address result1 = co_await scan_f.Call(endpoint, block, Address(directory_addr), uint128_t(1) );
        printf("[%d] scan(1): ", __LINE__); std::cout << std::hex << result1 << std::endl;
        
        map<uint256_t, int> cnts;
        const int nsamples = 300;
        
        for (int i(0); i < int(nsamples); i++) {
            double rv      = double(rand()%10000) / double(10000);
            uint128_t rvi  = uint128_t(rv * pow(2.0, 128.0)); 
            Address raddr  = co_await scan_f.Call(endpoint, block, Address(directory_addr), rvi );
            printf("[%d] scan(%f): ", __LINE__,rv); std::cout << std::hex << raddr << std::endl;
            cnts[uint256_t(raddr)]++;
        }

        for (int i(0); i < int(node_address.size()); i++) {
            auto ntokens  = node_ntokens[uint256_t(node_address[i])];
            float rtokens = double(ntokens) / double(tot_ntokens);
            int cnt       = cnts[uint256_t(node_address[i])];
            float rcnt    = double(cnt) / double(nsamples);
            printf("[%d] node[%i]: ", __LINE__, i); std::cout << std::hex << node_address[i] << "  " << std::dec << node_ntokens[uint256_t(node_address[i])] << " " << rtokens << " " << rcnt << std::endl;
        }
        
        
        printf("[%d] Testing pull() \n\n\n", __LINE__);
 
        
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


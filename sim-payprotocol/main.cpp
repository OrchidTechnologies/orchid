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
*/




#include <string>
#include <cstdio>
#include <iostream>
#include <fstream>
#include <sstream>
#include "pay_protocol.h"
#include <random>


template <class T>
T sum(const vector<T>& X)
{
	double s = 0; for (int i(0); i < int(X.size()); i++) { s+= X[i]; } return s;
}

template <class T>
vector<T> prefix_sum(const vector<T>& X)
{
	vector<T> Y(X);
	double s = 0;
	for (int i(0); i < int(X.size()); i++) {
		s+= Y[i];
		Y[i] = s;
	}
	return Y;
}

template <class T>
int find_range(const vector<T>& X, const T& y)
{
	int i = 0;
	int e = X.size();
	//while (true) {
	for (int j(0); j < 1024; j++) {
		int m = (i + e)/2; //  + (rand()%2);
		//printf("%i,%i,%i %f < %f,%f,%f \n", i,m,e, y, X[i],X[m],X[e]);
		if (y < X[m]) {
			if (m == i) { return i;}
			e = m;
		}
		else {
			if (m == i) { return e;}
			i = m;
		}
		if (m >= X.size()-1) { return m; }
	}
	return -1;
}

void test_psums()
{
	printf(".");
	vector<double> X;  for (int i(0); i < 1000; i++) { X.push_back(double(rand()) / double(RAND_MAX)); }
	printf(".");
	double Xs = sum(X);
	printf(".");
	for (int i(0); i < int(X.size()); i++) { X[i] = X[i] / Xs; }
	printf(".");
	auto Xps = prefix_sum(X);
	printf(".");

	printf("\n");
	printf("%i 0.00 \n", find_range(Xps, 0.0) );
	printf("%i 0.01 \n", find_range(Xps, 0.01) );
	printf("%i 0.10 \n", find_range(Xps, 0.1) );
	printf("%i 0.50 \n", find_range(Xps, 0.5) );
	printf("%i 0.90 \n", find_range(Xps, 0.9) );

	printf(".");

}


struct Conn { bytes32 saddr; bytes32 daddr; double curload; };

struct Device { double throughput; double bqueued; };

struct Network
{

	double QueLimit = 1e7;

	map<bytes32, vector<Conn>> conns_;
	map<bytes32, Device> odevs_;
	map<bytes32, Device> idevs_;
	map<bytes32, INet*>  objs_;


	void step(double elap)
	{
		for (auto& cm : conns_) {
			auto& cs = cm.second;
			for (auto& c : cs) {
				double psize = c.curload * elap;

				auto& odev = odevs_[c.saddr];
				if (psize + odev.bqueued > QueLimit) {
					objs_[c.saddr]->on_dropped_packet(objs_[c.daddr], psize);
				}
				else if (psize + odev.bqueued > 0.1*QueLimit){
					objs_[c.saddr]->on_queued_packet(objs_[c.daddr], psize);
					odev.bqueued += psize;
				}
				else {
					odev.bqueued += psize;
				}

				auto& idev = idevs_[c.daddr];
				if (psize + idev.bqueued > QueLimit) {
					objs_[c.daddr]->on_dropped_packet(objs_[c.saddr], psize);
				}
				else if (psize + idev.bqueued > 0.1*QueLimit){
					objs_[c.daddr]->on_queued_packet(objs_[c.saddr], psize);
					idev.bqueued += psize;
				}
				else {
					idev.bqueued += psize;
				}

			}
		}

		for (auto& odm : odevs_) {
			auto& dev = odm.second;
			dev.bqueued = max(dev.bqueued - elap*dev.throughput, 0.0);
		}

		for (auto& idm : idevs_) {
			auto& dev = idm.second;
			dev.bqueued = max(dev.bqueued - elap*dev.throughput, 0.0);
		}

	}
};


struct Sim
{
	int NumClients = 1000;
	int NumServers = 10;

	vector<Client*> clients;
	vector<Server*> servers;
	vector<double> server_stakes;
	vector<double> server_stakes_ps;

	void client_new_connect(Client* client)
	{
		int si = find_range(server_stakes_ps, double(rand()) / double(RAND_MAX) );
		client->on_connect(servers[si]);
	}

	Sim()
	{
	    srand(time(NULL));
	    srand(38183);
	    default_random_engine gen(19818);


		printf("Initializing.");

		test_psums();

		printf(".");
		for (int i(0); i < NumClients; i++) {
			clients.push_back(new Client());
		}

		printf(".");
		for (int i(0); i < NumServers; i++) {
			servers.push_back(new Server());
		}

		printf("\n server_stakes: ");
		auto server_stake_dist = lognormal_distribution<>(8.0, 4.0);
		for (int i(0); i < NumServers; i++) {
			server_stakes.push_back(server_stake_dist(gen));
			printf(" %f ", server_stakes[i]);
		}
		printf("\n");

		auto server_stakes_s  = sum(server_stakes);
		server_stakes_ps = prefix_sum(server_stakes);
		for (int i(0); i < int(server_stakes_ps.size()); i++) { server_stakes_ps[i] = server_stakes_ps[i] / server_stakes_s; }

		printf("testing linear stake-weighted selection: ");
		for (int i(0); i < 5; i++) {
			int si = find_range(server_stakes_ps, double(rand()) / double(RAND_MAX) );
			printf(" (%i,%f) ", si, server_stakes[si]);
		}
		printf("\n");

		printf("client initial connect \n");
		for (int i(0); i < clients.size(); i++) {
			client_new_connect(clients[i]);
		}

	}

};

// ============================ ===================================

int main(int argc, char* argv[])
{
	printf("Start ppsim.\n");

	Sim sim;


	printf("\n");

	printf("Done!\n");

}

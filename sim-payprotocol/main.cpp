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


double& GetCurrentTime()
{
	static double ctime = 0;
	return ctime;
}

double CurrentTime() { return GetCurrentTime(); }



vector<ITickable*>& GetTickables()
{
	static vector<ITickable*> store_; return store_;
}

void register_timer_func(ITickable* p)
{
	GetTickables().push_back(p);
}

void step_all(double ctime)
{
	for (auto p : GetTickables())
	{
		double nst = p->next_step_time();
		printf("if ctime(%f) >= nst(%f)\n", ctime, nst);
		if (ctime >= nst) {
			p->step(ctime);
		}
	}
}


namespace Lot
{
	pot& balance(bytes32 k) {
		static map<bytes32, pot> local_;
		return local_[k];
	}
}





struct Device { double throughput; double bqueued; };

struct Network : public Tickable
{

	double QueLimit = 1e8;
	double ltime_   = 0.0;

	map<netaddr, Device> odevs_;
	map<netaddr, Device> idevs_;
	map<netaddr, INet*>  objs_;

	Network() {
		printf("Network: %f %f \n", QueLimit, ltime_);
		period_  = 1.0; register_timer_func(this);
	}

	void send(netaddr to, netaddr from, double psize)
	{
		auto& odev = odevs_[from];
		auto& idev = idevs_[to];

		printf("Network::send(%x,%x,%f) odev.bqueued(%f) idev.bqueued(%f)\n", to,from,psize,odev.bqueued,idev.bqueued);

		if (psize + odev.bqueued > QueLimit) {
			if (objs_[from] != nullptr) objs_[from]->on_dropped_packet(to,from,psize);
			return;
		}
		else if (psize + odev.bqueued > 0.2*QueLimit){
			if (objs_[from] != nullptr) objs_[from]->on_queued_packet(to,from, psize);
		}
		odev.bqueued += psize;

		if (psize + idev.bqueued > QueLimit) {
			if (objs_[to] != nullptr) objs_[to]->on_dropped_packet(to,from,psize);
			return;
		}
		else if (psize + idev.bqueued > 0.2*QueLimit){
			if (objs_[to] != nullptr) objs_[to]->on_queued_packet(to,from, psize);
		}
		idev.bqueued += psize;

		if (objs_[to] != nullptr) objs_[to]->on_packet(to,from,psize);
	}

	void add(INet* net, double ibw, double obw)
	{
		//printf("n(%f,%f) ", ibw, obw);
		netaddr addr  = net->get_netaddr();
		objs_[addr]   = net;
		idevs_[addr]  = Device{ibw, 0.0};
		odevs_[addr]  = Device{obw, 0.0};
	}

	virtual void step(double ctime)
	{
		printf("Network::step(%f)\n", ctime);
    	Tickable::step(ctime);
		double elap = ctime - ltime_;
		for (auto& odm : odevs_) {
			auto& dev = odm.second;
			dev.bqueued = max(dev.bqueued - elap*dev.throughput, 0.0);
		}

		for (auto& idm : idevs_) {
			auto& dev = idm.second;
			dev.bqueued = max(dev.bqueued - elap*dev.throughput, 0.0);
		}
		ltime_ = ctime;
	}
};

Network& get_network()
{
	static Network local;
	return local;
}

namespace net
{
	void send(netaddr to, netaddr from, double psize) 	{ get_network().send(to,from,psize); }
	void add(INet* net, double ibw, double obw) 		{ get_network().add(net,ibw,obw); }
}


namespace simple
{
	uint32 hash(uint32 x) {
		x = ((x >> 16) ^ x) * 0x45d9f3b;
		x = ((x >> 16) ^ x) * 0x45d9f3b;
		x = (x >> 16) ^ x;
		return x;
	}
}


template <class T>
void test_noise_f(const T& nf, int N = 60*60)
{
	double avg(0.0), nzf(0.0);
	for (int i(0); i < N; i++) {
		double x = nf.exec(double(i));
		//printf(" = %f \n", x);
		avg += x;
		if (x > 0.0) nzf += 1.0;
	}
	avg = avg / double(N);
	nzf = nzf / double(N);
	printf("avg: %f  nzf: %f \n", avg, nzf);

	printf("S: "); for (int i(0); i < 14; i++) { double x = nf.exec(double(i)*1.0);  	printf(" %f", x); } printf("\n");
	printf("M: "); for (int i(0); i < 14; i++) { double x = nf.exec(double(i)*Minutes); printf(" %f", x); } printf("\n");
	printf("H: "); for (int i(0); i < 14; i++) { double x = nf.exec(double(i)*Hours); 	printf(" %f", x); } printf("\n");
	printf("D: "); for (int i(0); i < 14; i++) { double x = nf.exec(double(i)*Days); 	printf(" %f", x); } printf("\n");

}

struct INoise_f
{
	virtual double exec(double x) const = 0;
	virtual ~INoise_f(){}
};

struct MultFractal : public INoise_f
{
	uint32 rseed_;
	double m_, b_, p_;
	int    n_;

	MultFractal(uint32 r, double m, double b, double p, int n): rseed_(r), m_(m), b_(b), p_(p), n_(n) {
		printf("MultFractal(%f, %f, %f, %i): ", m_, b_, p_, n_);
	}
	virtual ~MultFractal(){}

	virtual double exec(double x) const
	{
		double b = exp(b_);
		double r = 1.0;
		double d = pow(m_, double(n_-1));
		for (int i(0); i < n_; i++) {
			uint32 xi = uint32(x / d);
			uint32 rval  = simple::hash(rseed_ + xi);
			//printf(" %d,%d ", xi, rval);
			double rvalf = double(rval) / double(numeric_limits<uint32>::max());
			d = d / m_;
			r = max(r * rvalf - b, 0.0);
			//printf("%f ", r);
		}
		return pow(r, p_);
	}

};

struct FBM_f : public INoise_f
{
	uint32 rseed_;
	double m_, f_, r_;
	int n_;

	FBM_f(uint32 rs, double m, double f, double r, int n): rseed_(rs), m_(m), f_(f), r_(r), n_(n) {
		printf("FBM(%f, %f, %f, %i): ", m_, f_, r_, n_);
	}
	virtual ~FBM_f(){}


	double noise(uint32 x) const {
		return double(simple::hash(rseed_ + x)) / double(numeric_limits<uint32>::max());
	}

	double BM(double x) const {
		double x0 = double(uint32(x));
		double f  = x - x0;
		double n0 = noise(uint32(x)+1);
		double n1 = noise(uint32(x)+0);
		double y  = f*n0 + (1-f)*n1;
		//printf(" %f*%f + (1-%f)*%f = %f\n", f,n0,f,n1,y);
		return y;
	}

	virtual double exec(double x) const
	{
		double y = 0.0;
		double m = m_;
		double r = r_;
		for (int i(0); i < n_; i++) {
			y += m*BM(r*x);
			m *= f_;
			r *= 2.0;
		}
		return y;
	}
};

struct expFBM_f : public FBM_f
{
	double s_, b_, o_;

	expFBM_f(uint32 rs, double m, double f, double r, int n, double s, double b, double o): FBM_f(rs,m,f,r,n), s_(s), b_(b), o_(o) {
		printf("expFBM_f(%f,%f,%f): ", s_, b_, o_);
	}
	virtual ~expFBM_f(){}

	virtual double exec(double x) const
	{
		return max( s_ * exp(FBM_f::exec(x) + b_) + o_, 0.0);
	}
};



struct User : public Tickable
{
	uint32 		rseed_;
	Client* 	client_;
	INoise_f* 	bwdemandf_;		// temporal noise function for bw demand
	double		bwd_mult_;		// bandwidth demand scale multiplier
	netaddr		targ_addr_;

	double ltime_;

	User(Client* client, INoise_f* bwdf, double bwdm, netaddr ta): rseed_(rand()), client_(client), bwdemandf_(bwdf), bwd_mult_(bwdm), targ_addr_(ta)
	{
		ltime_ = 0.0;
		period_  = 1.0; register_timer_func(this);
	}

	void step(double ctime)
	{
		printf("User::step(%f) bwdf(%p) client(%p) \n", ctime, bwdemandf_, client_); fflush(stdout);
    	Tickable::step(ctime);
		// send a packet to our target of size (elapsed_time * bandwidth_demand)
		double elap = ctime - ltime_;
		double bwdm = bwdemandf_->exec(ctime);
		double bwd  = bwdm * bwd_mult_;
		printf("bwd(%f) = %f * %f \n", bwd, bwdm, bwd_mult_); fflush(stdout);
		double ps   = bwd*elap;
		auto server_addr = client_->server_->get_netaddr();
		net::send(server_addr, client_->get_netaddr(), ps);
		//net::send(targ_addr_, client_->get_netaddr(), ps);
		ltime_ = ctime;
		printf("\n");
	}

};


struct Website : public INet
{
	netaddr addr_;

	Website(): addr_(rand()) {}

	virtual ~Website() {}

	virtual netaddr get_netaddr() { return addr_; }

	// simple reflector
	virtual void on_packet(netaddr to, netaddr from, double psize) { net::send(from, to, psize); }

};


struct Sim
{
	int NumClients 	= 1; // 1000;
	int NumWebsites = 1; // 20;
	int NumServers 	= 1; // 10;

	vector<Client*> 	clients;
	vector<User*> 		users;
	vector<Website*> 	websites;
	vector<Server*> 	servers;
	vector<double> 		server_stakes;
	vector<double> 		server_stakes_ps;

	void client_new_connect_1H(Client* client, netaddr dst)
	{
		int si = find_range(server_stakes_ps, double(rand()) / double(RAND_MAX) );
		client->on_connect(servers[si], dst);
	}

	Sim()
	{
	    srand(time(NULL));
	    srand(381131);
	    default_random_engine gen(198182);


		printf("Initializing.");

		test_psums();


		printf(".\n");
		printf("create network \n");
		get_network();


		printf("auto-correlated temporal noise functions: .\n");
		{ MultFractal mf{uint32(rand()), 2.0, -9.46, 0.2, 12}; test_noise_f(mf); }
		{ MultFractal mf{uint32(rand()), 2.0, -8.46, 0.2, 12}; test_noise_f(mf); }
		{ MultFractal mf{uint32(rand()), 2.0, -7.46, 0.2, 12}; test_noise_f(mf); }

		printf(".\n");
		{ FBM_f 	mf{uint32(rand()),  0.5, 0.9,  1.0 / Hours, 1};  test_noise_f(mf); }
		{ FBM_f 	mf{uint32(rand()), -1.6, 0.6,  1.0 / Hours, 10}; test_noise_f(mf); }

		printf(".\n");
		vector<INoise_f*> noisefuncs_;
		{ auto mf = new expFBM_f{uint32(rand()), -1.6, 0.6,  1.0 / Days, 10, 1.0, 0.0, -0.05}; test_noise_f(*mf); noisefuncs_.push_back(mf); }
		{ auto mf = new expFBM_f{uint32(rand()), -1.0, 0.7,  1.0 / Days, 10, 2.0, 0.0, -0.30}; test_noise_f(*mf); noisefuncs_.push_back(mf); }
		{ auto mf = new expFBM_f{uint32(rand()), -1.0, 0.7,  1.0 / Days, 10, 3.0, 0.0, -0.70}; test_noise_f(*mf); noisefuncs_.push_back(mf); }
		{ auto mf = new expFBM_f{uint32(rand()), -1.0, 0.7,  1.0 / Days, 10, 4.0, 0.0, -1.00}; test_noise_f(*mf); noisefuncs_.push_back(mf); }
		{ auto mf = new expFBM_f{uint32(rand()), -1.0, 0.8,  1.0 / Days, 10, 6.0, 0.0, -1.00}; test_noise_f(*mf); noisefuncs_.push_back(mf); }


		printf("Creating %i websites .\n", NumWebsites);
		for (int i(0); i < NumWebsites; i++) {
			Website* ws = new Website();
			websites.push_back(ws);
			auto ibw_dist = lognormal_distribution<>(  18, 7);
			auto obw_dist = lognormal_distribution<>( 0.0, 1.0);
			double ibw = ibw_dist(gen);
			double obw = ibw * obw_dist(gen);
			net::add(ws, ibw, obw);
		}

		printf("Creating %i clients .\n", NumClients);
		for (int i(0); i < NumClients; i++) {

			bytes32 account = rand();

			auto client_bal_dist = lognormal_distribution<>(4, 2);
			Lot::balance(account) = Lot::pot{client_bal_dist(gen), 4.0};
	        double curbal   = Lot::balance(account).amount_;
	        printf("funded client balance(%f) \n", curbal);

			auto client_budget_time_dist = normal_distribution<>(1*Months, 1*Months);

			Client* client = new Client(account, client_budget_time_dist(gen));


			clients.push_back(client);
			auto ibw_dist = lognormal_distribution<>(  14, 4);
			auto obw_dist = lognormal_distribution<>(-1.0, 1.5);
			double ibw = ibw_dist(gen);
			double obw = ibw * obw_dist(gen);
			net::add(client, ibw, obw);

			auto obwu_dist = lognormal_distribution<>(  14, 4);
			INoise_f* noisef = (noisefuncs_[ rand() % noisefuncs_.size() ]);
			printf("noisef(%p)\n", noisef);
			test_noise_f(*noisef);

			Website* ws = websites[ rand() % websites.size() ];

			User* user = new User(client, noisef, obwu_dist(gen), ws->get_netaddr());
			users.push_back(user);
			//user->step(0.0);
		}

		//printf("testing \n");
		//for (auto user : users) {user->step(0.0);}

		printf("Creating %i servers . \n", NumServers);
		for (int i(0); i < NumServers; i++) {
			Server* server = new Server();
			servers.push_back(server);
			auto ibw_dist = lognormal_distribution<>(  18, 7);
			auto obw_dist = lognormal_distribution<>( 0.0, 1.0);
			double ibw = ibw_dist(gen);
			double obw = ibw * obw_dist(gen);
			net::add(server, ibw, obw);
		}

		printf("server_stakes: ");
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

		printf("clients connecting \n");
		for (int i(0); i < clients.size(); i++) {
			client_new_connect_1H(clients[i], users[i]->targ_addr_);
		}


		printf("running sim loop: \n");
		double ctime = 0.0;
		for (int i(0); i < 2; i++)
		{
			ctime += 1.0;
			step_all(ctime);
		}
		printf("end sim loop \n");


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

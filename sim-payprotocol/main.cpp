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
#include <stdarg.h>
#include <time.h>
#include <chrono>

using namespace std::chrono;


const int MaxLogLevel = 1;




template <class X, class Y> inline pair<X,Y> pair_(const X& x, const Y& y) { return pair<X,Y>(x,y); }

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
	int e = X.size()-1;
	//while (true) {
	for (int j(0); j < 1024; j++) {
		int m = (i + e)/2; //  + (rand()%2);
		if (y < X[m]) {
			//printf("%i,%i,%i %f <  %f  %f,%f \n", i,m,e, y,X[m], X[i],X[e]);
			if (m == i) { return i;}
			e = m;
		}
		else {
			//printf("%i,%i,%i %f >= %f  %f,%f \n", i,m,e, y,X[m], X[i],X[e]);
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


struct timer
{
	decltype(high_resolution_clock::now()) sclock_;

	inline timer()
	{
		sclock_ = high_resolution_clock::now();
	}

	inline double elapsed() const
	{
		auto eclock  = high_resolution_clock::now();
		double elap  = duration_cast<duration<double>>(eclock - sclock_).count();
		return elap;
	}

};


vector<ITickable*>& GetTickables()
{
	static vector<ITickable*> store_; return store_;
}

void register_timer_func(ITickable* p)
{
	GetTickables().push_back(p);
}

void step_all(const timer& clock, double ctime)
{
	GetCurrentTime() = ctime;

	int cstep = int(ctime);

	double walltime = clock.elapsed();
	double speedup  = ctime/walltime;

	if 		(cstep % 1000 == 0) dlog(0,"step_all(%f) in %fs (%fX)\n",ctime,walltime,speedup);
	else if (cstep % 100  == 0) dlog(1,"step_all(%f) in %fs (%fX)\n",ctime,walltime,speedup);
	else if (cstep % 10   == 0) dlog(2,"step_all(%f) in %fs (%fX)\n",ctime,walltime,speedup);
	else						dlog(3,"step_all(%f) in %fs (%fX)\n",ctime,walltime,speedup);

	for (auto p : GetTickables())
	{
		double nst = p->next_step_time();
		dlog(3,"if ctime(%f) >= nst(%f)\n", ctime, nst);
		if (ctime >= nst) {
			p->step(ctime);
		}
	}
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



bytes32 keccak256(const string& x) 	{ return hash<string>{}(x); }
uint256 keccak256(uint256 x) 		{ return simple::hash(x); }

// 'signature' is just the signer address, for easy recovery
bytes32 sign(bytes32 x, bytes32 signer)	{ return signer;}
bytes32 ecrecover(bytes32 sig)			{ return sig; }



double& get_trans_cost() // (oracle) get current transaction cost estimate
{
	static double local_(0.00001);
	return local_;
}

double& get_max_trans_cost()   // (oracle) get estimate of max reasonable current transaction fees
{
	static double local_(0.001);
	return local_;
}

double& get_OXT_balance(bytes32 account)  	// (RPC call, cached) external eth balance
{
	static map<bytes32, double> balances_;
	return balances_[account];
}


namespace Lot
{
	pot& balance(bytes32 k) {
		static map<bytes32, pot> local_;
		return local_[k];
	}
}




struct RotLog
{
	const char* name_;
	FILE* p_;
	int   idx_;
	int   cnt_;
	int	  maxN_;

	RotLog(const char* name, int maxN): name_(name), p_(nullptr), idx_(0), cnt_(0), maxN_(maxN)
	{
		std::string rname = std::string(name_) + to_string(idx_);
		p_ = fopen(rname.c_str(), "w");
	}

	~RotLog()
	{
		fclose(p_);
	}

	FILE* get()
	{
		if (p_ == nullptr) return nullptr;

		if ((cnt_++) >= maxN_)
		{
			fclose(p_);
			idx_ = (idx_ + 1) % 2;
			std::string rname = std::string(name_) + to_string(idx_);
			p_ = fopen(rname.c_str(), "w");
			cnt_ = 0;
		}
		return p_;
	}
};


RotLog Log0 = RotLog("log0_", 512*1024);
RotLog Log1 = RotLog("log1_", 512*1024);
RotLog Log2 = RotLog("log2_", 512*1024);
RotLog Log3 = RotLog("log3_", 512*1024);

FILE* get_logfile(int i) {
	if (i == 0) { return Log0.get(); }
	if (i == 1) { return Log1.get(); }
	if (i == 2) { return Log2.get(); }
	if (i == 3) { return Log3.get(); }
	assert(false);
	return nullptr;
}


void dlog(int level, const char* fmt, ...)
{
	for (int i = 0; i <= MaxLogLevel; i++) {
	    if (i >= level) {
	    	{
			va_list args;
			va_start(args, fmt);
			vfprintf(get_logfile(i), fmt, args);
			va_end(args);
	    	}
	    }
	}
	if (level <= 0) {
		va_list args;
		va_start(args, fmt);
		vprintf(fmt, args);
		va_end(args);
	}

}





struct Device { double throughput; double bqueued; };

struct Network : public Tickable
{

	double QueLimitT = 10.0;
	double ltime_    = 0.0;

	map<uint32, Device> odevs_;
	map<uint32, Device> idevs_;
	map<uint32, INet*>  objs_;

	Network() {
		dlog(0,"Network: %f %f \n", QueLimitT, ltime_);
		period_  = 1.0; register_timer_func(this);
	}

	void send(netaddr to, netaddr from, const Packet& p)
	{
		double psize = get_size(p);
		auto& odev   = odevs_[from.addr_];
		auto& idev   = idevs_[to.addr_];

		dlog(3, "Network::send      ([%x,%x],[%x,%x],%e,%i) odev(%e,%e) idev(%e,%e)\n", to.addr_,to.port_,from.addr_,from.port_,psize,get_id(p),odev.throughput,odev.bqueued,idev.throughput,idev.bqueued);

		double olimit = QueLimitT * odev.throughput; // specify queue limit as relative to throughput
		if (psize + odev.bqueued > olimit) {
			if (objs_[from.addr_] != nullptr) objs_[from.addr_]->on_dropped_packet(to,from,p);
			dlog(3, "Network::send(%x,%x,%e) psize(%e) + odev.bqueued(%e) > olimit(%e) \n", to.addr_,from.addr_,psize,psize,odev.bqueued,olimit);
			return;
		}
		else if (psize + odev.bqueued > 0.2*olimit){
			if (objs_[from.addr_] != nullptr) objs_[from.addr_]->on_queued_packet(to,from, p);
		}
		odev.bqueued += psize;

		double ilimit = QueLimitT * idev.throughput; // specify queue limit as relative to throughput
		if (psize + idev.bqueued > ilimit) {
			if (objs_[to.addr_] != nullptr) objs_[to.addr_]->on_dropped_packet(to,from,p);
			dlog(3, "Network::send(%x,%x,%e) psize(%e) + idev.bqueued(%e) > ilimit(%e) \n", to.addr_,from.addr_,psize,psize,idev.bqueued,ilimit);
			return;
		}
		else if (psize + idev.bqueued > 0.2*ilimit){
			if (objs_[to.addr_] != nullptr) objs_[to.addr_]->on_queued_packet(to,from, p);
		}
		idev.bqueued += psize;

		if (objs_[to.addr_] != nullptr) objs_[to.addr_]->on_packet(to,from,p);
	}

	void add(INet* net, double ibw, double obw)
	{
		dlog(2, "Network::add(%e,%e) \n", ibw, obw);
		netaddr addr  = net->get_netaddr();
		objs_[addr.addr_]   = net;
		idevs_[addr.addr_]  = Device{ibw, 0.0};
		odevs_[addr.addr_]  = Device{obw, 0.0};
	}

	virtual double step(double ctime)
	{
		dlog(3, "Network::step(%f)\n", ctime);
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
		return elap;
	}
};

Network& get_network()
{
	static Network local;
	return local;
}


namespace net
{
	void send(netaddr to, netaddr from, const Packet& p) 	{ get_network().send(to,from,p); }
	void add(INet* net, double ibw, double obw) 			{ get_network().add(net,ibw,obw); }
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
	dlog(1,"avg: %f  nzf: %f \n", avg, nzf);

	dlog(1,"S: "); for (int i(0); i < 14; i++) { double x = nf.exec(double(i)*1.0);  	dlog(1," %f", x); } dlog(1,"\n");
	dlog(1,"M: "); for (int i(0); i < 14; i++) { double x = nf.exec(double(i)*Minutes); dlog(1," %f", x); } dlog(1,"\n");
	dlog(1,"H: "); for (int i(0); i < 14; i++) { double x = nf.exec(double(i)*Hours); 	dlog(1," %f", x); } dlog(1,"\n");
	dlog(1,"D: "); for (int i(0); i < 14; i++) { double x = nf.exec(double(i)*Days); 	dlog(1," %f", x); } dlog(1,"\n");

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
		dlog(1,"MultFractal(%f, %f, %f, %i): ", m_, b_, p_, n_);
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
		dlog(1,"FBM(%f, %f, %f, %i): ", m_, f_, r_, n_);
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
		dlog(1,"expFBM_f(%f,%f,%f): ", s_, b_, o_);
	}
	virtual ~expFBM_f(){}

	virtual double exec(double x) const
	{
		return max( s_ * exp(FBM_f::exec(x) + b_) + o_, 0.0);
	}
};


struct Sim;


struct User : public Tickable
{
	Sim*		sim_;
	uint32 		rseed_;
	Client* 	client_;
	INoise_f* 	bwdemandf_;		// temporal noise function for bw demand
	double		bwd_mult_;		// bandwidth demand scale multiplier
	netaddr		targ_addr_;

	double      half_life_ = 10.0; // average reroll time at 50% throttling

	double bwd_ = 1.0;

	double ltime_;

	User(Sim* sim, Client* client, INoise_f* bwdf, double bm, netaddr ta): sim_(sim), rseed_(rand()), client_(client), bwdemandf_(bwdf), bwd_mult_(bm), targ_addr_(ta)
	{
		ltime_      = 0.0;
		period_     = 1.0; register_timer_func(this);
		double bwdm = bwdemandf_->exec(CurrentTime());
		bwd_        = bwdm * bwd_mult_;
	}

	void reroll_check(double ctime, double elap);

	double step(double ctime)
	{
    		Tickable::step(ctime);

		double elap = ctime - ltime_;
    		reroll_check(ctime, elap);

		// send a packet to our target of size (elapsed_time * bandwidth_demand)
		double bwdm = bwdemandf_->exec(ctime);
		bwd_  		= bwdm * bwd_mult_;
		double bwd 	= bwd_;
		dlog(2,"User::step(%f) bwdf(%p) client(%p) bwd(%e) = %f * %e  \n", ctime, bwdemandf_, client_,  bwd, bwdm, bwd_mult_);

		if (bwd > 0.0) {
			client_->set_active(1.0);
			double ps   = bwd*elap;
			client_->send_data(ctime, targ_addr_, ps);
		}
		else {
			client_->set_active(0.0);
		}


		ltime_ = ctime;
		return elap;
	}


};


struct Website : public INet
{
	netaddr addr_;

	Website(): addr_{uint32(rand()),8020} {}

	virtual ~Website() {}

	virtual netaddr get_netaddr() { return addr_; }

	// simple reflector
	virtual void on_packet(netaddr to, netaddr from, const Packet& p)
	{
		dlog(2,"Website::on_packet (%x,%x,%e) \n", to,from,get_size(p));
		net::send(from, addr_, p);
	}

};


void Server::print_info(int llev, double ctime, double stake, int nusers)
{
	double bal = get_OXT_balance(account_);

	double ibw = get_network().idevs_[address_.addr_].throughput;
	double obw = get_network().odevs_[address_.addr_].throughput;

	double iq = get_network().idevs_[address_.addr_].bqueued;
	double oq = get_network().odevs_[address_.addr_].bqueued;

	dlog(llev,"Server balance[%8x]=%9.4f  stake(%8.0f)  ratio(%4.4f)  ibw(%e,%f) obw(%e,%f) nusers(%i) \n", account_, bal, stake, bal/stake, ibw,iq/ibw, obw,oq/obw, nusers);
}




struct Sim
{
	const int NumClients  = 200; // 200; // 200; // 200;
	const int NumWebsites = 20; // 20; // 20;
	const int NumServers  = 10; // 10; // 10;
	const int NumHops     = 3;

	vector<Client*> 	clients;
	vector<User*> 		users;
	vector<Website*> 	websites;
	vector<Server*> 	servers;
	vector<double> 		server_stakes;
	map<Server*,double> server_stake_map;
	vector<double> 		server_stakes_ps;

	default_random_engine gen;


	void client_new_connect(double ctime, Client* client, netaddr dst)
	{
		vector<pair<netaddr,bytes32>> route;

		set<int> sidxs;

		for (int i(0); i < NumHops; i++)
		{

			int sidx = -1;
			double rv = -1.0;
			for (int j(0); j < 100; j++) {
				rv     = double(rand()) / double(RAND_MAX) ;
				int si = find_range(server_stakes_ps, rv);
				if (sidxs.find(si) == sidxs.end()) { sidx = si; break; }
			}

			assert(sidx >= 0);
			sidxs.insert(sidx);

			Server* server = servers[sidx];
			double stake  = server_stakes[sidx];
			// bw(%e,%e)\n", ibw,obw

			double ibw = get_network().idevs_[server->address_.addr_].throughput;
			double obw = get_network().odevs_[server->address_.addr_].throughput;

			double iq = get_network().idevs_[server->address_.addr_].bqueued;
			double oq = get_network().odevs_[server->address_.addr_].bqueued;

			double iqr = iq/(ibw + 0.0000001);
			double oqr = oq/(obw + 0.0000001);

			double ratelm 	= client->rate_limit_mult_;

			dlog(1, "client_new_connect(%f,%p,%x) ratelm(%f) rv(%f) sidx(%i) stake(%f) ibw(%e,%f) obw(%e,%f) \n", ctime,client,dst, ratelm, rv,sidx,stake, ibw,iqr, obw,oqr);

			route.push_back(pair_(server->address_, server->account_));
		}

		client->on_connect(ctime, route);
	}

	void print_server_info(double ctime)
	{	
		int cstep = int(ctime);
		int llev  = -1;

		if      (cstep % 1000 == 0) llev = 0;
		else if (cstep % 100  == 0) llev = 1;

		map<uint32,int> user_cnts;

		for (auto client : clients) {
			for (const auto& node : client->route_) {
				user_cnts[node.address_.addr_]++;
			}
		}


		if (llev >= 0) {
			for (auto server : servers) {
				server->print_info(llev, ctime, server_stake_map[server], user_cnts[server->address_.addr_]);
			}
		}
	}

	void print_client_info(double ctime)
	{
		int cstep = int(ctime);
		int llev  = -1;

		if 	(cstep % 1000 == 0) llev = 0;
		else if (cstep % 100  == 0) llev = 1;

		double nsent = 0;
		double nrecv = 0;

		for (auto client : clients) {
			nsent += client->packs_sent_;
			nrecv += client->packs_recv_;
		}

		if (llev >= 0) {
			dlog(llev, "client packets sent(%f) recv(%f) frac(%f) \n", nsent, nrecv, nrecv / nsent);
		}

	}

	Sim(): gen(492782) {}

	void init()
	{
	    srand(time(NULL));
	    srand(3864320);


		dlog(0,"Initializing.");

		test_psums();


		dlog(0,".\n");
		dlog(0,"create network \n");
		get_network();


		dlog(0,"auto-correlated temporal noise functions: .\n");
		{ MultFractal mf{uint32(rand()), 2.0, -9.46, 0.2, 12}; test_noise_f(mf); }
		{ MultFractal mf{uint32(rand()), 2.0, -8.46, 0.2, 12}; test_noise_f(mf); }
		{ MultFractal mf{uint32(rand()), 2.0, -7.46, 0.2, 12}; test_noise_f(mf); }

		dlog(0,".\n");
		{ FBM_f 	mf{uint32(rand()),  0.5, 0.9,  1.0 / Hours, 1};  test_noise_f(mf); }
		{ FBM_f 	mf{uint32(rand()), -1.6, 0.6,  1.0 / Hours, 10}; test_noise_f(mf); }

		dlog(0,".\n");
		vector<expFBM_f*> noisefuncs_;
		{ auto mf = new expFBM_f{uint32(rand()), -1.6, 0.6,  1.0 / Days, 10, 1.0, 0.0, -0.05}; test_noise_f(*mf); noisefuncs_.push_back(mf); }
		{ auto mf = new expFBM_f{uint32(rand()), -1.0, 0.7,  1.0 / Days, 10, 2.0, 0.0, -0.30}; test_noise_f(*mf); noisefuncs_.push_back(mf); }
		{ auto mf = new expFBM_f{uint32(rand()), -1.0, 0.7,  1.0 / Days, 10, 3.0, 0.0, -0.70}; test_noise_f(*mf); noisefuncs_.push_back(mf); }
		{ auto mf = new expFBM_f{uint32(rand()), -1.0, 0.7,  1.0 / Days, 10, 4.0, 0.0, -1.00}; test_noise_f(*mf); noisefuncs_.push_back(mf); }
		{ auto mf = new expFBM_f{uint32(rand()), -1.0, 0.8,  1.0 / Days, 10, 6.0, 0.0, -1.00}; test_noise_f(*mf); noisefuncs_.push_back(mf); }


		double ctime = 0.0;

		dlog(0,"Creating %i websites .\n", NumWebsites);
		for (int i(0); i < NumWebsites; i++) {
			Website* ws = new Website();
			websites.push_back(ws);
			auto ibw_dist = lognormal_distribution<>(  22, 3);
			auto obw_dist = lognormal_distribution<>( 0.0, 0.5);
			double ibw = ibw_dist(gen);
			double obw = ibw * obw_dist(gen);
			net::add(ws, ibw, obw);
		}

		dlog(0,"Creating %i clients .\n", NumClients);
		for (int i(0); i < NumClients; i++) {

			bytes32 account = rand();

			auto client_bal_dist = lognormal_distribution<>(4, 0.5); // 2);
			Lot::balance(account) = Lot::pot{client_bal_dist(gen), 4.0};
	        double curbal   = Lot::balance(account).amount_;
	        dlog(2,"funded client balance(%f) \n", curbal);

			auto client_budget_time_dist = normal_distribution<>(6*Months, 2*Months); // 1*Months);

			Client* client = new Client(account, client_budget_time_dist(gen), NumHops);


			clients.push_back(client);
			auto ibw_dist = lognormal_distribution<>(  14, 2); // 4);
			auto obw_dist = lognormal_distribution<>(-0.0, 1); // 1.5);
			double ibw = ibw_dist(gen);
			double obw = ibw * obw_dist(gen);
			net::add(client, ibw, obw);


			expFBM_f* noisef_ = (noisefuncs_[ rand() % noisefuncs_.size() ]);
			expFBM_f* noisef  = new expFBM_f(*noisef_); noisef->rseed_ = rand();
			test_noise_f(*noisef);

			Website* ws = websites[ rand() % websites.size() ];

			auto bwd_dist = lognormal_distribution<>(  14, 2); // 4);

			User* user = new User(this, client, noisef, bwd_dist(gen), ws->get_netaddr());
			users.push_back(user);
			//user->step(0.0);
		}

		//printf("testing \n");
		//for (auto user : users) {user->step(0.0);}

		dlog(0,"Creating %i servers . \n", NumServers);
		for (int i(0); i < NumServers; i++) {
			Server* server = new Server();
			servers.push_back(server);
			auto ibw_dist = lognormal_distribution<>(  22, 4);
			auto obw_dist = lognormal_distribution<>( 0.0, 1.0);
			auto honest_dist = bernoulli_distribution(0.75);
			double honest = honest_dist(gen);
			double ibw = honest * ibw_dist(gen);
			double obw = honest * ibw * obw_dist(gen);
			net::add(server, ibw, obw);
			dlog(0,"bw(%e,%e)\n", ibw,obw);
		}

		dlog(0,"server_stakes: ");
		auto server_stake_dist = lognormal_distribution<>(8.0, 0.0); // 2.0);
		for (int i(0); i < NumServers; i++) {
			server_stakes.push_back(server_stake_dist(gen));
			server_stake_map[servers[i]] = server_stakes[i];
			dlog(0," %f ", server_stakes[i]);
		}
		dlog(0,"\n");

		auto server_stakes_s  = sum(server_stakes);
		server_stakes_ps = prefix_sum(server_stakes);
		for (int i(0); i < int(server_stakes_ps.size()); i++) { server_stakes_ps[i] = server_stakes_ps[i] / server_stakes_s; }

		dlog(0,"testing linear stake-weighted selection: ");
		for (int i(0); i < 5; i++) {
			int si = find_range(server_stakes_ps, double(rand()) / double(RAND_MAX) );
			dlog(0," (%i,%f) ", si, server_stakes[si]);
		}
		dlog(0,"\n");

		dlog(0,"clients connecting \n");
		for (int i(0); i < clients.size(); i++) {
			client_new_connect(ctime, clients[i], users[i]->targ_addr_);
		}


		timer timer_;
		dlog(0,"running sim loop: \n");
		//for (int i(0); i < 20000; i++)
		double sim_length = 1*Weeks;
		for (ctime = 1.0; ctime <= sim_length; ctime += 1.0)
		{
			//ctime += 1.0;
			step_all(timer_, ctime);

			print_server_info(ctime);
			print_client_info(ctime);

			//fflush(stdout);

		}
		dlog(0,"end sim loop \n");


	}

};

Sim& get_sim()
{
	static Sim sim; return sim;
}


void Client::on_update_route()
{
	dlog(1,"Client::on_update_route(): \n");
	uniform_int_distribution<uint64> udist;
	routehash_ = udist(get_sim().gen); // fake hash
}


void User::reroll_check(double ctime, double elap)
{

	double rate_limit 	= client_->rate_limit_mult_;
	double lrl 		  	= -log(rate_limit);
	double half_life  	= half_life_ / (lrl + 0.00000001);
	double keep_prob  	= pow(0.5, elap / half_life);
	auto keep_dist 		= bernoulli_distribution(keep_prob);
	double keep 		= keep_dist(sim_->gen);

	dlog(2,"reroll_check(%f,%f) keep(%f) keep_prob(%f) = pow(0.5, %f / %f) half_life = (%f / (lrl + epsi)))  lrl(%f) = -log(%f) \n", ctime,elap, keep,keep_prob, elap,half_life,half_life_,lrl,rate_limit );

	if (keep < 0.5) {
		sim_->client_new_connect(ctime, client_, targ_addr_);
		half_life_ *= 1.2; // every time we reroll we take longer to reroll the next time
	}

	//  x^(t/hl)  = p
	//  x^(10/10) = 0.5
	// 0.5^(t/hl)
}

// ============================ ===================================

int main(int argc, char* argv[])
{
	printf("Start ppsim.\n");

	get_sim().init();


	printf("\n");

	printf("Done!\n");

}

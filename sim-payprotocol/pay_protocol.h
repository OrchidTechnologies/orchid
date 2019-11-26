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



#include <map>
#include <set>
#include <vector>
#include <math.h>
#include <functional>
#include <limits>
#include <assert.h>

double Minutes = 60;
double Hours   = 60*Minutes;
double Days    = 24*Hours;
double Weeks   = 7*Days;
double Months  = 30*Days;

using namespace std;


typedef unsigned int uint32;
typedef unsigned long long uint64;

typedef unsigned int bytes32;
typedef unsigned int uint256;
//typedef unsigned int netaddr;



struct netaddr
{
	uint32 addr_ = 0;
	uint32 port_ = 0;
};

inline bool operator==(const netaddr& x, const netaddr& y) { return (x.addr_ == y.addr_) && (x.port_ == y.port_);  }


// ==================  misc/debugging/loggin ==============================

void dlog(int level, const char* fmt, ...);


// ==================  ETH misc ==============================



template <class T>
string encodePacked(T x) { return to_string(x); }

template <class T, class ... Ts>
string encodePacked(T x, Ts... xs)
{
	return to_string(x) + encodePacked(xs...);
}

bytes32 keccak256(const string& x);
uint256 keccak256(uint256 x);
bytes32 sign(bytes32 x, bytes32 signer);
bytes32 ecrecover(bytes32 sig);


double& get_trans_cost();
double& get_max_trans_cost();
double& get_OXT_balance(bytes32 account);

struct payment
{
	bytes32 hash_secret, target, nonce, sender;
	double  ratio, start, range, amount;
	bytes32 sig;
};

double is_winner(bytes32 secret, bytes32 nonce, double ratio)  // offline check to see if ticket is a winner
{
    double rval = double(keccak256(encodePacked(secret, nonce))) / double(numeric_limits<bytes32>::max());
    return rval < ratio;
}


namespace Lot
{
	struct pot { double amount_, escrow_; };

	pot& balance(bytes32 k);

	void grab(bytes32 secret, bytes32 hash, bytes32 target, bytes32 nonce, double ratio, double start, double range, double amount, bytes32 sig, vector<bytes32>)
	{
		if (is_winner(secret, nonce, ratio)) {
			bytes32 sender = ecrecover(sig);
			dlog(2,"grab(%x,%x,%x,%x,%f,%f,%f,%f,%x) winner! amount(%f) ", secret,hash,target,nonce,ratio,start,range,amount,sig, amount);
			if (balance(sender).amount_ >= amount) {
				dlog(2,"balance[%x](%f) >= %f \n", sender, balance(sender).amount_, amount);
				balance(sender).amount_ -= amount;
				get_OXT_balance(target) += amount;
			}
			else {
				dlog(2,"balance[%x](%f) < %f \n", sender, balance(sender).amount_, amount);
				balance(sender).escrow_ = 0;
			}
		}

	}
}




// ==================  Network/IMsg Interface ==============================


struct Connect_Msg;
struct Payable_Msg;
struct Payment_Msg;

struct Packet;

struct IMsgReciever
{
	virtual ~IMsgReciever() {}
	virtual void on_recv(netaddr to, netaddr from, const Packet& inpack, Connect_Msg* msg) {};
	virtual void on_recv(netaddr to, netaddr from, const Packet& inpack, Payable_Msg* msg) {};
	virtual void on_recv(netaddr to, netaddr from, const Packet& inpack, Payment_Msg* msg) {};
};

struct Msg
{
	bytes32 recipient_;

	Msg(bytes32 r): recipient_(r) {}

	virtual ~Msg() {}
	virtual bytes32 get_recipient() { return recipient_; }
	virtual void    recv(netaddr to, netaddr from, const Packet& p, IMsgReciever* r)  = 0;
};


struct Packet
{
	uint32 id_   = 0;
	double size_ = 0.0;

	uint64 routehash_ = 0; // 'real' packet wouldn't store this, optimization for sim
	vector<netaddr> fwds_;
	vector<Msg*> 	msgs_;
	vector<bytes32> payersigs_;
};

template <class T> inline T  zero(T)  { return T(); }
template <class T> inline T* zero(T*) { return nullptr; }

template <class T> inline T safe_back(const vector<T>& X) { T x(zero(T())); if (X.size() > 0) x = X.back(); return x; }

inline double  get_size( const Packet& p) { return p.size_; }
inline uint32  get_id(	 const Packet& p) { return p.id_; }
inline bytes32 get_payer(const Packet& p) { return safe_back(p.payersigs_);}
inline netaddr get_fwd(  const Packet& p) { return safe_back(p.fwds_); }
inline Msg*    get_msg(  const Packet& p) { return safe_back(p.msgs_); }
inline void    del_msg(  const Packet& p) { delete p.msgs_.back(); }
inline bool    has_fwd(  const Packet& p) { return p.fwds_.size() > 0; }
inline uint64  get_route_hash(const Packet& p) { return p.routehash_; }

inline void    strip( Packet& p)    { p.fwds_.pop_back(); p.msgs_.pop_back(); p.payersigs_.pop_back(); }

// netaddr get_next(packet& p);





struct Payment_Msg : public Msg
{
	payment payment_;

	Payment_Msg(bytes32 r, const payment& p): Msg(r), payment_(p) {}

	virtual void    recv(netaddr to, netaddr from, const Packet& p, IMsgReciever* r) { r->on_recv(to,from,p,this); }
};

struct Payable_Msg : public Msg
{
	netaddr 	address_ = {};
	bytes32 	stakee_  = 0;
	bytes32 	target_  = 0; // could be different from stakee_ . .?
	uint256 	hash_secret_ = 0;

	Payable_Msg(bytes32 r, netaddr a, bytes32 s, bytes32 t, uint256 hs): Msg(r), address_(a), stakee_(s), target_(t), hash_secret_(hs) {}

	virtual void    recv(netaddr to, netaddr from, const Packet& p, IMsgReciever* r) { r->on_recv(to,from,p,this); }
};

struct Connect_Msg : public Msg
{

	bytes32 sender_;

	Connect_Msg(bytes32 r, bytes32 s): Msg(r), sender_(s) {}

	virtual void    recv(netaddr to, netaddr from, const Packet& p, IMsgReciever* r) { r->on_recv(to,from,p,this); }
};




//struct packet;

/*
// todo: replace
struct packet
{
	double 	size_;
	bytes32	payer_;
	vector<netaddr> route_;
	uint32  id_;
};

*/





struct INet : public IMsgReciever
{
	virtual ~INet() {}

	virtual netaddr get_netaddr() = 0;

	virtual void on_packet(			netaddr to, netaddr from, const Packet& p){}
	virtual void on_dropped_packet(	netaddr to, netaddr from, const Packet& p){}
	virtual void on_queued_packet( 	netaddr to, netaddr from, const Packet& p){}

};

namespace net
{
	void send(netaddr to, netaddr from, const Packet& p);
	void add(INet* net, double ibw, double obw);
}




// ==================  Time and Tickable (event simulation) ==============================


double CurrentTime();

struct ITickable
{
	virtual ~ITickable() {}
    virtual double step(double ctime) = 0;
    virtual double next_step_time() = 0;
};

void register_timer_func(ITickable* p);


struct Tickable : public ITickable
{
	virtual ~Tickable() {}

	double period_ = 1.0;
	double next_   = 0.0;
        double last_   = 0.0;

    virtual double step(double ctime) {
        double last = last_;
        last_ = ctime;
    	next_ = ctime + period_;
        return ctime - last;
    }

    virtual double next_step_time() {
    	return next_;
    }

    void reset(double n) { next_ = n; }


};




// ==================  Pay Protocol interfaces,objects ==============================



struct Server;



struct IBudget
{
	virtual ~IBudget() {}
	virtual double get_afford(double ctime) = 0;
	virtual double get_max_faceval() = 0;
    virtual void on_connect(double ctime) = 0;
    virtual void on_disconnect() {}
    virtual void on_payment(double ctime, double amt) {}
	virtual void set_active(double aratio) = 0;
};


struct Budget_SurpTrack2 : public IBudget, public Tickable
{
	// UI/config inputs
    double budget_rate_   = 0; // based budget in OXT/s
    double prepay_credit_ = 0; // in OXT
	double max_faceval_	  = 1.0;  // maximum allowable faceval in OXT (user's hard variance limit)

    // internal
    double active_ = 1.0;
    double surplus_ = 0; // todo: surplus should be initialized to some non-zero fraction of the (unknown) budget
    double nxt_surplus_ = 0;
    double last_aff_date_ = 0;
    double last_pay_date_ = 0;
    double prepay_amt_ = 0;

    // budget_rate_ in OXT/s, for now prepay_credit of 4s
    Budget_SurpTrack2(double budget_rate, double pay_interval = 4.0) { budget_rate_ = budget_rate; prepay_credit_ = budget_rate_ * pay_interval; }

    Budget_SurpTrack2(bytes32 account, double edate) {
        double curbal = Lot::balance(account).amount_;
        double sdate  = CurrentTime();
        budget_rate_  = curbal / (edate - sdate);
        prepay_credit_ = budget_rate_ * 4.0;
        dlog(1,"Budget_ST2(%x,%f) curbal(%f) budget_rate_(%f) \n", account,edate, curbal, budget_rate_);
    }

	virtual double get_max_faceval() { return max_faceval_; }

	virtual double get_afford(double ctime)
	{
	    double elap = (ctime - last_aff_date_);
	    last_aff_date_ = ctime;
	    double surplus_rate = surplus_ / (3*Days);
	    nxt_surplus_ = surplus_ - surplus_rate * elap;
	    double spendrate = budget_rate_ + surplus_rate;
	    double allowed   = active_*spendrate*elap + prepay_amt_;
        dlog(2,"Budget_ST2::get_afford(%f) allowed(%f) = %f*spendrate_(%f)*%f + %f  \n", ctime,allowed, active_,spendrate,elap,prepay_amt_);
	    return allowed;
	}

    virtual void on_payment(double ctime, double amt) {
        double elap = (ctime - last_pay_date_);
        last_pay_date_ = ctime;
        surplus_ = nxt_surplus_;
        double expected_amt = budget_rate_ * elap;
        surplus_ += (expected_amt - amt);
        prepay_amt_ = 0.0;
    }

    void on_connect(double ctime)    {
        dlog(2,"Budget_ST2::on_connect() ctime(%f) \n", ctime);
        last_aff_date_ = ctime; prepay_amt_ = prepay_credit_;
    }

    // if we get a new updated actual balance, the UI can call these functions to reduce variance and/or avoid overdrafts
    void set_budget(double balance, double time_remain) { budget_rate_ = balance/time_remain; }
    void set_budget_rate(double br) { budget_rate_ = br; }
    void set_active(double active) { active_ = active; }

};

struct Budget_SurpTrack : public IBudget, public Tickable
{
	double budget_edate_;   	    // target budget end date
	double max_faceval_		= 1.0;  // maximum allowable faceval in OXT (user's hard variance limit)
	double max_prepay_time_ = 4.0;   // max amount of time client will prepay (credit) to server for undelivered bandwidth, in seconds (client->server trust)

    // config hyperparams
	double timer_sample_rate_ = 20.0; // frequency of calls to on_timer() (nothing special about 20s)

	double prepay_credit_;
	double last_pay_date_  = 0.0;
	double spendrate_      = 0.0;
	bytes32 account_;

	double start_time_ 	  = 0.0;
	double start_balance_ = 0.0;


	virtual double get_afford(double ctime)
	{
	    double time_owed = (ctime - last_pay_date_);
	    double allowed   = spendrate_ * (time_owed + prepay_credit_);
        dlog(2,"Budget_ST::get_afford(%f) allowed(%f) = spendrate_(%f) * (%f - %f + %f) \n", ctime,allowed,spendrate_,ctime,last_pay_date_,prepay_credit_);
        return allowed;
	}


	virtual double get_max_faceval() { return max_faceval_; }

    virtual double step(double ctime) {
        double elap = Tickable::step(ctime);
    	double core_spendrate = start_balance_ / (budget_edate_ - start_time_);

        double curbal   = Lot::balance(account_).amount_;
        double expbal   = start_balance_ - core_spendrate * (ctime - start_time_);
        double surplus  = curbal - expbal;
        double surplus_spendrate = surplus / (3.0 * Days);

        spendrate_ = core_spendrate + surplus_spendrate;

        dlog(2,"Budget_ST::step(%f) spendrate_(%f) = core_spendrate(%f) + surplous_spendrate(%f) \n", ctime, spendrate_, core_spendrate, surplus_spendrate);
        dlog(2,"Budget_ST core = %f / (%f - %f)   surplus = (curbal(%f) - expbal(%f)) / (%f)   expbal = (%f - %f * (%f - %f)) \n", start_balance_,budget_edate_,start_time_,  curbal,expbal,3.0*Days,  start_balance_,core_spendrate,ctime,start_time_);
        return elap;
    }

    Budget_SurpTrack(bytes32 account, double budget_edate): account_(account), budget_edate_(budget_edate)
	{
        period_ = timer_sample_rate_;
        register_timer_func(this); // call on_timer() every {timer_sample_rate_} seconds

        start_time_    = CurrentTime();
        start_balance_ = Lot::balance(account_).amount_;

        step(CurrentTime()); // tick the timer once on startup to update for any time orchid was shutdown
    }

    virtual ~Budget_SurpTrack() {}

    void on_connect(double ctime)    {
        dlog(2,"Budget_ST::on_connect() ctime(%f) \n", ctime);
        last_pay_date_ = ctime; prepay_credit_ = max_prepay_time_;
    }

    void on_disconnect() { }
    virtual void on_payment(double ctime, double amt) { last_pay_date_ = ctime; prepay_credit_ = 0; }
    void set_active(double aratio) { }

};


struct Budget_PredExpW : public IBudget, public Tickable
{
	// budgeting params (input from UI)
	double budget_edate_;   	    // target budget end date
	double max_faceval_		= 1.0;  // maximum allowable faceval in OXT (user's hard variance limit)
	double max_prepay_time_ = 4.0;   // max amount of time client will prepay (credit) to server for undelivered bandwidth, in seconds (client->server trust)

    // config hyperparams
	double timer_sample_rate_ = 20.0; // frequency of calls to on_timer() (nothing special about 20s)

	double prepay_credit_;
	double last_pay_date_  = 0.0;
	double spendrate_      = 0.0;
	bytes32 account_;

    // internal
	bool   route_active_;                  // true when a connection/circuit is active
	double wactive_	= 0.1; // default to 2.4 hours / day of active VPN time
	double ltime_;
	double exp_half_life   = 1*Weeks;      // 1 one week 50% smoothing period


	virtual double get_afford(double ctime) {
	    double time_owed = (ctime - last_pay_date_);
	    double allowed   = spendrate_ * (time_owed + prepay_credit_);
	    dlog(2,"Budget_PredExpW::get_afford(%f) allowed(%f) = spendrate_(%f) * (%f - %f + %f) \n", ctime,allowed,spendrate_,ctime,last_pay_date_,prepay_credit_);
	    return allowed;
    }
    
	virtual double get_max_faceval() {
        return max_faceval_;
    }

    virtual double step(double ctime) {
        double elap = Tickable::step(ctime);
        double ltime    = ltime_; // persist_load("ltime", CurrentTime()); // load variable from persistent disk/DB/config, default to CurrentTime()
        double wactive  = wactive_; // persist_load("wactive", 1.0);

        // predict the fraction of time Orchid is active & connected (simple exp smoothing predictor) 
        double etime    = ctime - ltime;
        double decay    = exp(log(0.5) * etime/exp_half_life);        
        double cactive  = route_active_ ? 1.0 : 0.0;       
        wactive         = decay*wactive + (1-decay)*cactive;
        ltime           = ctime;
        
        dlog(2,"Budget_PredExpW::step(%f) wactive=%f = %f*%f + (1-%f)*%f ", ctime,wactive,decay,wactive,decay,cactive);


        double pred_future_active_time = (budget_edate_ - ctime) * wactive;
        double curbal   = Lot::balance(account_).amount_;
        double duration = pred_future_active_time + 1*Days;
        spendrate_      = curbal / duration;

        dlog(2," pfat = (%f-%f)*%f; spendrate_(%f) = %f / (%f + %f) \n", budget_edate_,ctime,wactive,  spendrate_,curbal,pred_future_active_time,1*Days);

        ltime_ 			= ltime; 	// persist_store("ltime",   ltime);
        wactive_ 		= wactive; // persist_store("wactive", wactive);
        return elap;
    }

    Budget_PredExpW(bytes32 account, double budget_edate): account_(account), budget_edate_(budget_edate), ltime_(CurrentTime()) {
        period_ = timer_sample_rate_;
        register_timer_func(this); // call on_timer() every {timer_sample_rate_} seconds
        route_active_ = false;
        step(CurrentTime()); // tick the timer once on startup to update for any time orchid was shutdown
    }
    
    virtual ~Budget_PredExpW() {}

    void on_connect(double ctime)    {
        dlog(2,"Budget_PredExpW::on_connect() ctime(%f) \n", ctime);
        route_active_ = true;  last_pay_date_ = ctime; prepay_credit_ = max_prepay_time_;
    }

    void on_disconnect() { route_active_ = false; }
    void on_payment()    { last_pay_date_ = CurrentTime(); prepay_credit_ = 0; }
	void set_active(double aratio) { route_active_ = aratio > 0.0; }

};


/*
 *
This simple client implmentation sends payments on a regular schedule every (period_) seconds (Tickable timer)
The amount of each payment is determined by the budget object

In sendpay(...) the client uses a simple method of determining how to split expected value between win_prob and face_val by using a fixed parameterized transaction fee overhead target.
(todo: this could later be outsourced to a more complex payment param optimizer thing)

This client also has a simple congestion control thing (for the sim, not really part of the protocol, todo refactor later)
 */
struct Client : public Tickable, public INet
{
	// budgeting params (input from UI or optimization stuff)
	double target_overhead_ = 0.1;	// target transaction fee overhead  // move to server?

	// Internal
	netaddr address_;
	bytes32 account_;

	struct Node
	{
	    netaddr 	address_ = {};
	    bytes32 	stakee_  = 0;
	    bytes32 	target_  = 0; // could be different from stakee_ . .?
	    uint256 	hash_secret_ = 0;
	    IBudget*	budget_ = nullptr;
	};
	vector<Node> 	route_; // client route information
	uint64 routehash_ = 0;


	double  brecvd_; // bytes received for the current connection
	double  active_ = 1.0;

	// packet id tracking and rate limit multiplr for simple congestion control
	uint32  last_recv_pac_id_ = 0;
	uint32  last_sent_pac_id_ = 0;
	double  rate_limit_mult_  = 1.0;
	double  packs_sent_ = 0;
	double  packs_recv_ = 0;


	void on_update_route();

	Client(bytes32 account, double budget_edate, int nhops) {
	    account_ = account;
	    address_ = netaddr{uint32(rand()), 0};
	    period_  = 4.0; register_timer_func(this); // send a payment every 4s for now
	    brecvd_  = 0.0;
	    route_.resize(nhops);
	    for (int i(0); i < nhops; i++) {
	        //route_[i].budget_ = new Budget_PredExpW(account_, budget_edate);
	        route_[i].budget_ = new Budget_SurpTrack2(account_, budget_edate);
		}
	    on_update_route();
	}

	virtual ~Client() { for (auto n : route_) delete n.budget_; }

	virtual netaddr get_netaddr() { return address_; }

    
	// External functions
	double get_trust_bound();  	// max OXT amount client is willing to lend to server (can initially be a large constant)


	void set_active(double active) { // set an activity ratio for budgeting  (0.0 idle, 1.0 full use)
		for (auto n : route_) n.budget_->set_active(active);
		active_ = active;
	}
    
    // callback when disconnected from route
	void on_disconnect()     { for (auto& n : route_) { n.budget_->on_disconnect(); n = Node(); } }

	//void on_payto(uint256 hash_secret, bytes32 target) { hash_secret_ = hash_secret; target_ = target;}
	//void sendpay(double ctime, uint256 hash_secret, bytes32 target);

	payment create_payment(double ctime, IBudget* budget, uint256 hash_secret, bytes32 target);


	void 	send_data(double ctime, netaddr dst, double ps);
	void 	send_payments(double ctime);
	void 	on_connect(double ctime, const vector<pair<netaddr,bytes32>>& route); 	// user initiates connection to server (random selection picks server)


	virtual void on_recv(netaddr to, netaddr from, const Packet& inpack, Payable_Msg* msg) {
		dlog(2,"Client::on_recv(%x,%x,Packet,Payable_Msg*)) \n", to.addr_, from.addr_);

		for (auto& node : route_) {
			if (node.address_.addr_ == msg->address_.addr_) {
				node.target_ = msg->target_;
				node.hash_secret_ = msg->hash_secret_;
			}
		}

	}


    virtual double step(double ctime) {
        dlog(2,"Client::step(%f)\n", ctime);
        double elap = Tickable::step(ctime);
        if (active_ > 0.0) send_payments(ctime);
        return elap;
    }

    void send_packet(netaddr to, netaddr from, Packet& p) {
		auto* msg = get_msg(p);
    	//if (msg == nullptr)
		packs_sent_ += 1.0;
    	if (last_sent_pac_id_ != last_recv_pac_id_) {
    		// last packet was dropped, downgrade rate control
    		rate_limit_mult_ = rate_limit_mult_*0.5;
    		dlog(2,"Client(%p)::send_packet(%i != %i) packs(%f,%f) rate_limit_mult_(%f) \n", this, last_sent_pac_id_,last_recv_pac_id_, packs_sent_,packs_recv_, rate_limit_mult_);
    	}
    	else {
    		rate_limit_mult_ = min(rate_limit_mult_*1.1, 1.0);
    		dlog(2,"Client(%p)::send_packet(%i == %i) packs(%f,%f) rate_limit_mult_(%f) \n", this, last_sent_pac_id_,last_recv_pac_id_, packs_sent_,packs_recv_, rate_limit_mult_);
    	}
    	p.size_ = p.size_ * rate_limit_mult_;
    	last_sent_pac_id_++;
    	p.id_   = last_sent_pac_id_;
    	net::send(to, from, p);
    }

	virtual void on_packet(netaddr to, netaddr from, const Packet& p)
	{
		auto* msg = get_msg(p);
		//if (msg == nullptr)
		if (last_recv_pac_id_ != get_id(p)) {
			last_recv_pac_id_ = get_id(p);
			packs_recv_ += 1.0;
		}
		auto psize = get_size(p);
		assert(to.addr_ == address_.addr_); brecvd_ += psize;
		dlog(2,"Client(%p)::on_packet  (%x,%x,%e,%d) packs(%f,%f) brecvd_(%f) ids(%i,%i) \n", this, to,from,psize,get_id(p), packs_sent_,packs_recv_, brecvd_, last_sent_pac_id_, last_recv_pac_id_);

		if (msg != nullptr) {
			msg->recv(to, from, p, this);
			del_msg(p);
		}
		else {
			//assert(p.routehash_ == routehash_);
		}
	}


	void print_info(int llevl, double ctime);

};


payment Client::create_payment(double ctime, IBudget* budget, uint256 hash_secret, bytes32 target)
{
	double afford	   	= budget->get_afford(ctime);
	double max_face_val	= budget->get_max_faceval();

	double exp_val 		= afford;
   	double trans_cost   = get_trans_cost();
	double face_val     = trans_cost / target_overhead_;
	//face_val      = min(face_val, max_face_val);
	//if (face_val > max_face_val) { assert(false); face_val = 0; }  // hard constraint failure }

	// todo: simulate server ticket value function?
	if (face_val > trans_cost) {
		double win_prob = exp_val / (face_val - trans_cost);
		if (win_prob >= 1.0) {
			win_prob = 1.0; face_val = exp_val + trans_cost;
			//printf("win_prob %f = %f / (%f - %f) \n ", win_prob, exp_val, face_val, trans_cost);
		}
		win_prob    	= max(min(win_prob, 1.0), 0.0); // todo: server may want a lower bound on win_prob for double-spend reasons
		// todo: is one hour duration (range) reasonable?
		bytes32 nonce 	= rand();
		double ratio 	= win_prob, start = CurrentTime(), range = 1.0*Hours, amount = face_val;
		bytes32 ticket 	= keccak256(encodePacked(hash_secret, target, nonce, ratio, start, range, amount));
		auto sig 		= sign(ticket, account_);
		budget->on_payment(ctime, win_prob * face_val);
		// any book-keeping here

		return payment{hash_secret, target,  nonce, account_, ratio, start, range, amount, sig};
	}
	else {
		// handle payment error, report to GUI, etc
		return payment{};
	}
}

inline int invidx(int i, int s) { return s - i - 1; }

void Client::send_data(double ctime, netaddr dst, double ps)
{
	dlog(2, "Client::send_data(%f) \n", ctime);

	Packet pack; pack.routehash_ = routehash_;
	pack.size_ = ps;
	netaddr targ;
	if (route_.size() > 0) targ = route_[0].address_;
	int rs = int(route_.size());
	pack.payersigs_.resize(rs); pack.fwds_.resize(rs); pack.msgs_.resize(rs);
	for (int i(0); i < rs; i++)
	{
		const Node& node = route_[i];
		auto sig  = sign( bytes32(), account_);
		pack.payersigs_[invidx(i,rs)] = sig;
		netaddr fwd;
		if (i+1 < route_.size()) fwd = route_[i+1].address_;
		else fwd = dst;
		pack.fwds_[invidx(i,rs)] = fwd;
		pack.msgs_[invidx(i,rs)] = nullptr; // Packet::Layer{node.address_, nmsg});
	}

	send_packet(targ, this->address_, pack);
}


void Client::send_payments(double ctime)
{
	dlog(2, "Client::send_payments(%f) \n", ctime);

	Packet pack; pack.routehash_ = routehash_;
	netaddr dst;
	if (route_.size() > 0) dst = route_[0].address_;
	int rs = int(route_.size());
	pack.payersigs_.resize(rs); pack.fwds_.resize(rs); pack.msgs_.resize(rs);
	for (int i(0); i < rs; i++)
	{
		const Node& node = route_[i];
		payment p = create_payment(ctime, node.budget_, node.hash_secret_, node.target_);
		//auto sig  = sign( keccak256(encodePacked(p)), account_);
		auto sig  = sign( bytes32(), account_);
		auto* nmsg = new Payment_Msg(node.stakee_, p);
		pack.payersigs_[invidx(i,rs)] = sig;
		netaddr fwd;
		if (i+1 < route_.size()) fwd = route_[i+1].address_;
		pack.fwds_[invidx(i,rs)] = fwd;
		pack.msgs_[invidx(i,rs)] = nmsg; // Packet::Layer{node.address_, nmsg});
	}

	send_packet(dst, this->address_, pack);
}



// user initiates connection to server (random selection picks server)
void Client::on_connect(double ctime, const vector<pair<netaddr,bytes32>>& route)
{
	dlog(1, "Client::on_connect(%f) \n", ctime);


	set<uint32> saddrs;

	brecvd_ = 0.0;
	rate_limit_mult_ = 1.0;
	last_recv_pac_id_ = 0;
	last_sent_pac_id_ = 0;

	assert(route.size() == route_.size());
	for (int i(0); i < int(route_.size()); i++) {
		auto saddr = route[i].first;
		assert(saddrs.find(saddr.addr_) == saddrs.end());
		saddrs.insert(saddr.addr_);
		route_[i].address_ = route[i].first; route_[i].stakee_ = route[i].second;
		route_[i].budget_->on_connect(ctime);
		dlog(2, "Client::on_connect route[%i] address_(%x) stakee_(%x) \n", i, route_[i].address_, route_[i].stakee_);
	}
	on_update_route();

	//send("connect", server);
	//server->on_connect(this, dst);
	//budget_->on_connect();
	//this->step(ctime); // run update immediately

	netaddr dst; if (route_.size() > 0) dst = route_[0].address_;

	for (int i(0); i < int(route_.size()); i++)
	{
		dlog(2, "  on_connect %i \n", i);

		Packet pack; pack.routehash_ = routehash_;
		int rs = i+1;
		pack.payersigs_.resize(rs); pack.fwds_.resize(rs); pack.msgs_.resize(rs);
		const Node& node = route_[i];
		{
			pack.msgs_[invidx(i,rs)] = new Connect_Msg(node.stakee_, account_);

			for (int j(0); j < rs-1; j++)
			{
				pack.fwds_[invidx(j,rs)]      = route_[j+1].address_;
				pack.payersigs_[invidx(j,rs)] = sign( bytes32(), account_);
				pack.msgs_[invidx(j,rs)]      = nullptr;
			}
			send_packet(dst, this->address_, pack); // this should immediately cause a Payable_Msg response
		}

		// now we can send a payment
		{
			payment p = create_payment(ctime, node.budget_, node.hash_secret_, node.target_);
			pack.msgs_[invidx(i,rs)] = new Payment_Msg(node.stakee_, p);

			for (int j(0); j < rs-1; j++)
			{
				pack.fwds_[invidx(j,rs)]      = route_[j+1].address_;
				pack.payersigs_[invidx(j,rs)] = sign( bytes32(), account_);
				pack.msgs_[invidx(j,rs)]      = nullptr;
			}
			send_packet(dst, this->address_, pack);
		}
	} // for (int i


}





/*
 *

This simple Server implementation conditionally forwards packets based on balance test, then bills the payer
It also charges seperate fees for queued and dropped packets

 *
 */
struct Server : public INet
{
	// Server Hyperparams - from a config file or something
	//double bytes_per_upay_;  // desired inv frequency of payments, in bytes
	//double data_price_;	  // server's OXT/byte price

	double res_price_ 	= 1e-11;	  	 // server's reserve(floor) OXT/byte price
	double que_price_	= 1e-10;		 // server's initial? congestion OXT/byte price for queued packets
	double drop_price_	= 1e-9;			 // server's initial? congestion OXT/byte price for dropped packets

	//double targ_balance_;    // target min client balance before invoice sent
	double min_balance_ = 0;     // min client balance to route packets (default 0)

	// Internal
	bytes32 account_;
	netaddr address_;
	//map<INet*, double> 	balances_;
	map<bytes32, double> 	balances_;
	map<double,  bytes32> 	old_tickets_;
	map<uint256, uint256> 	secrets_;

	struct PortEntry
	{
		netaddr to_, from_;
		bytes32 payer_;
	};
	map<uint64,  uint32>	route_to_port_;
	map<uint32,PortEntry>	port_to_entry_;
	uint32					next_port_ = 1;

	//map<netaddr, pair<netaddr,Client*>> routing_;
    


	Server() {
		account_       = rand();
		address_.addr_ = rand();
	}

	virtual ~Server() { }

	virtual netaddr get_netaddr() { return address_; }


	// client connection request
	/*
	void on_connect(Client* client, netaddr dst) {
		uint256 secret 		= rand();
		uint256 hash_secret = keccak256(secret);
		secrets_[hash_secret] = secret;
		client->on_payto(hash_secret, account_);
		//routing_[client->get_netaddr()] = pair<netaddr,Client*>(dst, client);
		//routing_[dst] = pair<netaddr,Client*>(client->get_netaddr(), client);
		// connection established, stuff happens		
	}
	*/

	// todo: remove sync ethnode RPC calls with async
	bool check_payment(payment p) { // validate the micropayment (does not verify it's a winner)
		if (Lot::balance(p.sender).amount_ <     p.amount) return false;
		if (Lot::balance(p.sender).escrow_ < 2 * p.amount) return false; // 2 is justin's magic number, and may change
		return true;
	}

	void grab(payment p, double trans_fee) {
		//function grab(uint256 secret, bytes32 hash, address payable target, uint256 nonce, uint256 ratio, uint256 start, uint128 range, uint128 amount, uint8 v, bytes32 r, bytes32 s, bytes32[] memory old)
		auto hash = p.hash_secret;
		auto secret = secrets_[hash];
		bytes32 ticket = keccak256(encodePacked(hash, p.target, p.nonce, p.ratio, p.start, p.range, p.amount));
		//old_tickets_.insert(ticket, p.start + p.range);
		vector<bytes32> old = {};
		/* while ((CurrentTime() + 1*Hour) > old_tickets.top().key()) {
			old.insert(old_tickets.pop());
		} */
		//RPC::transaction(trans_fee, grab(secret, hash, p.target, p.nonce, p.ratio, p.start, p.range, p.amount, p.sig, old));
		Lot::grab(secret, hash, p.target, p.nonce, p.ratio, p.start, p.range, p.amount, p.sig, old);
	}

	double ticket_value(payment p, double trans_fee) {
		auto val = (p.amount - trans_fee) * p.ratio;
		auto timestamp = CurrentTime() + 5*Minutes; // 5 minutes is roughly upper eth transaction delay
		double limit = val;
		if (p.start >= timestamp)
			limit = val;
		else
			limit = (val * (p.range - (timestamp - p.start)) / p.range);
		return limit;
	}
	

	// upayment from client
	void on_upay(payment p) { //  uses blocking external ethnode RPC calls

		dlog(2,"Server::on_upay(payment(%f,%f,%f,%f)) \n", p.ratio,p.amount, p.start,p.range);

		// todo: charge them cost of processing payment
		if (check_payment(p)) { // validate the micropayment
			auto trans_fee = get_trans_cost();
			double tv = ticket_value(p, trans_fee);
			dlog(2,"Server::on_upay balances_[%x]=%f += ticket_value(p,%f)=%f \n", p.sender, balances_[p.sender], trans_fee, tv);
			balances_[p.sender] += tv;
			auto secret = secrets_[p.hash_secret];
			if (is_winner(secret, p.nonce, p.ratio)) { // now check to see if it's a winner, and redeem if so
				grab(p, trans_fee);
			}
		}
	}

	
	void bill_packet(bytes32 account, double psize) {
		double amt = psize * res_price_;
		dlog(2,"Server::bill_packet(%x,%f) balances_[%x]=%f -= %f(%f*%f) \n", account,psize, account,balances_[account], amt,psize,res_price_);
		balances_[account] -= amt;
		//invoice_check(client);
	}

	void on_queued_packet(netaddr to, netaddr from, const Packet& p) {
		auto psize = get_size(p);
		bytes32 account = get_payer(p);
		double amt = psize * que_price_;
		dlog(2,"Server::on_queued_packet(%x,%x,%f) balances_[%x]=%f -= %f(%f * %f) \n", to,from,psize, account,balances_[account], amt,psize,que_price_);
		balances_[account] -= amt;
	}

	void on_dropped_packet(netaddr to, netaddr from, const Packet& p) {
		auto psize = get_size(p);
		bytes32 account = get_payer(p);
		double amt = psize * drop_price_;
		double ctime = CurrentTime();
		dlog(2,"Server::on_dropped_packet(%x,%x,%f) ctime(%f) balances_[%x]=%f -= %f(%f * %f) \n", to,from,psize, ctime, account,balances_[account], amt,psize,drop_price_);
		balances_[account] -= amt;
	}

	virtual void on_packet(netaddr to, netaddr from, const Packet& p_) {
		Packet p(p_);
		auto psize = get_size(p);
		assert(to.addr_ == address_.addr_);

		auto* msg = get_msg(p); // if there's a protocol message for us, handle it first

		dlog(3,"Server::on_packet  ([%x,%x],[%x,%x],%e)  msg(%p) \n", to.addr_,to.port_,from.addr_,from.port_,psize,msg);

		if (msg != nullptr && (msg->get_recipient() == account_)) {
			msg->recv(to, from, p, this);
			del_msg(p);
		}

		bytes32 payer = get_payer(p);
		if (payer != 0) // fwd packet - has a payer
		{
			assert(has_fwd(p));
			if (balances_[payer] > min_balance_) {
				dlog(3," Server::on_packet  ([%x,%x],[%x,%x],%e) payer(%x) balance:  %f > %f ", to.addr_,to.port_,from.addr_,from.port_,psize,payer,balances_[payer],min_balance_);
				netaddr dst = get_fwd(p);
				uint32 sendport = next_port_;
				if (route_to_port_.find(p.routehash_) == route_to_port_.end()) {
					route_to_port_[p.routehash_] = sendport;
					port_to_entry_[sendport] = PortEntry{to,from,payer};
					dlog(3," new routehash_(%x) -> sendport(%i) \n", p.routehash_, sendport);
					next_port_++;
				}
				else {
					sendport = route_to_port_[p.routehash_];
					auto pe = port_to_entry_[sendport];
					dlog(3," existing routehash_(%x) -> sendport(%i) pe([%x,%x],[%x,%x],%x) \n", p.routehash_, sendport, pe.to_.addr_,pe.to_.port_, pe.from_.addr_, pe.from_.port_, pe.payer_);
					assert(pe.to_ == to);
					assert(pe.from_ == from);
					assert(pe.payer_ == payer);
				}
				bill_packet(payer, psize);
				strip(p);
				net::send(dst, netaddr{address_.addr_, sendport}, p);
			} else {
				dlog(3," Server::on_packet  ([%x,%x],[%x,%x],%e) payer(%x) balance:  %f <= %f \n", to.addr_,to.port_,from.addr_,from.port_,psize,payer,balances_[payer],min_balance_);
			}
		}
		else if (to.port_ != 0) // inv packet, look it up
		{
			PortEntry pe = port_to_entry_[to.port_];
			netaddr dst = pe.from_;
			payer = pe.payer_;

			if (balances_[payer] > min_balance_) {
				dlog(3," Server::on_packet  ([%x,%x],[%x,%x],%e)  payer(%x) balance:  %f > %f  inv pe[%x,%x][%x,%x] \n", to.addr_,to.port_,from.addr_,from.port_,psize,payer, balances_[payer],min_balance_, pe.to_.addr_,pe.to_.port_,pe.from_.addr_,pe.from_.port_);
				bill_packet(payer, psize);
				//strip(p);
				net::send(dst, to, p);
			}
			else {
				dlog(3," Server::on_packet  ([%x,%x],[%x,%x],%e)  payer(%x) balance:  %f <= %f  inv pe[%x,%x][%x,%x] \n", to.addr_,to.port_,from.addr_,from.port_,psize,payer, balances_[payer],min_balance_, pe.to_.addr_,pe.to_.port_,pe.from_.addr_,pe.from_.port_);
			}
		}
	}



	virtual void on_recv(netaddr to, netaddr from, const Packet& ipack, Connect_Msg* msg)
	{
		dlog(2,"Server::on_recv(%x,%x,Packet,Connect_Msg*) \n", to.addr_, from.addr_);

		assert(msg != nullptr);
		uint256 secret 		  = rand();
		uint256 hash_secret   = keccak256(secret);
		secrets_[hash_secret] = secret;

		Packet opack; opack.id_ = ipack.id_; opack.size_ = ipack.size_;
		opack.msgs_ = { new Payable_Msg(msg->sender_, address_, account_, account_, hash_secret ) };
		net::send(from, to, opack);
	}

	virtual void on_recv(netaddr to, netaddr from, const Packet& ipack, Payment_Msg* msg)
	{
		assert(msg != nullptr);
		on_upay(msg->payment_);
		Packet opack; opack.id_ = ipack.id_; opack.size_ = ipack.size_;;
		net::send(from, to, opack);
	}

	void print_info(int llevl, double ctime, double stake, int nusers);

};






/*
 *

R < C

(Sa/S)*N*F*Tb < Sa*Ir

N*F*Tb < S*Ir

Tb < (S*Ir) / (N*F)

$10M / 1M*365*24


Tb < (R-Cb) / (N*F)

Tb < Pu / F

Tb < Pu * Dc



The happy asshole free equilibrium is one where the asshole strategy is unprofitable: the earnings of the strategy (registering stake but providing zero service) is less than the cost:
R < C

(Sa/S)*N*F*Tb < Sa*Ir

Sa: attacker stake fraction
Ir: interest rate
S: total stake
N: number of users
F: connection frequency
Tb: effective 'trust bound' - the amount attacker earns from a connection before they reroll

N*F*Tb < S*Ir

Tb < (S*Ir) / (N*F)

If we have 1 million users and $500M staked and 10% interest rates, S*Ir is $50M/yr.  IF the avg connection frequency is 1 hour, then:

Tb < $50M / 1M*365*24 = $0.0057

$0.0057 is quite large - on the order of a thousand micropayments (which is not a coincidence, with payments sent on the order of seconds and a few thousand seconds in an hour)

And actually, we can simplify the equation:


First we can replace (S*Ir) with (R-Cb), the profit over time:

Tb < (R-Cb) / (N*F)

Then we can substitute Pu = (R-Cb)/N, where Pu is the profit over time per user

Tb < Pu / F

And finally replace 1/F with D, the duration:

Tb < Pu * D

So in essence, as long as the typical connection session lasts much longer than the time it takes a user/client to reroll a bad connection, and the budgeting algorithm doesn't prepay too much, this attack should be unprofitable.


The earlier end simplified equation:
Tb < Pu * D
Tb: effective 'trust bound' - the amount attacker earns from a connection before they reroll
Pu: profit over time per user
D:  connection duration

Perhaps more clear formulated as:
Pu * Rt < Pu * D
Pu: profit over time per user
Rt: time until user rerolls a bad connection
D:  connection duration


*/




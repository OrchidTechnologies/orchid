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
typedef unsigned int bytes32;
typedef unsigned int uint256;
typedef unsigned int netaddr;


// ==================  Network Interface ==============================

void dlog(int level, const char* fmt, ...);


//struct packet;

// todo: replace
struct packet
{
	double 	size_;
	bytes32	payer_;
	vector<netaddr> route_;
	uint32  id_;
};


double 	get_size(const packet& p);
netaddr get_next(packet& p);
bytes32 get_payer(const packet& p);
uint32  get_id(const packet& p);


struct INet
{
	virtual ~INet() {}

	virtual netaddr get_netaddr() = 0;

	virtual void on_packet(			netaddr to, netaddr from, const packet& p){}
	virtual void on_dropped_packet(	netaddr to, netaddr from, const packet& p){}
	virtual void on_queued_packet( 	netaddr to, netaddr from, const packet& p){}

};

namespace net
{
	void send(netaddr to, netaddr from, const packet& p);
	void add(INet* net, double ibw, double obw);
}



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
bytes32 sign(bytes32 x, bytes32 y);


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
			bytes32 sender = sig;
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


// ==================  Time and Tickable (event simulation) ==============================


double CurrentTime();

struct ITickable
{
	virtual ~ITickable() {}
    virtual void step(double ctime) = 0;
    virtual double next_step_time() = 0;
};

void register_timer_func(ITickable* p);


struct Tickable : public ITickable
{
	virtual ~Tickable() {}

	double period_ = 1.0;
	double next_   = 0.0;

    virtual void step(double ctime) {
    	next_ = ctime + period_;
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
    virtual void on_connect() = 0;
    virtual void on_disconnect() = 0;
    virtual void on_invoice() = 0;
	virtual void set_active(double aratio) = 0;
};

struct Budget_PredExpW : public IBudget, public Tickable
{
	// budgeting params (input from UI)
	double budget_edate_;   	    // target budget end date
	double max_faceval_		= 1.0;  // maximum allowable faceval in OXT (user's hard variance limit)
	double max_prepay_time_ = 4.0;   // max amount of time client will prepay (credit) to server for undelivered bandwidth, in seconds (client->server trust)

    // config hyperparams
	double timer_sample_rate_ = 20.0; // frequency of calls to on_timer() (nothing special about 20s)

    // internal
	double wactive_	= 0.1; // default to 2.4 hours / day of active VPN time

	double prepay_credit_;
	bool   route_active_;                  // true when a connection/circuit is active
	double exp_half_life   = 1*Weeks;      // 1 one week 50% smoothing period
	double last_pay_date_;
	double spendrate_ = 0;
	bytes32 account_;
	double ltime_;


	virtual double get_afford(double ctime) {
		double time_owed = (ctime - last_pay_date_);
		double allowed   = spendrate_ * (time_owed + prepay_credit_);
        dlog(2,"Budget_PredExpW::get_afford(%f) allowed(%f) = spendrate_(%f) * (%f - %f + %f) ", ctime,allowed,spendrate_,ctime,last_pay_date_,prepay_credit_);
        return allowed;
    }
    
	virtual double get_max_faceval() {
        return max_faceval_;
    }

    void step(double ctime) {
    	Tickable::step(ctime);
    
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
    }

    Budget_PredExpW(bytes32 account, double budget_edate): account_(account), budget_edate_(budget_edate), ltime_(CurrentTime()) {
    	period_ = timer_sample_rate_;
        register_timer_func(this); // call on_timer() every {timer_sample_rate_} seconds
        route_active_ = false;
        step(CurrentTime()); // tick the timer once on startup to update for any time orchid was shutdown
    }
    
    void on_connect()    { route_active_ = true;  last_pay_date_ = CurrentTime(); prepay_credit_ = max_prepay_time_; }
    void on_disconnect() { route_active_ = false; }
    void on_invoice()    { last_pay_date_ = CurrentTime(); prepay_credit_ = 0; }
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
	bytes32 account_;
	double last_pay_date_ = CurrentTime();
	IBudget* budget_;
	Server* server_;
	netaddr address_;

	uint256 hash_secret_;
	bytes32 target_ = 0;

	double  brecvd_; // bytes received for the current connection

	// packet id tracking and rate limit multiplr for simple congestion control
	uint32  last_recv_pac_id_ = 0;
	uint32  last_sent_pac_id_ = 0;
	double  rate_limit_mult_  = 1.0;
	double  packs_sent_ = 0;
	double  packs_recv_ = 0;

	Client(bytes32 account, double budget_edate) {
		account_ = account;
		address_ = rand();
		budget_  = new Budget_PredExpW(account_, budget_edate);
		period_  = 4.0; register_timer_func(this); // send a payment every 4s for now

		brecvd_ = 0.0;
	}

	virtual ~Client() { delete budget_; }

	virtual netaddr get_netaddr() { return address_; }

    
	// External functions
	double get_trust_bound();  	// max OXT amount client is willing to lend to server (can initially be a large constant)

	// user initiates connection to server (random selection picks server)
	void on_connect(double ctime, Server* server, netaddr dst);

	void set_active(double aratio) { // set an activity ratio for budgeting  (0.0 idle, 1.0 full use)
		budget_->set_active(aratio);
	}
    
    // callback when disconnected from route
	void on_disconnect()     { budget_->on_disconnect(); }

	void on_payto(uint256 hash_secret, bytes32 target) { hash_secret_ = hash_secret; target_ = target;}
	void sendpay(double ctime, uint256 hash_secret, bytes32 target);

    void step(double ctime) {
		dlog(2,"Client::step(%f)\n", ctime);
    	Tickable::step(ctime);
    	assert(target_ != 0);
    	sendpay(ctime, hash_secret_, target_);
    }

    void send_packet(netaddr to, netaddr from, packet p) {
    	packs_sent_ += 1.0;
    	if (last_sent_pac_id_ != last_recv_pac_id_) {
    		// last packet was dropped, downgrade rate control
    		rate_limit_mult_ = rate_limit_mult_*0.5;
    		dlog(2,"Client::send_packet(%x != %x) rate_limit_mult_(%f) \n", last_sent_pac_id_, last_recv_pac_id_, rate_limit_mult_);
    	}
    	else {
    		rate_limit_mult_ = min(rate_limit_mult_*1.1, 1.0);
    		dlog(2,"Client::send_packet(%x == %x) rate_limit_mult_(%f) \n", last_sent_pac_id_, last_recv_pac_id_, rate_limit_mult_);
    	}
    	p.size_ = p.size_ * rate_limit_mult_;
    	last_sent_pac_id_++;
    	p.id_   = last_sent_pac_id_;
    	net::send(to, from, p);
    }

	virtual void on_packet(netaddr to, netaddr from, const packet& p)
	{
    	packs_recv_ += 1.0;
		last_recv_pac_id_ = get_id(p);
		auto psize = get_size(p);
		assert(to == address_); brecvd_ += psize;
		dlog(2,"Client::on_packet  (%x,%x,%e,%d) brecvd_(%f) \n", to,from,psize,get_id(p),brecvd_);
	}


	void print_info(int llevl, double ctime);

};


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
	map<double, bytes32> 	old_tickets_;
	map<uint256, uint256> 	secrets_;

	//map<netaddr, pair<netaddr,Client*>> routing_;
    


	Server() {
		account_ = rand();
		address_ = rand();
	}

	virtual ~Server() { }

	virtual netaddr get_netaddr() { return address_; }


	// client connection request
	void on_connect(Client* client, netaddr dst) {
		uint256 secret 		= rand();
		uint256 hash_secret = keccak256(secret);
		secrets_[hash_secret] = secret;
		client->on_payto(hash_secret, account_);
		//routing_[client->get_netaddr()] = pair<netaddr,Client*>(dst, client);
		//routing_[dst] = pair<netaddr,Client*>(client->get_netaddr(), client);
		// connection established, stuff happens		
	}

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
	void on_upay(Client* client, payment p) { //  uses blocking external ethnode RPC calls

		dlog(2,"Server::on_upay(%p,payment(%f,%f,%f,%f)) \n", client, p.ratio,p.amount, p.start,p.range);

		// todo: charge them cost of processing payment
		if (check_payment(p)) { // validate the micropayment
			auto trans_fee = get_trans_cost();
			double tv = ticket_value(p, trans_fee);
			dlog(2,"Server::on_upay balances_[%x]=%f += ticket_value(p,%f)=%f \n", client->account_, balances_[client->account_], trans_fee, tv);
			balances_[client->account_] += tv;
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

	void on_queued_packet(netaddr to, netaddr from, const packet& p) {
		auto psize = get_size(p);
		bytes32 account = get_payer(p);
		double amt = psize * que_price_;
		dlog(2,"Server::on_queued_packet(%x,%x,%f) balances_[%x]=%f -= %f(%f * %f) \n", to,from,psize, account,balances_[account], amt,psize,que_price_);
		balances_[account] -= amt;
	}

	void on_dropped_packet(netaddr to, netaddr from, const packet& p) {
		auto psize = get_size(p);
		bytes32 account = get_payer(p);
		double amt = psize * drop_price_;
		dlog(2,"Server::on_dropped_packet(%x,%x,%f) balances_[%x]=%f -= %f(%f * %f) \n", to,from,psize, account,balances_[account], amt,psize,drop_price_);
		balances_[account] -= amt;
	}

	virtual void on_packet(netaddr to, netaddr from, const packet& p_) { // inc data from client out to target
		packet p(p_);
		auto psize = get_size(p);
		assert(to == address_);
		bytes32 account = get_payer(p);
		if (balances_[account] > min_balance_) {
			dlog(3,"Server::on_packet  (%x,%x,%e) client(%x) balance:  %f > %f \n", to,from,psize,account,balances_[account],min_balance_);
			bill_packet(account, psize);
			net::send(get_next(p), address_, p);
		} else {
			dlog(3,"Server::on_packet  (%x,%x,%e) client(%x) balance:  %f <= %f \n", to,from,psize,account,balances_[account],min_balance_);
		}
	}


	void print_info(int llevl, double ctime, double stake);


};



// user initiates connection to server (random selection picks server)
void Client::on_connect(double ctime, Server* server, netaddr dst) {
	target_ = 0;
	brecvd_ = 0.0;
	rate_limit_mult_ = 1.0;
	server_ = server;
	//send("connect", server);
	server->on_connect(this, dst);
	budget_->on_connect();
	this->step(ctime); // run update immediately
}



void Client::sendpay(double ctime, uint256 hash_secret, bytes32 target)
{
	double afford	   	= budget_->get_afford(ctime);
	double max_face_val	= budget_->get_max_faceval();

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
		//send("upay", server_, payment{hash_secret, target,  nonce, ratio, start, range, amount, sig} );
		server_->on_upay(this, payment{hash_secret, target,  nonce, account_, ratio, start, range, amount, sig});
		budget_->on_invoice();
		// any book-keeping here
	}
	else {
		// handle payment error, report to GUI, etc
	}
}


/*
void Client::on_invoice(uint256 hash_secret, bytes32 target, double bal_owed, double trans_cost) { // server requests payment from client

	double afford	   	= budget_->get_afford();
	double max_face_val	= budget_->get_max_faceval();

	// todo: add back client side balance of trade tracking for trust bound

	//trust_bound 	= get_trust_bound();
	//exp_val     	= min(afford, bal_owed, trust_bound); // moved into budgeting
	double exp_val 		= min(afford, bal_owed);
   	trans_cost  		= min(get_max_trans_cost(), trans_cost);
	double face_val     = trans_cost / target_overhead_;
	//face_val      = min(face_val, max_face_val);
	if (face_val > max_face_val) face_val = 0;  // hard constraint failure

	// todo: simulate server ticket value function?
	if (face_val > trans_cost) {
		double win_prob = exp_val / (face_val - trans_cost);
		win_prob    	= max(min(win_prob, 1.0), 0.0); // todo: server may want a lower bound on win_prob for double-spend reasons
		// todo: is one hour duration (range) reasonable?
		bytes32 nonce = rand();
		double ratio = win_prob, start = CurrentTime(), range = 1.0*Hours, amount = face_val;
		bytes32 ticket = keccak256(encodePacked(hash_secret, target, nonce, ratio, start, range, amount));
		auto sig = sign(ticket);
		//send("upay", server_, payment{hash_secret, target,  nonce, ratio, start, range, amount, sig} );
		server_->on_upay(this, payment{hash_secret, target,  nonce, account_, ratio, start, range, amount, sig});
		budget_->on_invoice();
		// any book-keeping here
	}
	else {
		// handle payment error
	}
}
*/




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




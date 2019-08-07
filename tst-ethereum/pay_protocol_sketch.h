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



/*



struct Client
{

	// budgeting params (input from UI)
	budget_time_;   	// remaining time we want our balance to last
	target_overhead_ = 0.1;	// target transaction fee overhead  // move to server?

	// eth/system inputs (from some oracle)
	trans_cost_;	// in OXT

	// auto derived upay params
	winProb_;
	faceVal_;

	server_;
	elapsed_;
	totbytes_;
	balance_; 		// actual pot balance (shadowed)

	expBalance_;		// expected, micro-payment balance (amount owed from server to client)
	minBalance_;		// min expected balance, below which we send a new micropayment

	on_connect(address);  	// user initiates connection to server
	on_connected(server);	// server connection response
	on_winner(payment);	// server notifies client on winning ticket (needed for rate control)
	on_in_packets(data);    // on inc data from server
	on_out_packets(data);   // on out data to   server

	GetAvgDataRate() {	// this could be smarter?  Avg data rate over all of time
		return (totbytes_ / GetTotElapsedTime());
	}

	// user initiates connection to server
	on_connect(server) 	 { send("connect", server, ...); }


	get_budget_balance() { 
		spendrate = balance_ / budget_time_; // simple dumb bad budgeting
		allowed = spendrate * ElapsedTime();
		return allowed;
	};

	// server connection response
	on_connected(server)  {
		server_ = server; balance_ = elapsed_ = expBalance_ = 0;

		afford 	    = get_budget_balance();
		trust_bound = get_trust_bound();
		exp_value   = min(afford, server_.exp_value_, trust_bound);

		// init micropay params
		faceVal_	= trans_cost_ / target_overhead_; // todo: move to server
		winProb_	= exp_value / (faceVal_ - trans_cost_);
	}

	// server notifies client on winning ticket (needed for rate control)
	on_winner(payment)  {

		balance_   -= payment.faceVal;

		afford 	    = get_budget_balance();
		trust_bound = get_trust_bound();
		exp_value   = min(afford, server_.exp_value_, trust_bound);

		// dyn adjust of faceVal rather than winprob (important)
		faceVal_    = exp_value / winProb_; // todo: subject to server minFaceVal
	}

	on_in_packets(data)  {    // inc data from server
		expBalance_ -= size(data) * server_.data_price_;
		totbytes_   += size(data);
	}

	on_out_packets(data)  {    // out data to server
		expBalance_ -= size(data) * server_.data_price_;
		totbytes_   += size(data);
	}

	on_invoice(bal_owed) {
		
		afford 	    = get_budget_balance();
		trust_bound = get_trust_bound();
		exp_value   = min(afford, bal_owed, trust_bound);

		// dyn adjust of faceVal rather than winprob (important)
		faceVal_    = exp_value / winProb_; // todo: subject to server minFaceVal		
		send("upay", server_, payment{winProb_, faceVal_, ..} );
	}


	update(etime)
	{
		elapsed_     += etime;
		budget_time_ -= etime;

		// todo: move to server, request
		minBalance_  = server_.bytesPerUpay_ * (server_.data_price_);

		if (expBalance_ < minBalance_) {
			send("upay", server_, payment{winProb_, faceVal_, ..} );
			expBalance_ += winProb_ * faceVal_;
		}
	}

};


struct Server
{
	// Server Hyperparams - from a config file or something
	// upay_freq_;	// desired frequency of micropayments, in hertz
	bytesPerUpay_;  // desired inv frequency of micropayments, in bytes
	data_price_;	// server's OXT/byte price

	// Internal
	balances_;
	iconn_map_;
	oconn_map_;


	on_connect(client);		// client connection request
	on_upay(client, payment);	// upayment from client
	on_out_packets(src, data);	// inc data from client out to target
	on_in_packets(src, data);       // inc data from target out to client


	// client connection request
	on_connect(client) {
		send("connected", client, { bytesPerUpay_, data_price_ ... } );
	}

	OnlinePaymentCheck(payment) { // validate the micropayment (does not verify it's a winner)
		if (RPC.balance(payment.sender).amount_ <     payment.faceVal)) return false;
		if (RPC.balance(payment.sender).escrow_ < 2 * payment.faceVal)) return false;
	}

	IsWinner(payment); // offline check to see if ticket is a winner

	// upayment from client
	on_upay(client, payment) { //  uses blocking external ethnode RPC calls
		if (OnlinePaymentCheck(payment)) { // validate the micropayment
			balances_[client] += payment.faceVal * payment.winProb;
			if (IsWinner(payment) { // now check to see if it's a winner, and redeem if so
				RPC.grab(payment);
				send("winner", client, payment);
			}
		}
	}

	on_out_packets(src, data) {	// inc data from client out to target
		client = iconn_map_[src];
		cost   = data.size_ * data_price_;
		balances[client] -= cost;
		if (balances[client] > 0) {
			send(client.target, data);
		}
	}

	on_in_packets(src, data) {   // inc data from target out to client
		client = oconn_map_[src];
		cost   = data.size_ * data_price_;
		balances[client] -= cost;
		if (balances[client] > 0) {
			send(client, data);
		}
	}

};




 *
 *
*/




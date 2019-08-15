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
	budget_time_;   		// remaining time we want our balance to last
	target_overhead_ = 0.1;	// target transaction fee overhead

	// eth/system inputs (from some oracle)
	trans_cost_;	// in OXT

	// auto derived upay params
	winProb_;
	faceVal_;

	server_;
	elapsed_;
	balance_; 		// pot balance (shadowed)

	on_connect(address);  	// user initiates connection to server
	on_connected(server);	// server connection response
	on_winner(payment);		// server notifies client on winning ticket (needed for rate control)


	// user initiates connection to server
	on_connect(server) 	 { send("connect", server, ...); }

	// server connection response
	on_connected(server)  {
		server_ = server; balance_ = elapsed_ = 0;

		spendrate 		= balance_ / budget_time_;
		upay_interval 	= 1.0 / server_.upay_freq_;
		exp_value 		= spendrate * upay_interval;

		// init micropay params
		faceVal_		= trans_cost_ / target_overhead_;
		winProb_		= exp_value / faceVal_;
	}

	// server notifies client on winning ticket (needed for rate control)
	on_winner(payment)
	{
		balance_ 	   -= payment.faceVal;
		spendrate 		= balance_ / budget_time_;
		upay_interval 	= 1.0 / server_.upay_freq_;
		exp_value 		= spendrate * upay_interval;

		// dyn adjust of faceVal rather than winprob (important)
		faceVal_ 		= exp_value / winProb_;
	}

	update(etime)
	{
		elapsed_ 	 += etime;
		budget_time_ -= etime;
		upay_interval = 1.0 / server_.upay_freq_;

		while (elapsed_ > upay_interval) {
			send("upay", server_, payment{winProb_, faceVal_, ..} );
			elapsed_ -= upay_interval;
		}
	}

};


struct Server
{
	// Server Hyperparams - from a config file or something
	upay_freq_;		// requested max frequency of micropayments, in hertz
	data_price_;	// server's OXT/byte price

	// Internal
	balances_;
	iconn_map_;
	oconn_map_;


	on_connect(client);			// client connection request
	on_upay(client, payment);	// upayment from client
	on_out_packets(src, data);	// inc data from client out to target
	on_in_packets(src, data);   // inc data from target out to client


	// client connection request
	on_connect(client) {
		send("connected", client, {upay_freq_, ...} );
	}

	OnlinePaymentCheck(payment) { // validate the micropayment (does not verify it's a winner)
		if (RPC.balance(payment.sender).amount_ < 	  payment.faceVal)) return false;
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




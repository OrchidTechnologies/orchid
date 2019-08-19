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
	budget_edate_;   	    // target budget end date
	target_overhead_ = 0.1;	// target transaction fee overhead  // move to server?

    // Internal
    last_pay_date_ = CurrentTime();

    // External functions
    get_trans_cost();   // get current transaction cost estimate
    get_OXT_balance();  // external eth balance 
    get_trust_bound();  // max OXT amount client is willing to lend to server

    // Protocol server message handlers
	on_invoice(bal_owed);   // server requests payment from client


	// user initiates connection to server
	on_connect(server) 	 { send("connect", server, ...); }

    
    // replace with more sophisticated budgeting
	get_budget_afford() {
		spendrate = get_OXT_balance() / (budget_edate_ - CurrentTime()); // simple dumb bad budgeting
		allowed = spendrate * (CurrentTime() - last_pay_date);
		return allowed;
	};


	on_invoice(bal_owed) {
		
		afford 	    = get_budget_afford();
		trust_bound = get_trust_bound();
		exp_val     = min(afford, bal_owed, trust_bound);

        trans_cost  = get_trans_cost();
		face_val	= trans_cost / target_overhead_;
		win_prob    = exp_val / (face_val - trans_cost);

		send("upay", server_, payment{win_prob, face_val, ..} );

		last_pay_date_ = CurrentTime();
	}

};


struct Server
{
	// Server Hyperparams - from a config file or something
	bytes_per_upay_;  // desired inv frequency of micropayments, in bytes
	data_price_;	  // server's OXT/byte price
	targ_balance_;    // target min client balance before invoice sent (server->client trust bound)
	min_balance_;     // min client balance to route packets

	// Internal
	balances_;

    // External functions
    get_trans_cost();    // get current transaction cost estimate
	is_winner(payment);  // offline check to see if ticket is a winner

    // Protocol client message handlers
	on_connect(client);		    // client connection request
	on_upay(client, payment);	// upayment from client

    // On packet data event handlers
	on_out_packets(src, data);	// inc data from client out to target
	on_in_packets(src, data);   // inc data from target out to client


    invoice_check(client) {
		if (balances[client] <= targ_balance_) {
		    billed_amt  = max(bytes_per_upay_ * data_price_, targ_balance_ - balances[client]);
		    send("invoice", client, billed_amt);
		}
    }


	// client connection request
	on_connect(client) {
	    invoice_check(client);
	}

	check_payment(payment) { // validate the micropayment (does not verify it's a winner)
		if (RPC.balance(payment.sender).amount_ <     payment.faceVal)) return false;
		if (RPC.balance(payment.sender).escrow_ < 2 * payment.faceVal)) return false;
	}


	// upayment from client
	on_upay(client, payment) { //  uses blocking external ethnode RPC calls
		if (check_payment(payment)) { // validate the micropayment
			balances_[client] += (payment.faceVal - get_trans_cost()) * payment.winProb;
			if (is_winner(payment) { // now check to see if it's a winner, and redeem if so
				RPC.grab(payment);
				send("winner", client, payment);
			}
		}
	}
	
	bill_packet(data) {
		cost   = data.size_ * data_price_;
		balances[client] -= cost;
	    invoice_check(client);
	}

	on_out_packets(client, data) {	// inc data from client out to target
		bill_packet(data);
		if (balances[client] > min_balance_) { send(client.target, data); }
	}

	on_in_packets(client, data) {   // inc data from target out to client
		bill_packet(data);
		if (balances[client] > min_balance_) { send(client, data); }
	}

};




 *
 *
*/




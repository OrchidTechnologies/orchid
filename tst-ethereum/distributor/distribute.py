import os
import sys

#export WEB3_INFURA_PROJECT_ID=aca6dac91cf34aadb23005b60d38b603
os.environ['WEB3_INFURA_PROJECT_ID'] = 'aca6dac91cf34aadb23005b60d38b603'
from web3.auto.infura import w3

import web3.exceptions
import time
import requests


token_abi = [{"inputs": [], "payable": False, "stateMutability": "nonpayable", "type": "constructor"}, {"anonymous": False, "inputs": [{"indexed": True, "internalType": "address", "name": "owner", "type": "address"}, {"indexed": True, "internalType": "address", "name": "spender", "type": "address"}, {"indexed": False, "internalType": "uint256", "name": "value", "type": "uint256"} ], "name": "Approval", "type": "event"}, {"anonymous": False, "inputs": [{"indexed": True, "internalType": "address", "name": "from", "type": "address"}, {"indexed": True, "internalType": "address", "name": "to", "type": "address"}, {"indexed": False, "internalType": "uint256", "name": "value", "type": "uint256"} ], "name": "Transfer", "type": "event"}, {"constant": True, "inputs": [{"internalType": "address", "name": "owner", "type": "address"}, {"internalType": "address", "name": "spender", "type": "address"} ], "name": "allowance", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "spender", "type": "address"}, {"internalType": "uint256", "name": "amount", "type": "uint256"} ], "name": "approve", "outputs": [{"internalType": "bool", "name": "", "type": "bool"} ], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "account", "type": "address"} ], "name": "balanceOf", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": True, "inputs": [], "name": "decimals", "outputs": [{"internalType": "uint8", "name": "", "type": "uint8"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "spender", "type": "address"}, {"internalType": "uint256", "name": "subtractedValue", "type": "uint256"} ], "name": "decreaseAllowance", "outputs": [{"internalType": "bool", "name": "", "type": "bool"} ], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "spender", "type": "address"}, {"internalType": "uint256", "name": "addedValue", "type": "uint256"} ], "name": "increaseAllowance", "outputs": [{"internalType": "bool", "name": "", "type": "bool"} ], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [], "name": "name", "outputs": [{"internalType": "string", "name": "", "type": "string"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": True, "inputs": [], "name": "symbol", "outputs": [{"internalType": "string", "name": "", "type": "string"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": True, "inputs": [], "name": "totalSupply", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "recipient", "type": "address"}, {"internalType": "uint256", "name": "amount", "type": "uint256"} ], "name": "transfer", "outputs": [{"internalType": "bool", "name": "", "type": "bool"} ], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "sender", "type": "address"}, {"internalType": "address", "name": "recipient", "type": "address"}, {"internalType": "uint256", "name": "amount", "type": "uint256"} ], "name": "transferFrom", "outputs": [{"internalType": "bool", "name": "", "type": "bool"} ], "payable": False, "stateMutability": "nonpayable", "type": "function"} ];

lottery_abi = [{"inputs": [{"internalType": "contract IERC20", "name": "token", "type": "address"} ], "payable": False, "stateMutability": "nonpayable", "type": "constructor"}, {"anonymous": False, "inputs": [{"indexed": True, "internalType": "address", "name": "funder", "type": "address"}, {"indexed": True, "internalType": "address", "name": "signer", "type": "address"}, {"indexed": False, "internalType": "uint128", "name": "amount", "type": "uint128"}, {"indexed": False, "internalType": "uint128", "name": "escrow", "type": "uint128"}, {"indexed": False, "internalType": "uint256", "name": "unlock", "type": "uint256"} ], "name": "Update", "type": "event"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "contract OrchidVerifier", "name": "verify", "type": "address"}, {"internalType": "bytes", "name": "shared", "type": "bytes"} ], "name": "bind", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "address payable", "name": "target", "type": "address"}, {"internalType": "uint128", "name": "amount", "type": "uint128"}, {"internalType": "bytes", "name": "receipt", "type": "bytes"} ], "name": "give", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "bytes32", "name": "seed", "type": "bytes32"}, {"internalType": "bytes32", "name": "hash", "type": "bytes32"}, {"internalType": "bytes32", "name": "nonce", "type": "bytes32"}, {"internalType": "uint256", "name": "start", "type": "uint256"}, {"internalType": "uint128", "name": "range", "type": "uint128"}, {"internalType": "uint128", "name": "amount", "type": "uint128"}, {"internalType": "uint128", "name": "ratio", "type": "uint128"}, {"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "address payable", "name": "target", "type": "address"}, {"internalType": "bytes", "name": "receipt", "type": "bytes"}, {"internalType": "uint8", "name": "v", "type": "uint8"}, {"internalType": "bytes32", "name": "r", "type": "bytes32"}, {"internalType": "bytes32", "name": "s", "type": "bytes32"}, {"internalType": "bytes32[]", "name": "old", "type": "bytes32[]"} ], "name": "grab", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"} ], "name": "keys", "outputs": [{"internalType": "address[]", "name": "", "type": "address[]"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "bytes32", "name": "ticket", "type": "bytes32"} ], "name": "kill", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"} ], "name": "lock", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "address", "name": "signer", "type": "address"} ], "name": "look", "outputs": [{"internalType": "uint128", "name": "", "type": "uint128"}, {"internalType": "uint128", "name": "", "type": "uint128"}, {"internalType": "uint256", "name": "", "type": "uint256"}, {"internalType": "contract OrchidVerifier", "name": "", "type": "address"}, {"internalType": "bytes", "name": "", "type": "bytes"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "uint128", "name": "amount", "type": "uint128"} ], "name": "move", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "uint256", "name": "offset", "type": "uint256"}, {"internalType": "uint256", "name": "count", "type": "uint256"} ], "name": "page", "outputs": [{"internalType": "address[]", "name": "", "type": "address[]"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "address payable", "name": "target", "type": "address"} ], "name": "pull", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "address payable", "name": "target", "type": "address"}, {"internalType": "uint128", "name": "amount", "type": "uint128"} ], "name": "pull", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "uint128", "name": "total", "type": "uint128"}, {"internalType": "uint128", "name": "escrow", "type": "uint128"} ], "name": "push", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "uint256", "name": "offset", "type": "uint256"} ], "name": "seek", "outputs": [{"internalType": "address", "name": "", "type": "address"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"} ], "name": "size", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"} ], "name": "warn", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [], "name": "what", "outputs": [{"internalType": "contract IERC20", "name": "", "type": "address"} ], "payable": False, "stateMutability": "view", "type": "function"} ];

distributor_abi = [{"inputs":[{"internalType":"contract IERC20","name":"token","type":"address"}],"payable":False,"stateMutability":"nonpayable","type":"constructor"},{"constant":True,"inputs":[{"internalType":"address","name":"a","type":"address"}],"name":"compute_owed","outputs":[{"internalType":"uint128","name":"","type":"uint128"}],"payable":False,"stateMutability":"view","type":"function"},{"constant":True,"inputs":[{"internalType":"address","name":"a","type":"address"},{"internalType":"uint256","name":"t","type":"uint256"}],"name":"compute_owed_","outputs":[{"internalType":"uint128","name":"","type":"uint128"}],"payable":False,"stateMutability":"view","type":"function"},{"constant":False,"inputs":[],"name":"distribute_all","outputs":[],"payable":False,"stateMutability":"nonpayable","type":"function"},{"constant":False,"inputs":[{"internalType":"uint256","name":"N","type":"uint256"}],"name":"distribute_partial","outputs":[],"payable":False,"stateMutability":"nonpayable","type":"function"},{"constant":False,"inputs":[{"internalType":"address","name":"rec","type":"address"},{"internalType":"uint256","name":"idx","type":"uint256"},{"internalType":"uint256","name":"beg","type":"uint256"},{"internalType":"uint256","name":"end","type":"uint256"},{"internalType":"uint128","name":"amt","type":"uint128"}],"name":"update","outputs":[],"payable":False,"stateMutability":"nonpayable","type":"function"},{"constant":True,"inputs":[],"name":"what","outputs":[{"internalType":"contract IERC20","name":"","type":"address"}],"payable":False,"stateMutability":"view","type":"function"}]

test_account = w3.eth.account.create('test')
print(f"test_account.address: {test_account.address} ");
print(f"test_account.privateKey: {test_account.privateKey.hex()} ");


print("Creating Token contract object from abi.");
Token = w3.eth.contract(abi=token_abi)

print("Creating Distributor contract object from abi.");
Distributor = w3.eth.contract(abi=distributor_abi)

distributor_main = Distributor(address = '0x3d971E78e9F5390d4AF4be8EDd88bCCD9040c75E')

def update(rec, idx, beg, end, amt, funder_pubkey, funder_privkey, nonce):

    #function update(address rec, uint idx, uint beg, uint end, uint128 amt) public {

	txn = distributor_main.functions.update(rec, idx, beg, end, w3.toWei(amt, 'ether')
		).buildTransaction({'chainId': 1, 'from': funder_pubkey, 'gas': 350000, 'gasPrice': w3.toWei('8', 'gwei'), 'nonce': nonce,}
	)

	print(f"Funder signed transaction:");
	txn_signed = w3.eth.account.sign_transaction(txn, private_key=funder_privkey)
	print(txn_signed);

	print(f"Submitting transaction:");
	txn_hash = w3.eth.sendRawTransaction(txn_signed.rawTransaction);
	print(f"Submitted transaction with hash: {txn_hash.hex()}");

	owed_wei = distributor_main.functions.compute_owed(rec).call();
	owed = w3.fromWei(owed_wei, 'ether');
	print(f"owed to {rec} : {owed}");

def send(funder_pubkey, funder_privkey):

	print("Distributor functions:");
	print( Distributor.all_functions() )

	token_address = '0x4575f41308EC1483f3d399aa9a2826d74Da13Deb'
	token_main = Token(address = '0x4575f41308EC1483f3d399aa9a2826d74Da13Deb')
	#distributor_main = Distributor(address = '0x3d971E78e9F5390d4AF4be8EDd88bCCD9040c75E')

	#funder.privateKey

	nonce = w3.eth.getTransactionCount(funder_pubkey);
	print(f"Funder nonce: {nonce}");

	k0 = funder_pubkey;
	k1 = funder_privkey;
	n  = nonce;

	rec = '0x25A20D9bd3e69a4c20E636F2679F2a19f595dA25';

	owed_wei = distributor_main.functions.compute_owed_(rec, 1485279353).call(); owed = w3.fromWei(owed_wei, 'ether');
	print(f"owed to {rec} at 1485279353 : {owed}");

	owed_wei = distributor_main.functions.compute_owed_(rec, 1585279353).call(); owed = w3.fromWei(owed_wei, 'ether');
	print(f"owed to {rec} at 1585279353 : {owed}");

	owed_wei = distributor_main.functions.compute_owed_(rec, 1595277426).call(); owed = w3.fromWei(owed_wei, 'ether');
	print(f"owed to {rec} at 1595277426 : {owed}");

	owed_wei = distributor_main.functions.compute_owed_(rec, 1716813426).call(); owed = w3.fromWei(owed_wei, 'ether');
	print(f"owed to {rec} at 1716813426 : {owed}");

	#update('0x25A20D9bd3e69a4c20E636F2679F2a19f595dA25', 0, 1585277426, 1616813426, 1.0, k0,k1,n);


def main():

	if len(sys.argv) > 1 :
		#signer = sys.argv[1];
		send(sys.argv[1], sys.argv[2])
	else :
		print("usage: distribute.py FUNDER_PUBKEY FUNDER_PRIVKEY ");


if __name__ == "__main__":
    main()

import os
import sys
import json

os.environ['WEB3_INFURA_PROJECT_ID'] = 'aca6dac91cf34aadb23005b60d38b603'
from web3.auto.infura import w3

import web3.exceptions

test_account = w3.eth.account.create('test')
print(f"test_account.address: {test_account.address} ");
print(f"test_account.privateKey: {test_account.privateKey.hex()} ");


def deploy(funder_pubkey, funder_privkey, contract, args):

	print(f"deploying {contract} funder_pubkey: {funder_pubkey}, funder_privkey: {funder_privkey} ");

	print("Loading bytecode and abi.");
	contract_bin  = open(contract + '.bin', 'r').read();
	contract_abi_ = open(contract + '.abi', 'r');

	contract_abi = json.load(contract_abi_);

	print(contract_abi);
	print(contract_bin);

	Contract = w3.eth.contract(abi=contract_abi, bytecode=contract_bin);

	print("Contract functions:");
	print( Contract.all_functions() )


	nonce = w3.eth.getTransactionCount(funder_pubkey);
	print(f"Funder nonce: {nonce}");

	'''
	print(f"Assembling transaction:");
	txn = Contract.functions.constructor(args[5]).buildTransaction(
		{'chainId': 1, 'from': funder_pubkey, 'gas': 50000, 'gasPrice': w3.toWei('8', 'gwei'), 'nonce': nonce,}
	);
	print(txn);

	'''
	print("Building Contract constructor() transaction...");
	# Submit the transaction that deploys the contract
	txn = Contract.constructor(args[4]).buildTransaction({'chainId': 1, 'from': funder_pubkey, 'gas': 1500000, 'gasPrice': w3.toWei('8', 'gwei'), 'nonce': nonce,});
	print(txn);

	print(f"Funder signed transaction:");
	signed_txn = w3.eth.account.sign_transaction(txn, private_key=funder_privkey)
	print(signed_txn);

	txn_hash = w3.eth.sendRawTransaction(signed_txn.rawTransaction);
	print(f"Submitted transaction with hash: {txn_hash.hex()}");

	# Wait for the transaction to be mined, and get the transaction receipt
	print("Waiting for tx_receipt...");
	tx_receipt = w3.eth.waitForTransactionReceipt(txn_hash);
	print(tx_receipt);


def main():

	if len(sys.argv) > 3 :
		deploy(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv);
	else :
		print("usage: deploy_contract.py FUNDER_PUBKEY FUNDER_PRIVKEY CONTRACT ARGS...");


if __name__ == "__main__":
    main()



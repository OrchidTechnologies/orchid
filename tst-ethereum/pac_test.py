import os
import sys
from inapppy import AppStoreValidator, InAppPyValidationError

os.environ['WEB3_INFURA_PROJECT_ID'] = 'aca6dac91cf34aadb23005b60d38b603'
from web3.auto.infura import w3

import web3.exceptions
import time
import requests


token_abi = [{"inputs": [], "payable": False, "stateMutability": "nonpayable", "type": "constructor"}, {"anonymous": False, "inputs": [{"indexed": True, "internalType": "address", "name": "owner", "type": "address"}, {"indexed": True, "internalType": "address", "name": "spender", "type": "address"}, {"indexed": False, "internalType": "uint256", "name": "value", "type": "uint256"} ], "name": "Approval", "type": "event"}, {"anonymous": False, "inputs": [{"indexed": True, "internalType": "address", "name": "from", "type": "address"}, {"indexed": True, "internalType": "address", "name": "to", "type": "address"}, {"indexed": False, "internalType": "uint256", "name": "value", "type": "uint256"} ], "name": "Transfer", "type": "event"}, {"constant": True, "inputs": [{"internalType": "address", "name": "owner", "type": "address"}, {"internalType": "address", "name": "spender", "type": "address"} ], "name": "allowance", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "spender", "type": "address"}, {"internalType": "uint256", "name": "amount", "type": "uint256"} ], "name": "approve", "outputs": [{"internalType": "bool", "name": "", "type": "bool"} ], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "account", "type": "address"} ], "name": "balanceOf", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": True, "inputs": [], "name": "decimals", "outputs": [{"internalType": "uint8", "name": "", "type": "uint8"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "spender", "type": "address"}, {"internalType": "uint256", "name": "subtractedValue", "type": "uint256"} ], "name": "decreaseAllowance", "outputs": [{"internalType": "bool", "name": "", "type": "bool"} ], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "spender", "type": "address"}, {"internalType": "uint256", "name": "addedValue", "type": "uint256"} ], "name": "increaseAllowance", "outputs": [{"internalType": "bool", "name": "", "type": "bool"} ], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [], "name": "name", "outputs": [{"internalType": "string", "name": "", "type": "string"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": True, "inputs": [], "name": "symbol", "outputs": [{"internalType": "string", "name": "", "type": "string"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": True, "inputs": [], "name": "totalSupply", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "recipient", "type": "address"}, {"internalType": "uint256", "name": "amount", "type": "uint256"} ], "name": "transfer", "outputs": [{"internalType": "bool", "name": "", "type": "bool"} ], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "sender", "type": "address"}, {"internalType": "address", "name": "recipient", "type": "address"}, {"internalType": "uint256", "name": "amount", "type": "uint256"} ], "name": "transferFrom", "outputs": [{"internalType": "bool", "name": "", "type": "bool"} ], "payable": False, "stateMutability": "nonpayable", "type": "function"} ];
lottery_abi = [{"inputs": [{"internalType": "contract IERC20", "name": "token", "type": "address"} ], "payable": False, "stateMutability": "nonpayable", "type": "constructor"}, {"anonymous": False, "inputs": [{"indexed": True, "internalType": "address", "name": "funder", "type": "address"}, {"indexed": True, "internalType": "address", "name": "signer", "type": "address"}, {"indexed": False, "internalType": "uint128", "name": "amount", "type": "uint128"}, {"indexed": False, "internalType": "uint128", "name": "escrow", "type": "uint128"}, {"indexed": False, "internalType": "uint256", "name": "unlock", "type": "uint256"} ], "name": "Update", "type": "event"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "contract OrchidVerifier", "name": "verify", "type": "address"}, {"internalType": "bytes", "name": "shared", "type": "bytes"} ], "name": "bind", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "address payable", "name": "target", "type": "address"}, {"internalType": "uint128", "name": "amount", "type": "uint128"}, {"internalType": "bytes", "name": "receipt", "type": "bytes"} ], "name": "give", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "bytes32", "name": "seed", "type": "bytes32"}, {"internalType": "bytes32", "name": "hash", "type": "bytes32"}, {"internalType": "bytes32", "name": "nonce", "type": "bytes32"}, {"internalType": "uint256", "name": "start", "type": "uint256"}, {"internalType": "uint128", "name": "range", "type": "uint128"}, {"internalType": "uint128", "name": "amount", "type": "uint128"}, {"internalType": "uint128", "name": "ratio", "type": "uint128"}, {"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "address payable", "name": "target", "type": "address"}, {"internalType": "bytes", "name": "receipt", "type": "bytes"}, {"internalType": "uint8", "name": "v", "type": "uint8"}, {"internalType": "bytes32", "name": "r", "type": "bytes32"}, {"internalType": "bytes32", "name": "s", "type": "bytes32"}, {"internalType": "bytes32[]", "name": "old", "type": "bytes32[]"} ], "name": "grab", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"} ], "name": "keys", "outputs": [{"internalType": "address[]", "name": "", "type": "address[]"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "bytes32", "name": "ticket", "type": "bytes32"} ], "name": "kill", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"} ], "name": "lock", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "address", "name": "signer", "type": "address"} ], "name": "look", "outputs": [{"internalType": "uint128", "name": "", "type": "uint128"}, {"internalType": "uint128", "name": "", "type": "uint128"}, {"internalType": "uint256", "name": "", "type": "uint256"}, {"internalType": "contract OrchidVerifier", "name": "", "type": "address"}, {"internalType": "bytes", "name": "", "type": "bytes"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "uint128", "name": "amount", "type": "uint128"} ], "name": "move", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "uint256", "name": "offset", "type": "uint256"}, {"internalType": "uint256", "name": "count", "type": "uint256"} ], "name": "page", "outputs": [{"internalType": "address[]", "name": "", "type": "address[]"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "address payable", "name": "target", "type": "address"} ], "name": "pull", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "address payable", "name": "target", "type": "address"}, {"internalType": "uint128", "name": "amount", "type": "uint128"} ], "name": "pull", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "uint128", "name": "total", "type": "uint128"}, {"internalType": "uint128", "name": "escrow", "type": "uint128"} ], "name": "push", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "uint256", "name": "offset", "type": "uint256"} ], "name": "seek", "outputs": [{"internalType": "address", "name": "", "type": "address"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"} ], "name": "size", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"} ], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"} ], "name": "warn", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [], "name": "what", "outputs": [{"internalType": "contract IERC20", "name": "", "type": "address"} ], "payable": False, "stateMutability": "view", "type": "function"} ];

test_account = w3.eth.account.create('AbsoluteHenryFalcon78')

test_receipt = [{"download_id": 0, "receipt_creation_date_ms": "1486371475000", "application_version": "2", "app_item_id": 0, "receipt_creation_date": "2017-02-06 08:57:55 Etc/GMT", "original_purchase_date": "2013-08-01 07:00:00 Etc/GMT", "request_date_pst": "2017-02-06 04:41:09 America/Los_Angeles", "original_application_version": "1.0", "original_purchase_date_pst": "2013-08-01 00:00:00 America/Los_Angeles", "request_date_ms": "1486384869996", "bundle_id": "com.yourcompany.yourapp", "request_date": "2017-02-06 12:41:09 Etc/GMT", "original_purchase_date_ms": "1375340400000", "in_app": [{"purchase_date_ms": "1486371474000", "web_order_line_item_id": "1000000034281189", "original_purchase_date_ms": "1486371475000", "original_purchase_date": "2017-02-06 08:57:55 Etc/GMT", "expires_date_pst": "2017-02-06 01:00:54 America/Los_Angeles", "original_purchase_date_pst": "2017-02-06 00:57:55 America/Los_Angeles", "purchase_date_pst": "2017-02-06 00:57:54 America/Los_Angeles", "expires_date_ms": "1486371654000", "expires_date": "2017-02-06 09:00:54 Etc/GMT", "original_transaction_id": "1000000271014363", "purchase_date": "2017-02-06 08:57:54 Etc/GMT", "quantity": "1", "is_trial_period": "false", "product_id": "com.yourcompany.yourapp", "transaction_id": "1000000271014363"}], "version_external_identifier": 0, "receipt_creation_date_pst": "2017-02-06 00:57:55 America/Los_Angeles", "adam_id": 0, "receipt_type": "ProductionSandbox"}]

#print(f"test_account.address: {test_account.address} ");
#print(f"test_account.privateKey: {test_account.privateKey.hex()} ");

#test_pubkey = '0xCA9E026D96829f5805B14Fb8223db4a0822D72a7';
#funder_privkey = b'I\x02\xa0\xfa\xb8m\\\xf5\xfc\x1d\xd6\xf2\xb2\xe0j\xb7\xd8\x97\x1c\x99g=iF\x9f =\xb59\xf0O\xdc';
#test_privkey = '0x64a31b5a2cd7d11cfd349cb52408b98b8d9c4161fa3f914929913791e49a4a93';

def get_usd_per_oxt():
	r = requests.get(url = "https://api.coinbase.com/v2/prices/OXT-USD/spot");
	data = r.json();
	print(data);
	usd_per_oxt = float(data['data']['amount']);
	print("usd_per_oxt: {usd_per_oxt}")
	return usd_per_oxt;

def fund_PAC_(signer, total, escrow, funder_pubkey, funder_privkey):


	print(f"Funding PAC  signer: {signer}, total: {total}, escrow: {escrow} ");

	print("Creating Token contract object from abi.");
	Token = w3.eth.contract(abi=token_abi)

	print("Creating Lottery contract object from abi.");
	Lottery = w3.eth.contract(abi=lottery_abi)

	print("Lottery functions:");
	print( Lottery.all_functions() )

	lottery_address = '0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1'
	token_main = Token(address = '0x4575f41308EC1483f3d399aa9a2826d74Da13Deb')
	lottery_main = Lottery(address = lottery_address)


	#funder.privateKey

	#nonce = w3.eth.getTransactionCount('0x464e537a24C76887599a9a9F96cE56d14505f93A')

	nonce = w3.eth.getTransactionCount(funder_pubkey);
	print(f"Funder nonce: {nonce}");

	print(f"Assembling approve transaction:");
	approve_txn = token_main.functions.approve(lottery_address, total
		).buildTransaction({'chainId': 1, 'from': funder_pubkey, 'gas': 50000, 'gasPrice': w3.toWei('8', 'gwei'), 'nonce': nonce,}
	)
	print(approve_txn);

	print(f"Funder signed transaction:");
	approve_txn_signed = w3.eth.account.sign_transaction(approve_txn, private_key=funder_privkey)
	print(approve_txn_signed);

	print(f"Submitting approve transaction:");	

	txn_hash = w3.eth.sendRawTransaction(approve_txn_signed.rawTransaction);
	print(f"Submitted transaction with hash: {txn_hash.hex()}");

	"""
	txn_receipt = None
	count = 0
	while txn_receipt is None and (count < 30):
		try:
			txn_receipt = w3.eth.getTransactionReceipt(txn_hash)
		except web3.exceptions.TransactionNotFound:
			time.sleep(10)

	print(txn_receipt)
	if txn_receipt is None:
		print("Failed to get txn receipt!");
	"""


	nonce = nonce + 1;
	print(f"Funder nonce: {nonce}");

	print(f"Assembling funding transaction:");
	funding_txn = lottery_main.functions.push(signer, total, escrow
		).buildTransaction({'chainId': 1, 'from': funder_pubkey, 'gas': 200000, 'gasPrice': w3.toWei('8', 'gwei'), 'nonce': nonce,}
	)
	print(funding_txn);

	print(f"Funder signed transaction:");
	funding_txn_signed = w3.eth.account.sign_transaction(funding_txn, private_key=funder_privkey)
	print(funding_txn_signed);

	print(f"Submitting funding transaction:");
	txn_hash = w3.eth.sendRawTransaction(funding_txn_signed.rawTransaction);
	print(f"Submitted transaction with hash: {txn_hash.hex()}");


def fund_PAC(signer, total_usd, funder_pubkey, funder_privkey):

	escrow_usd = 2;
	if (total_usd < 4):
		escrow_usd = 0.5 * total_usd

	usd_per_oxt = get_usd_per_oxt();
	oxt_per_usd = 1.0 / usd_per_oxt;

	total_oxt = total_usd * usd_per_oxt;
	escrow_oxt = escrow_usd * usd_per_oxt;

	print(f"Funding PAC  signer: {signer}, total: ${total_usd} {total_oxt}oxt, escrow: ${escrow_usd} {escrow_oxt}oxt ");

	fund_PAC_(signer, w3.toWei(total_oxt, 'ether'), w3.toWei(escrow_oxt, 'ether'), funder_pubkey, funder_privkey);


def process_app_pay_receipt(receipt, total_usd, shared_secret = None):

	bundle_id = 'com.yourcompany.yourapp'
	auto_retry_wrong_env_request=False # if True, automatically query sandbox endpoint if
	                                   # validation fails on production endpoint
	validator = AppStoreValidator(bundle_id="com.yourcompany.yourapp", sandbox=False, auto_retry_wrong_env_request=auto_retry_wrong_env_request)

	try:
	    exclude_old_transactions=False # if True, include only the latest renewal transaction
	    print("Validating AppStore Receipt:");
	    validation_result = validator.validate(receipt = receipt, shared_secret = shared_secret, exclude_old_transactions=exclude_old_transactions)
	except InAppPyValidationError as ex:
	    # handle validation error
	    response_from_apple = ex.raw_response  # contains actual response from AppStore service.
	    print("validation failure:");
	    print(response_from_apple);
	    return False;

	return True;

def main():

	if len(sys.argv) > 5 :
		signer = sys.argv[1];
		total_usd = sys.argv[2];
		funder_pubkey = sys.argv[3];
		funder_privkey = sys.argv[4];
		receipt = sys.argv[5];
		if (process_app_pay_receipt(receipt, total_usd)):
			fund_PAC(signer, float(total_usd), funder_pubkey, funder_privkey)
	else :
		print("usage: pac_test.py SIGNER TOTAL_USD FUNDER_PUBKEY FUNDER_PRIVKEY RECEIPT");


if __name__ == "__main__":
    main()



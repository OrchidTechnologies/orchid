import boto3
import json
import os
import requests
import sha3
import time  # noqa: F401
import web3.exceptions  # noqa: F401

from ecdsa import SigningKey, SECP256k1
from inapppy import AppStoreValidator, InAppPyValidationError
from typing import Any, Dict, Tuple
from web3.auto.infura import w3


client = boto3.client('ssm')


def get_secret(key: str) -> str:
    resp: dict = client.get_parameter(
        Name=key,
        WithDecryption=True,
    )
    return resp['Parameter']['Value']

token_abi = [{"inputs": [], "payable": False, "stateMutability": "nonpayable", "type": "constructor"}, {"anonymous": False, "inputs": [{"indexed": True, "internalType": "address", "name": "owner", "type": "address"}, {"indexed": True, "internalType": "address", "name": "spender", "type": "address"}, {"indexed": False, "internalType": "uint256", "name": "value", "type": "uint256"}], "name": "Approval", "type": "event"}, {"anonymous": False, "inputs": [{"indexed": True, "internalType": "address", "name": "from", "type": "address"}, {"indexed": True, "internalType": "address", "name": "to", "type": "address"}, {"indexed": False, "internalType": "uint256", "name": "value", "type": "uint256"}], "name": "Transfer", "type": "event"}, {"constant": True, "inputs": [{"internalType": "address", "name": "owner", "type": "address"}, {"internalType": "address", "name": "spender", "type": "address"}], "name": "allowance", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "spender", "type": "address"}, {"internalType": "uint256", "name": "amount", "type": "uint256"}], "name": "approve", "outputs": [{"internalType": "bool", "name": "", "type": "bool"}], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "account", "type": "address"}], "name": "balanceOf", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": True, "inputs": [], "name": "decimals", "outputs": [{"internalType": "uint8", "name": "", "type": "uint8"}], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "spender", "type": "address"}, {"internalType": "uint256", "name": "subtractedValue", "type": "uint256"}], "name": "decreaseAllowance", "outputs": [{"internalType": "bool", "name": "", "type": "bool"}], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "spender", "type": "address"}, {"internalType": "uint256", "name": "addedValue", "type": "uint256"}], "name": "increaseAllowance", "outputs": [{"internalType": "bool", "name": "", "type": "bool"}], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [], "name": "name", "outputs": [{"internalType": "string", "name": "", "type": "string"}], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": True, "inputs": [], "name": "symbol", "outputs": [{"internalType": "string", "name": "", "type": "string"}], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": True, "inputs": [], "name": "totalSupply", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "recipient", "type": "address"}, {"internalType": "uint256", "name": "amount", "type": "uint256"}], "name": "transfer", "outputs": [{"internalType": "bool", "name": "", "type": "bool"}], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "sender", "type": "address"}, {"internalType": "address", "name": "recipient", "type": "address"}, {"internalType": "uint256", "name": "amount", "type": "uint256"}], "name": "transferFrom", "outputs": [{"internalType": "bool", "name": "", "type": "bool"}], "payable": False, "stateMutability": "nonpayable", "type": "function"}]  # noqa: E501
lottery_abi = [{"inputs": [{"internalType": "contract IERC20", "name": "token", "type": "address"}], "payable": False, "stateMutability": "nonpayable", "type": "constructor"}, {"anonymous": False, "inputs": [{"indexed": True, "internalType": "address", "name": "funder", "type": "address"}, {"indexed": True, "internalType": "address", "name": "signer", "type": "address"}, {"indexed": False, "internalType": "uint128", "name": "amount", "type": "uint128"}, {"indexed": False, "internalType": "uint128", "name": "escrow", "type": "uint128"}, {"indexed": False, "internalType": "uint256", "name": "unlock", "type": "uint256"}], "name": "Update", "type": "event"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "contract OrchidVerifier", "name": "verify", "type": "address"}, {"internalType": "bytes", "name": "shared", "type": "bytes"}], "name": "bind", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "address payable", "name": "target", "type": "address"}, {"internalType": "uint128", "name": "amount", "type": "uint128"}, {"internalType": "bytes", "name": "receipt", "type": "bytes"}], "name": "give", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "bytes32", "name": "seed", "type": "bytes32"}, {"internalType": "bytes32", "name": "hash", "type": "bytes32"}, {"internalType": "bytes32", "name": "nonce", "type": "bytes32"}, {"internalType": "uint256", "name": "start", "type": "uint256"}, {"internalType": "uint128", "name": "range", "type": "uint128"}, {"internalType": "uint128", "name": "amount", "type": "uint128"}, {"internalType": "uint128", "name": "ratio", "type": "uint128"}, {"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "address payable", "name": "target", "type": "address"}, {"internalType": "bytes", "name": "receipt", "type": "bytes"}, {"internalType": "uint8", "name": "v", "type": "uint8"}, {"internalType": "bytes32", "name": "r", "type": "bytes32"}, {"internalType": "bytes32", "name": "s", "type": "bytes32"}, {"internalType": "bytes32[]", "name": "old", "type": "bytes32[]"}], "name": "grab", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}], "name": "keys", "outputs": [{"internalType": "address[]", "name": "", "type": "address[]"}], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "bytes32", "name": "ticket", "type": "bytes32"}], "name": "kill", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}], "name": "lock", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "address", "name": "signer", "type": "address"}], "name": "look", "outputs": [{"internalType": "uint128", "name": "", "type": "uint128"}, {"internalType": "uint128", "name": "", "type": "uint128"}, {"internalType": "uint256", "name": "", "type": "uint256"}, {"internalType": "contract OrchidVerifier", "name": "", "type": "address"}, {"internalType": "bytes", "name": "", "type": "bytes"}], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "uint128", "name": "amount", "type": "uint128"}], "name": "move", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "uint256", "name": "offset", "type": "uint256"}, {"internalType": "uint256", "name": "count", "type": "uint256"}], "name": "page", "outputs": [{"internalType": "address[]", "name": "", "type": "address[]"}], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "address payable", "name": "target", "type": "address"}], "name": "pull", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "address payable", "name": "target", "type": "address"}, {"internalType": "uint128", "name": "amount", "type": "uint128"}], "name": "pull", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}, {"internalType": "uint128", "name": "total", "type": "uint128"}, {"internalType": "uint128", "name": "escrow", "type": "uint128"}], "name": "push", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}, {"internalType": "uint256", "name": "offset", "type": "uint256"}], "name": "seek", "outputs": [{"internalType": "address", "name": "", "type": "address"}], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": True, "inputs": [{"internalType": "address", "name": "funder", "type": "address"}], "name": "size", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}], "payable": False, "stateMutability": "view", "type": "function"}, {"constant": False, "inputs": [{"internalType": "address", "name": "signer", "type": "address"}], "name": "warn", "outputs": [], "payable": False, "stateMutability": "nonpayable", "type": "function"}, {"constant": True, "inputs": [], "name": "what", "outputs": [{"internalType": "contract IERC20", "name": "", "type": "address"}], "payable": False, "stateMutability": "view", "type": "function"}]  # noqa: E501


def get_usd_per_oxt() -> float:
    r = requests.get(url="https://api.coinbase.com/v2/prices/OXT-USD/spot")
    data = r.json()
    print(data)
    usd_per_oxt = float(data['data']['amount'])
    print(f"usd_per_oxt: {usd_per_oxt}")
    return usd_per_oxt


def fund_PAC_(
    signer: str,
    total: float,
    escrow: float,
    funder_pubkey: str,
    funder_privkey: str,
) -> str:
    print(f"Funding PAC  signer: {signer}, total: {total}, escrow: {escrow} ")

    lottery_addr = w3.toChecksumAddress(os.environ['LOTTERY'])
    token_addr = w3.toChecksumAddress(os.environ['TOKEN'])
    verifier_addr = w3.toChecksumAddress(os.environ['VERIFIER'])

    lottery_main = w3.eth.contract(
        abi=lottery_abi,
        address=lottery_addr,
    )
    token_main = w3.eth.contract(
        abi=token_abi,
        address=token_addr,
    )

    print(f"Getting nonce for funder_pubkey: {funder_pubkey}")
    nonce = w3.eth.getTransactionCount(account=funder_pubkey)
    print(f"Funder nonce: {nonce}")

    print(f"Assembling approve transaction:")
    approve_txn = token_main.functions.approve(
        lottery_addr,
        total,
    ).buildTransaction(
        {
            'chainId': 1,
            'from': funder_pubkey,
            'gas': 50000,
            'gasPrice': w3.toWei('8', 'gwei'),
            'nonce': nonce,
        }
    )
    print(approve_txn)

    print(f"Funder signed transaction:")
    approve_txn_signed = w3.eth.account.sign_transaction(
        approve_txn, private_key=funder_privkey)
    print(approve_txn_signed)

    print(f"Submitting approve transaction:")

    approve_txn_hash = w3.eth.sendRawTransaction(
        approve_txn_signed.rawTransaction)
    print(f"Submitted approve transaction with hash: {approve_txn_hash.hex()}")

    nonce = nonce + 1
    print(f"Funder nonce: {nonce}")

    print(f"Assembling bind transaction:")
    bind_txn = lottery_main.functions.bind(signer, verifier_addr, w3.toBytes(0)
        ).buildTransaction({'chainId': 1, 'from': funder_pubkey, 'gas': 200000, 'gasPrice': w3.toWei('8', 'gwei'), 'nonce': nonce,}
    )
    print(bind_txn)

    print(f"Funder signed transaction:")
    bind_txn_signed = w3.eth.account.sign_transaction(bind_txn, private_key=funder_privkey)
    print(bind_txn_signed)

    print(f"Submitting bind transaction:")
    bind_txn_hash = w3.eth.sendRawTransaction(bind_txn_signed.rawTransaction)
    print(f"Submitted bind transaction with hash: {bind_txn_hash.hex()}")

    nonce = nonce + 1
    print(f"Funder nonce: {nonce}")

    print(f"Assembling funding transaction:")
    funding_txn = lottery_main.functions.push(
        signer,
        total,
        escrow
    ).buildTransaction(
        {
            'chainId': 1,
            'from': funder_pubkey,
            'gas': 200000,
            'gasPrice': w3.toWei('8', 'gwei'),
            'nonce': nonce,
        }
    )
    print(funding_txn)

    print(f"Funder signed transaction:")
    funding_txn_signed = w3.eth.account.sign_transaction(
        funding_txn, private_key=funder_privkey)
    print(funding_txn_signed)

    print(f"Submitting funding transaction:")
    txn_hash: str = w3.eth.sendRawTransaction(
        funding_txn_signed.rawTransaction).hex()
    print(f"Submitted funding transaction with hash: {txn_hash}")
    return txn_hash


def fund_PAC(signer, total_usd, funder_pubkey, funder_privkey) -> str:
    escrow_usd = 2
    if (total_usd < 4):
        escrow_usd = 0.5 * total_usd

    usd_per_oxt = get_usd_per_oxt()
    oxt_per_usd = 1.0 / usd_per_oxt;

    total_oxt = total_usd * oxt_per_usd
    escrow_oxt = escrow_usd * oxt_per_usd

    print(
        f"Funding PAC  signer: {signer}, \
total: ${total_usd}{total_oxt} oxt, \
escrow: ${escrow_usd} {escrow_oxt}oxt")

    txn_hash = fund_PAC_(signer, w3.toWei(total_oxt, 'ether'), w3.toWei(
        escrow_oxt, 'ether'), funder_pubkey, funder_privkey)
    return txn_hash


def process_app_pay_receipt(
    receipt,
    total_usd,
    shared_secret=None
) -> Tuple[bool, dict]:
    bundle_id = 'OrchidTechnologies.PAC-Test'
    # if True, automatically query sandbox endpoint
    # if validation fails on production endpoint
    if os.environ['AUTO_RETRY_WRONG_ENV_REQUEST'] == 'True':
        auto_retry_wrong_env_request = True
    else:
        auto_retry_wrong_env_request = False
    validator = AppStoreValidator(
        bundle_id=bundle_id,
        sandbox=os.environ['RECEIPT_SANDBOX'] == 'True',
        auto_retry_wrong_env_request=auto_retry_wrong_env_request,
    )
    try:
        # if True, include only the latest renewal transaction
        exclude_old_transactions = False
        print("Validating AppStore Receipt:")
        validation_result: Dict[Any, Any] = validator.validate(
            receipt=receipt,
            shared_secret=shared_secret,
            exclude_old_transactions=exclude_old_transactions
        )
        print(f'Validation Result: {validation_result}')
    except InAppPyValidationError as ex:
        # handle validation error
        # contains actual response from AppStore service.
        response_from_apple = ex.raw_response
        print("validation failure:")
        print(response_from_apple)
        return (False, response_from_apple)

    return (True, validation_result)


# https://github.com/vkobel/ethereum-generate-wallet/blob/master/ethereum-wallet-generator.py
def checksum_encode(addr_str):  # Takes a hex (string) address as input
    keccak = sha3.keccak_256()
    out = ''
    addr = addr_str.lower().replace('0x', '')
    keccak.update(addr.encode('ascii'))
    hash_addr = keccak.hexdigest()
    for i, c in enumerate(addr):
        if int(hash_addr[i], 16) >= 8:
            out += c.upper()
        else:
            out += c
    return '0x' + out


def generate_wallet():
    keccak = sha3.keccak_256()
    priv = SigningKey.generate(curve=SECP256k1)
    pub = priv.get_verifying_key().to_string()
    keccak.update(pub)
    address = keccak.hexdigest()[24:]

    wallet = {
        'private': priv.to_string().hex(),
        'public': pub.hex(),
        'address': checksum_encode(address),
    }
    return wallet


def generate_config(
    secret=None,
    curator='partners.orch1d.eth',
    protocol='orchid',
    funder='0xE85C49919615A4aE3bFf08A350AEd7853340D4A0',
):
    if secret is not None:
        return f'account = {{curator:"{curator}", protocol: "{protocol}", \
funder: "{funder}", secret: "{secret}"}};'
    else:
        return f'account = {{curator:"{curator}", protocol: "{protocol}", \
funder: "{funder}"}};'


def product_to_usd(product_id: str) -> float:
    mapping = {
        'BuyUS10': 10.00,
    }
    return mapping.get(product_id, -1)


def main(event, context):
    print(f'event: {event}')
    print(f'context: {context}')

    body = json.loads(event['body'])
    print(f'body: {body}')
    total_usd = body['total_usd']
    receipt = body['receipt']
    signer = body.get('signer', '')

    verify_receipt = body.get('verify_receipt', 'False')
    funder_pubkey = get_secret(key='PAC_FUNDER_PUBKEY')
    funder_privkey = get_secret(key='PAC_FUNDER_PRIVKEY')

    if signer == '':
        wallet = generate_wallet()
        signer = wallet['address']
        secret = wallet['private']
        config = generate_config(
            secret=secret,
            funder=funder_pubkey,
        )
    else:
        config = generate_config(
            funder=funder_pubkey,
        )

    apple_response = process_app_pay_receipt(receipt, total_usd)

    if (apple_response[0] or verify_receipt == 'False'):
        validation_result: dict = apple_response[1]
        bundle_id = validation_result['receipt']['bundle_id']
        if bundle_id != 'OrchidTechnologies.PAC-Test':
            print(f'Incorrect bundle_id: {bundle_id} (Does not match OrchidTechnologies.PAC-Test)')
            response = {
                "isBase64Encoded": False,
                "statusCode": 200,
                "headers": {},
                "body": json.dumps({
                    'message': f'Incorrect bundle_id: {bundle_id} (Does not match OrchidTechnologies.PAC-Test)',
                    'config': config,
                })
            }
        else:
            product_id = validation_result['receipt']['in_app'][0]['product_id']
            quantity = int(validation_result['receipt']['in_app'][0]['quantity'])
            total_usd = product_to_usd(product_id=product_id) * quantity
            print(f'product_id: {product_id}')
            print(f'quantity: {quantity}')
            print(f'total_usd: {total_usd}')
            if total_usd < 0:
                print('Unknown product_id')
                response = {
                    "isBase64Encoded": False,
                    "statusCode": 200,
                    "headers": {},
                    "body": json.dumps({
                        'message': f"Unknown product_id: {product_id}",
                        'config': config,
                    })
                }
            else:
                txn_hash = fund_PAC(signer, float(total_usd),
                                    funder_pubkey, funder_privkey)
                response = {
                    "isBase64Encoded": False,
                    "statusCode": 200,
                    "headers": {},
                    "body": json.dumps({
                        "push_txn": txn_hash,
                        "config": config,
                    })
                }
    else:
        response = {
            "isBase64Encoded": False,
            "statusCode": 200,
            "headers": {},
            "body": json.dumps({
                "message": f"Validation Failure: {apple_response[1]}",
                "config": config,
            })
        }
    print(f'response: {response}')
    return response


if __name__ == "__main__":
    main(event='', context='')

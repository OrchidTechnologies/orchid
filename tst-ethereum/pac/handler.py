import boto3
import datetime
import json
import logging
import os
import requests
import sha3
import time  # noqa: F401
import web3.exceptions  # noqa: F401
import uuid
import hashlib

from boto3.dynamodb.conditions import Key
from decimal import Decimal
from ecdsa import SigningKey, SECP256k1
from inapppy import AppStoreValidator, InAppPyValidationError
from abis import lottery_abi, token_abi
from typing import Any, Dict, Optional, Tuple
from web3.auto.infura import w3


if len(logging.getLogger().handlers) > 0:
    # The Lambda environment pre-configures a handler logging to stderr. If a handler is already configured,
    # `.basicConfig` does not execute. Thus we set the level directly.
    logging.getLogger().setLevel(level=os.environ.get('LOG_LEVEL', "DEBUG"))
else:
    logging.basicConfig(level=os.environ.get('LOG_LEVEL', "DEBUG"))

client = boto3.client('ssm')


def get_secret(key: str) -> str:
    resp: dict = client.get_parameter(
        Name=key,
        WithDecryption=True,
    )
    return resp['Parameter']['Value']


def get_usd_per_oxt() -> float:
    r = requests.get(url="https://api.coinbase.com/v2/prices/OXT-USD/spot")
    data = r.json()
    logging.debug(data)
    usd_per_oxt = float(data['data']['amount'])
    logging.debug(f"usd_per_oxt: {usd_per_oxt}")
    return usd_per_oxt


def get_product_id_mapping(store: str = 'apple') -> dict:
    mapping = {}
    mapping['apple'] = {
        'net.orchid.US499': 4.99,
        'net.orchid.pactier1': 4.99,
        'net.orchid.pactier2': 9.99,
        'net.orchid.pactier3': 19.99,
    }
    mapping['google'] = {
        'net.orchid.pactier1': 4.99,
        'net.orchid.pactier2': 9.99,
        'net.orchid.pactier3': 19.99,
    }
    return mapping.get(store, {})


def fund_PAC_(
    signer: str,
    total: float,
    escrow: float,
    funder_pubkey: str,
    funder_privkey: str,
    nonce: int,
) -> str:
    logging.debug(f"Funding PAC  signer: {signer}, total: {total}, escrow: {escrow} ")

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

    logging.debug(f"Funder nonce: {nonce}")

    logging.debug(f"Assembling approve transaction:")
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
    logging.debug(approve_txn)

    logging.debug(f"Funder signed transaction:")
    approve_txn_signed = w3.eth.account.sign_transaction(
        approve_txn, private_key=funder_privkey)
    logging.debug(approve_txn_signed)

    logging.debug(f"Submitting approve transaction:")

    approve_txn_hash = w3.eth.sendRawTransaction(
        approve_txn_signed.rawTransaction)
    logging.debug(f"Submitted approve transaction with hash: {approve_txn_hash.hex()}")

    nonce = nonce + 1
    logging.debug(f"Funder nonce: {nonce}")

    logging.debug(f"Assembling bind transaction:")
    bind_txn = lottery_main.functions.bind(
        signer,
        verifier_addr,
        w3.toBytes(0),
    ).buildTransaction(
        {
            'chainId': 1,
            'from': funder_pubkey,
            'gas': 200000,
            'gasPrice': w3.toWei('8', 'gwei'),
            'nonce': nonce,
        }
    )
    logging.debug(bind_txn)

    logging.debug(f"Funder signed transaction:")
    bind_txn_signed = w3.eth.account.sign_transaction(bind_txn, private_key=funder_privkey)
    logging.debug(bind_txn_signed)

    logging.debug(f"Submitting bind transaction:")
    bind_txn_hash = w3.eth.sendRawTransaction(bind_txn_signed.rawTransaction)
    logging.debug(f"Submitted bind transaction with hash: {bind_txn_hash.hex()}")

    nonce = nonce + 1
    logging.debug(f"Funder nonce: {nonce}")

    logging.debug(f"Assembling funding transaction:")
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
    logging.debug(funding_txn)

    logging.debug(f"Funder signed transaction:")
    funding_txn_signed = w3.eth.account.sign_transaction(
        funding_txn, private_key=funder_privkey)
    logging.debug(funding_txn_signed)

    logging.debug(f"Submitting funding transaction:")
    txn_hash: str = w3.eth.sendRawTransaction(
        funding_txn_signed.rawTransaction).hex()
    logging.debug(f"Submitted funding transaction with hash: {txn_hash}")
    return txn_hash


def fund_PAC(total_usd: float, nonce: int) -> Tuple[str, str, str]:
    wallet = generate_wallet()
    signer = wallet['address']
    secret = wallet['private']
    config = generate_config(
        secret=secret,
    )

    usd_per_oxt = get_usd_per_oxt();
    oxt_per_usd = 1.0 / usd_per_oxt;
    total_oxt = total_usd * oxt_per_usd;
    escrow_oxt = 3.0;
    if (escrow_oxt >= 0.9*total_oxt):
        escrow_oxt = 0.5*total_oxt;

    logging.debug(
        f"Funding PAC  signer: {signer}, \
total: ${total_usd}{total_oxt} oxt, \
escrow: ${escrow_usd}{escrow_oxt} oxt ")

    funder_pubkey = get_secret(key='PAC_FUNDER_PUBKEY')
    funder_privkey = get_secret(key='PAC_FUNDER_PRIVKEY')

    txn_hash = fund_PAC_(
        signer=signer,
        total=w3.toWei(total_oxt, 'ether'),
        escrow=w3.toWei(escrow_oxt, 'ether'),
        funder_pubkey=funder_pubkey,
        funder_privkey=funder_privkey,
        nonce=nonce,
        )
    return txn_hash, config, signer


def process_app_pay_receipt(
    receipt,
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
        logging.debug("Validating AppStore Receipt:")
        validation_result: Dict[Any, Any] = validator.validate(
            receipt=receipt,
            shared_secret=shared_secret,
            exclude_old_transactions=exclude_old_transactions
        )
        logging.debug(f'Validation Result: {validation_result}')
    except InAppPyValidationError as ex:
        # handle validation error
        # contains actual response from AppStore service.
        response_from_apple = ex.raw_response
        logging.debug(f"validation failure: {response_from_apple}")
        return (False, response_from_apple)

    return (True, validation_result)


def generate_wallet() -> Dict[str, str]:
    keccak = sha3.keccak_256()
    priv = SigningKey.generate(curve=SECP256k1)
    pub = priv.get_verifying_key().to_string()
    keccak.update(pub)
    address = keccak.hexdigest()[24:]

    wallet = {
        'private': priv.to_string().hex(),
        'public': pub.hex(),
        'address': w3.toChecksumAddress(address),
    }
    return wallet


def generate_config(
    secret: str = None,
    curator: str = 'partners.orch1d.eth',
    protocol: str = 'orchid',
    funder: str = get_secret(key='PAC_FUNDER_PUBKEY'),
) -> str:
    if secret is not None:
        return f'account = {{curator:"{curator}", protocol: "{protocol}", \
funder: "{funder}", secret: "{secret}"}};'
    else:
        return f'account = {{curator:"{curator}", protocol: "{protocol}", \
funder: "{funder}"}};'


def wildcard_product_to_usd(product_id: str) -> float:
    mapping = get_product_id_mapping()
    for id in mapping:
        if id.split('.')[-1] == product_id.split('.')[-1]:
            return mapping[id]
    return -1


def product_to_usd(product_id: str) -> float:
    mapping = get_product_id_mapping()
    return mapping.get(product_id, -1)


def random_scan(table, price):
    # generate a random 32 byte address (1 x 32 byte ethereum address)
    rand_key = uuid.uuid4().hex + uuid.uuid4().hex
    ddb_price = json.loads(json.dumps(price), parse_float=Decimal)  # Work around DynamoDB lack of float support
    response0 = table.query(KeyConditionExpression=Key('price').eq(ddb_price) & Key('signer').gte(rand_key))
    response1 = table.query(KeyConditionExpression=Key('price').eq(ddb_price) & Key('signer').lte(rand_key))
    response0['Items'].extend(response1['Items'])
    return response0


def get_account(price: float) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    logging.debug(f'Getting Account with Price:{price}')
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['TABLE_NAME'])
    response = random_scan(table, price)
    ret = None
    signer_pubkey = '0xTODO'
    for item in response['Items']:
        if float(price) == float(item['price']):
            # todo: need to check status - make sure pot is ready
            signer_pubkey = item['signer']
            config = item['config']
            push_txn_hash = item['push_txn_hash']
            logging.debug(f'Found available account ({push_txn_hash}): {config}')
            key = {
                'price': item['price'],
                'signer': signer_pubkey,
            }

            delete_response = table.delete_item(Key=key, ReturnValues='ALL_OLD')
            if (delete_response['Attributes'] is not None and len(delete_response['Attributes']) > 0):
            # update succeeded
                ret = push_txn_hash, config, signer_pubkey
                break
            else:
                logging.debug('Account was already deleted!')
    if ret:
        return ret
    return None, None, None


def call_maintain_pool():
    client = boto3.client('lambda')
    response = client.invoke(
        FunctionName=f"pac-{os.environ['STAGE']}-MaintainPool",
        InvocationType='Event',
    )
    return response


def maintain_pool_wrapper(event=None, context=None):
    mapping = get_product_id_mapping()
    funder_pubkey = get_secret(key='PAC_FUNDER_PUBKEY')
    nonce = w3.eth.getTransactionCount(account=funder_pubkey)
    for product_id in mapping:
        price = mapping[product_id]
        maintain_pool(price=price, nonce=nonce)
        nonce += 3


def get_transaction_confirm_count(txhash):
    funder_pubkey = get_secret(key='PAC_FUNDER_PUBKEY')
    blocknum = w3.eth.getTransactionCount(account=funder_pubkey)
    trans = w3.eth.getTransaction(txhash)
    return blocknum - trans['blockNumber']


def get_transaction_status(txhash):
    try:
        count = get_transaction_confirm_count(txhash)
        if (count >= 12):
            return "confirmed"
        else:
            return "unconfirmed"
    except w3.TransactionNotFound:
        return "unknown"
    return "unknown"


def maintain_pool(price: float, pool_size: int = int(os.environ['DEFAULT_POOL_SIZE']), nonce: int = None):
    logging.debug(f'Maintaining Pool of size:{pool_size} and price:{price}')
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['TABLE_NAME'])
    response = table.scan()
    actual_pool_size = 0
    for item in response['Items']:
        # todo: update status here with get_transaction_status(.)
        if float(price) == float(item['price']):
            actual_pool_size += 1
    accounts_to_create = max(pool_size - actual_pool_size, 0)
    logging.debug(f'Actual Pool Size: {actual_pool_size}. Need to create {accounts_to_create} accounts')
    logging.debug(f'Need to create {accounts_to_create} accounts')
    if nonce is None:
        funder_pubkey = get_secret(key='PAC_FUNDER_PUBKEY')
        nonce = w3.eth.getTransactionCount(account=funder_pubkey)
    for _ in range(accounts_to_create):
        push_txn_hash, config, signer_pubkey = fund_PAC(
            total_usd=price,
            nonce=nonce,
        )
        creation_time = datetime.datetime.utcnow().replace(tzinfo=datetime.timezone.utc).isoformat()
        item = {
            'signer': signer_pubkey,
            'price': price,
            'config': config,
            'push_txn_hash': push_txn_hash,
            'creation_time': creation_time,
        }
        ddb_item = json.loads(json.dumps(item), parse_float=Decimal)  # Work around DynamoDB lack of float support
        table.put_item(Item=ddb_item)
        nonce += 3


# todo: replay prevention through receipt hash map
def main(event, context):
    logging.debug(f'event: {event}')
    logging.debug(f'context: {context}')

    body = json.loads(event.get('body', {}))

    logging.debug(f'body: {body}')
    receipt = body.get('receipt', '')

    dynamodb = boto3.resource('dynamodb')
    receipt_hash_table = dynamodb.Table(os.environ['RECEIPT_TABLE_NAME'])

    if os.environ['STAGE'] != 'dev':
        if body.get('verify_receipt') or body.get('product_id'):  # todo: Use a whitelist rather than a blacklist
            response = {
                'isBase64Encoded': False,
                'statusCode': 400,
                'headers': {},
                'body': json.dumps({
                    'message': 'dev-only parameter included in request!',
                    'push_txn_hash': None,
                    'config': None,
                })
            }
            return response

    verify_receipt = body.get('verify_receipt', 'False')

    receipt_hash = hashlib.sha256(receipt.encode('utf-8')).hexdigest()
    if (verify_receipt == 'True'):
        result = receipt_hash_table.query(KeyConditionExpression=Key('receipt').eq(receipt_hash))
        if (result['Count'] > 0):  # we found a match - reject on duplicate
            response = {
                "isBase64Encoded": False,
                "statusCode": 402,
                "headers": {},
                "body": json.dumps({
                    "message": "Validation Failure: duplicate receipt!",
                    "push_txn_hash": None,
                    "config": None,
                })
            }
            logging.debug(f'response: {response}')
            return response

    apple_response = process_app_pay_receipt(receipt)

    if (apple_response[0] or verify_receipt == 'False'):
        validation_result: dict = apple_response[1]
        if validation_result is None:
            bundle_id = ''
        else:
            bundle_id = validation_result.get('receipt', {}).get('bundle_id', '')
        if bundle_id != 'OrchidTechnologies.PAC-Test' and verify_receipt != 'False':  # Bad bundle_id and set to verify_receipts
            logging.debug(f'Incorrect bundle_id: {bundle_id} (Does not match OrchidTechnologies.PAC-Test)')
            response = {
                "isBase64Encoded": False,
                "statusCode": 400,
                "headers": {},
                "body": json.dumps({
                    'message': f'Incorrect bundle_id: {bundle_id} (Does not match OrchidTechnologies.PAC-Test)',
                    'push_txn_hash': None,
                    'config': None,
                })
            }
        else:  # Good bundle_id or not verifying receipts
            product_id = body.get('product_id', validation_result['receipt']['in_app'][0]['product_id'])
            quantity = int(validation_result['receipt']['in_app'][0]['quantity'])
            if os.environ['STAGE'] == 'dev':
                total_usd = wildcard_product_to_usd(product_id=product_id) * quantity
            else:
                total_usd = product_to_usd(product_id=product_id) * quantity
            logging.debug(f'product_id: {product_id}')
            logging.debug(f'quantity: {quantity}')
            logging.debug(f'total_usd: {total_usd}')
            if total_usd < 0:
                logging.debug('Unknown product_id')
                response = {
                    "isBase64Encoded": False,
                    "statusCode": 400,
                    "headers": {},
                    "body": json.dumps({
                        'message': f"Unknown product_id: {product_id}",
                        'push_txn_hash': None,
                        'config': None,
                    })
                }
            else:
                push_txn_hash, config, signer_pubkey = get_account(price=total_usd)
                if config is None:
                    response = {
                        "isBase64Encoded": False,
                        "statusCode": 404,
                        "headers": {},
                        "body": json.dumps({
                            "message": "No Account Found",
                            "push_txn_hash": push_txn_hash,
                            "config": config,
                        })
                    }
                else:
                    response = {
                        "isBase64Encoded": False,
                        "statusCode": 200,
                        "headers": {},
                        "body": json.dumps({
                            "push_txn_hash": push_txn_hash,
                            "config": config,
                        })
                    }
                    item = {
                        'receipt': receipt_hash,
                    }
                    ddb_item = json.loads(json.dumps(item), parse_float=Decimal)  # Work around DynamoDB lack of float support
                    receipt_hash_table.put_item(Item=ddb_item)

    else:
        response = {
            "isBase64Encoded": False,
            "statusCode": 402,
            "headers": {},
            "body": json.dumps({
                "message": f"Validation Failure: {apple_response[1]}",
                "push_txn_hash": None,
                "config": None,
            })
        }
    logging.debug(f'response: {response}')
    return response


def apple(event, context):
    return main(event, context)


def google(event, context):
    response = {
        "isBase64Encoded": False,
        "statusCode": 501,
        "headers": {},
        "body": json.dumps({
            "message": f"Google Support Not Implemented Yet!",
            "push_txn_hash": None,
            "config": None,
        })
        }
    logging.debug(f'response: {response}')
    return response


if __name__ == "__main__":
    main(event='', context='')

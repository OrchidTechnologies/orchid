import boto3
import json
import logging
import os
import requests
import sha3
import time
import hashlib
import base64

from boto3.dynamodb.conditions import Key
from decimal import Decimal
from ecdsa import SigningKey, SECP256k1
from inapppy import AppStoreValidator, InAppPyValidationError
from status import get_transaction_status
from typing import Any, Dict, Optional, Tuple
from w3 import approve, bind, get_block_number, look, push
from utils import configure_logging, get_secret, is_true, random_scan
from web3 import Web3
from asn1crypto.cms import ContentInfo


w3 = Web3(Web3.WebsocketProvider(os.environ['WEB3_WEBSOCKET'], websocket_timeout=900))
configure_logging()


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
        'net.orchid.pactier1': 6.99,
        'net.orchid.pactier2': 29.99,
        'net.orchid.pactier3': 79.99,
    }
#     mapping['google'] = {
#         'net.orchid.pactier1': 4.99,
#         'net.orchid.pactier2': 9.99,
#         'net.orchid.pactier3': 19.99,
#     }
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

    gas_price = int(os.environ['DEFAULT_GAS'])
    lottery_addr = os.environ['LOTTERY']
    verifier_addr = os.environ['VERIFIER']

    approve(
      spender=lottery_addr,
      amount=total,
      nonce=nonce,
      gas_price=gas_price,
    )
    nonce += 1

    bind(
      signer=signer,
      verifier=verifier_addr,
      shared='0x',
      nonce=nonce,
      gas_price=gas_price,
    )
    nonce += 1

    push_txn_hash = push(
      signer=signer,
      total=total,
      escrow=escrow,
      nonce=nonce,
      gas_price=gas_price,
    )
    nonce += 1

    return push_txn_hash


def get_min_escrow():
    return 15.0


def get_target_NFV(tusd):
    return 2.228775056 * pow(tusd, 0.5) - 4.597556694


def fund_PAC(total_usd: float, nonce: int) -> Tuple[str, str, str, float, float]:
    wallet = generate_wallet()
    signer = wallet['address']
    secret = wallet['private']
    config = generate_config(secret=secret)

    target_NFV = get_target_NFV(total_usd)
    tot_units = max(int(target_NFV+0.5), 3)

    usd_per_oxt = get_usd_per_oxt()
    oxt_per_usd = 1.0 / usd_per_oxt
    # escrow_oxt = get_min_escrow()
    value_usd = total_usd * 0.7 - 0.5  # 30% store fee, 0.5 setup charge
    value_oxt = value_usd * oxt_per_usd
    # tot_units = max(int(value_oxt / (0.5*escrow_oxt)), 3);
    FV_oxt = value_oxt / float(tot_units)

    if total_usd == 6.99:
        escrow_mult = 2
    else:
        escrow_mult = 1

    eth_to_wei = 1000000000000000000
    FV_wei = int(eth_to_wei * FV_oxt)
    total_wei = tot_units * FV_wei + (2 * FV_wei)
    escrow_wei = 2 * FV_wei * escrow_mult

    escrow_oxt = float(escrow_wei) / float(eth_to_wei)
    total_oxt = float(total_wei) / float(eth_to_wei)
    balance_oxt = total_oxt - escrow_oxt

    logging.debug(
        f'Funding PAC  signer: {signer}, total_usd: ${total_usd} total_oxt: {total_oxt} OXT, '
        f'escrow: {escrow_oxt} OXT  escrow_mult: {escrow_mult} tot_units: {tot_units}  FV_oxt: {FV_oxt} '
        f'target_NFV: {target_NFV}'
    )

    funder_pubkey = get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET'])
    funder_privkey = get_secret(key=os.environ['PAC_FUNDER_PRIVKEY_SECRET'])

    txn_hash = fund_PAC_(
        signer=signer,
        total=w3.toWei(total_wei, 'wei'),
        escrow=w3.toWei(escrow_wei, 'wei'),
        funder_pubkey=funder_pubkey,
        funder_privkey=funder_privkey,
        nonce=nonce,
        )
    return txn_hash, config, signer, balance_oxt, escrow_oxt


def process_app_pay_receipt(
    receipt,
    shared_secret=None
) -> Tuple[bool, dict]:
    bundle_id = os.environ['BUNDLE_ID']
    # if True, automatically query sandbox endpoint
    # if validation fails on production endpoint
    if is_true(os.environ['AUTO_RETRY_WRONG_ENV_REQUEST']):
        auto_retry_wrong_env_request = True
    else:
        auto_retry_wrong_env_request = False
    validator = AppStoreValidator(
        bundle_id=bundle_id,
        sandbox=is_true(os.environ['RECEIPT_SANDBOX']),
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
    funder: str = get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET']),
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


def get_account_(price: float, blocknum: int) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    logging.debug(f'get_account_ price:{price}')
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['TABLE_NAME'])
    response = random_scan(table, price)
    ret = None
    signer_pubkey = '0xTODO'
    epoch_time = int(time.time())
    for item in response['Items']:
        if float(price) == float(item['price']):
            signer_pubkey = item['signer']
            config = item['config']
            push_txn_hash = item['push_txn_hash']
            creation_etime = item.get('creation_etime', 0)
            age = epoch_time - creation_etime

            if is_true(os.environ['DOUBLE_CHECK_ACCOUNTS']):
                old_status = item['status']
                status = get_transaction_status(push_txn_hash, blocknum)
                if old_status != status:
                    logging.warning(
                      f'DynamoDB status of {old_status} for {push_txn_hash} '
                      f'does not match new status of {status}!'
                    )
            else:
                status = item['status']

            if ((status != 'confirmed') and (age < 10*60*60)):  # 10 hour grace period
                logging.debug(f'Skipping account ({push_txn_hash}) with status: {status} age: {age}')
                continue

            logging.debug(f'Found potential account ({push_txn_hash}) status: {status} age:{age} config: {config}')
            key = {
                'price': item['price'],
                'signer': signer_pubkey,
            }
            delete_response = table.delete_item(Key=key, ReturnValues='ALL_OLD')
            if (delete_response['Attributes'] is not None and len(delete_response['Attributes']) > 0):
                balance, escrow, _ = look(
                    funder=get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET']),
                    signer=signer_pubkey,
                )
                # update succeeded
                if ((status == 'confirmed') and (escrow > get_min_escrow())):
                    ret = push_txn_hash, config, signer_pubkey
                    break
                else:
                    logging.debug(
                        f'broken account: {push_txn_hash} status: {status}  age: {age} '
                        f'balance: {balance} deleted and skipped'
                    )
            else:
                logging.debug('Account was already deleted!')
    if ret:
        return ret
    return None, None, None


def get_account(price: float) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    logging.debug(f'Getting Account with Price:{price}')
    blocknum = get_block_number()
    push_txn_hash = config = signer_pubkey = None
    count = 0
    while push_txn_hash is None and count < 8:
        push_txn_hash, config, signer_pubkey = get_account_(price=price, blocknum=blocknum)
        count = count + 1
    return push_txn_hash, config, signer_pubkey


def hash_receipt_body(receipt):

    # receipt_hash = hashlib.sha256(receipt.encode('utf-8')).hexdigest()

    # Load the contents of the receipt file
    # receipt_file = open('./receipt_data.bin', 'rb').read()
    logging.debug('hashing receipt')
    # receipt_file = bytearray.fromhex(receipt);
    # receipt_file = bytes.fromhex(receipt)
    receipt_file = base64.decodebytes(receipt.encode('utf-8'))

    # Use asn1crypto's cms definitions to parse the PKCS#7 format
    pkcs_container = ContentInfo.load(receipt_file)

    # Extract the certificates, signature, and receipt_data
    certificates = pkcs_container['content']['certificates']
    signer_info = pkcs_container['content']['signer_infos'][0]
    receipt_data = pkcs_container['content']['encap_content_info']['content']
    logging.debug(
      f'extracted certificates {len(str(certificates))}B signer_info {len(str(signer_info))}B '
      f'receipt_data {len(str(receipt_data))}B'
    )

    receipt_data_str = str(receipt_data).encode('utf-8')[50:]  # slice the string to remove random header
    logging.debug(f'receipt_data_str: \n{receipt_data_str}')

    receipt_hash = hashlib.sha256(receipt_data_str).hexdigest()
    logging.debug(f'receipt_hash: {receipt_hash}')

    return receipt_hash


def response_error_invalid_dev_param():
    response = {
        'isBase64Encoded': False,
        'statusCode': 400,
        'headers': {},
        'body': json.dumps({
            'message': 'dev-only parameter included in request!',
            'push_txn_hash': None,
            'config': None,
            'seller': None,
        })
    }
    logging.debug(f'dev-only parameter included in request! response: {response}')
    return response


def response_invalid_bundle(bundle_id):
    logging.debug(f'Incorrect bundle_id: {bundle_id} (Does not match expected {os.environ["BUNDLE_ID"]})')
    response = {
        "isBase64Encoded": False,
        "statusCode": 400,
        "headers": {},
        "body": json.dumps({
            'message': f'Incorrect bundle_id: {bundle_id} (Does not match expected {os.environ["BUNDLE_ID"]})',
            'push_txn_hash': None,
            'config': None,
            'seller': None,
        })
    }
    return response


def response_invalid_product(product_id):
    logging.debug(f'response_invalid_product(product_id:{product_id})')
    response = {
        "isBase64Encoded": False,
        "statusCode": 400,
        "headers": {},
        "body": json.dumps({
            'message': f"Unknown product_id: {product_id}",
            'push_txn_hash': None,
            'config': None,
            'seller': None,
        })
    }
    return response


def response_no_account():
    logging.debug('response_no_account()')
    response = {
        "isBase64Encoded": False,
        "statusCode": 404,
        "headers": {},
        "body": json.dumps({
            "message": "No Account Found",
            "push_txn_hash": None,
            "config": None,
            "seller": None,
        })
    }
    return response


def response_invalid_receipt(apple_response):
    logging.debug('response_invalid_receipt(.)')
    response = {
        "isBase64Encoded": False,
        "statusCode": 402,
        "headers": {},
        "body": json.dumps({
            "message": f"Validation Failure: {apple_response[1]}",
            "push_txn_hash": None,
            "config": None,
            "seller": None,
        })
    }
    return response


def response_valid_account(push_txn_hash, config, verifier):
    logging.debug(f'response_valid_account(push_txn_hash:{push_txn_hash})')
    response = {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": {},
        "body": json.dumps({
            "push_txn_hash": push_txn_hash,
            "config": config,
            "seller": verifier,
        })
    }
    return response


def find_previous_pot(result_hash_table, receipt_hash, verifier, Stage):
    logging.debug(f'find_previous_pot( receipt_hash:{receipt_hash}, verifier: {verifier}, Stage: {Stage})')
    result = result_hash_table.query(ConsistentRead=True, KeyConditionExpression=Key('receipt').eq(receipt_hash))
    if (Stage != 'dev' and result['Count'] > 0):  # we found a match, return it
        item = result['Items'][0]
        config = item['config']
        push_txn_hash = item['push_txn_hash']
        response = {
            "isBase64Encoded": False,
            "statusCode": 200,
            "headers": {},
            "body": json.dumps({
                "push_txn_hash": push_txn_hash,
                "config": config,
                "seller": verifier,
            })
        }
        logging.debug(f'found existing match for receipt_hash({receipt_hash}), result: {response}')
        return response
    return None


def find_previous_receipt_claim(receipt_hash_table, receipt_hash):
    logging.debug(f'find_previous_receipt_claim( receipt_hash:{receipt_hash})')
    result = receipt_hash_table.query(ConsistentRead=True, KeyConditionExpression=Key('receipt').eq(receipt_hash))
    if (result['Count'] > 0):  # we found a match - reject on duplicate
        response = {
            "isBase64Encoded": False,
            "statusCode": 402,
            "headers": {},
            "body": json.dumps({
                "message": "Validation Failure: duplicate receipt!",
                "push_txn_hash": None,
                "config": None,
                "seller": None,
            })
        }
        logging.debug(f'duplicate receipt! response: {response}')
        return response
    return None


def claim_receipt(receipt_hash_table, receipt_hash):
    logging.debug(f'claim_receipt(receipt_hash:{receipt_hash})')
    item = {
        'receipt': receipt_hash,
    }
    ddb_item = json.loads(json.dumps(item), parse_float=Decimal)  # Work around DynamoDB lack of float support
    # fail if already exists, raises ConditionalCheckFailedException
    receipt_hash_table.put_item(Item=ddb_item, ConditionExpression='attribute_not_exists(receipt)')


def store_result(result_hash_table, receipt_hash, config, push_txn_hash, verifier):
    logging.debug(f'store_result(receipt_hash:{receipt_hash},...)')
    expiration_time = int(time.time() + 24*3600*7)  # one week
    item = {
        'receipt': receipt_hash,
        'config': config,
        'push_txn_hash': push_txn_hash,
        'seller': verifier,
        'expiration_time': expiration_time,
    }
    ddb_item = json.loads(json.dumps(item), parse_float=Decimal)  # Work around DynamoDB lack of float support
    result_hash_table.put_item(Item=ddb_item)


def main(event, context):
    Stage = os.environ['STAGE']

    body = json.loads(event.get('body', {}))

    if is_true(body.get('debug', '')):
        configure_logging(level="DEBUG")

    logging.debug(f'main entry Stage:{Stage} ')
    logging.debug(f'event: {event}')
    logging.debug(f'context: {context}')
    logging.debug(f'body: {body}')
    receipt = body.get('receipt', '')

    dynamodb = boto3.resource('dynamodb')
    result_hash_table = dynamodb.Table(os.environ['RESULT_TABLE_NAME'])
    receipt_hash_table = dynamodb.Table(os.environ['RECEIPT_TABLE_NAME'])

    # check for dev params, respond with error in prod
    if os.environ['STAGE'] != 'dev':
        if body.get('verify_receipt') or body.get('product_id'):
            return response_error_invalid_dev_param()

    # extract and hash the receipt body payload
    receipt_hash = hash_receipt_body(receipt)

    # find any matching previous pot result and conditionally return it (idempotency)
    response = find_previous_pot(result_hash_table, receipt_hash, os.environ['VERIFIER'], Stage)
    if response is not None:
        return response

    # find and error return for any previous claim of the receipt (replay prevention)
    # todo: this is not concurrent-safe, claim needs to be atomic
    verify_receipt = body.get('verify_receipt', 'True')
    if (is_true(verify_receipt)):
        response = find_previous_receipt_claim(receipt_hash_table, receipt_hash)
        if response is not None:
            return response

    apple_response = process_app_pay_receipt(receipt)

    if (apple_response[0] or verify_receipt == 'False'):
        validation_result: dict = apple_response[1]
        if validation_result is None:
            bundle_id = ''
        else:
            bundle_id = validation_result.get('receipt', {}).get('bundle_id', '')

        if bundle_id != os.environ['BUNDLE_ID'] and is_true(verify_receipt):  # Bad bundle_id and set to verify_receipts
            response = response_invalid_bundle(bundle_id)
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
            if total_usd <= 0:
                response = response_invalid_product(product_id)
            else:
                # find/claim a valid pot
                push_txn_hash, config, signer_pubkey = get_account(price=total_usd)
                if config is None:
                    response = response_no_account()
                else:
                    response = response_valid_account(push_txn_hash, config, os.environ['VERIFIER'])

                    # claim the receipt (conditionally atomically, exception fails if already exists)
                    if (Stage != 'dev'):
                        claim_receipt(receipt_hash_table, receipt_hash)

                    # store result (idempotency)
                    store_result(result_hash_table, receipt_hash, config, push_txn_hash, os.environ['VERIFIER'])
    else:
        response = response_invalid_receipt(apple_response)
    logging.debug(f'response: {response}')
    return response


def apple(event, context):
    return main(event, context)


if __name__ == "__main__":
    main(event='', context='')

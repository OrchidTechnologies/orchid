from recycle import recycle_accounts
import boto3
import datetime
import json
import logging
import os
import time

from decimal import Decimal
from handler import fund_PAC, get_product_id_mapping
from utils import configure_logging
from w3 import get_nonce


configure_logging()


def call_maintain_pool():
    client = boto3.client('lambda')
    response = client.invoke(
        FunctionName=f"pac-{os.environ['STAGE']}-MaintainPool",
        InvocationType='Event',
    )
    return response


def maintain_pool_wrapper(event=None, context=None):
    configure_logging(level="DEBUG")
    mapping = get_product_id_mapping()
    nonce = get_nonce()
    logging.debug(f"maintain_pool_wrapper Funder nonce: {nonce}")
    for product_id in mapping:
        price = mapping[product_id]
        pool_size_env = f'{product_id.upper()}_POOL_SIZE'.replace('.', '_')
        pool_size = os.environ.get(pool_size_env, os.environ['DEFAULT_POOL_SIZE'])
        logging.debug(f'pool_size_env: {os.environ.get(pool_size_env)} DEFAULT: {os.environ["DEFAULT_POOL_SIZE"]}')
        nonce = maintain_pool(price=price, pool_size=int(pool_size), nonce=nonce)
    recycle_accounts(nonce=nonce)


def get_account_counts(price: float):
    logging.debug(f'get_account_counts(price:{price})')
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['TABLE_NAME'])
    response = table.scan()
    total_count = 0
    confirm_count = 0
    for item in response['Items']:
        if float(price) == float(item['price']):
            total_count += 1
            if item['status'] == 'confirmed':
                confirm_count += 1
    return confirm_count, total_count


def compute_gas_price(confirm_count, target_count):
    ratio = float(confirm_count) / float(target_count)
    min_price = 1.0
    max_price = 50.0
    gas_price = (1.0-ratio)*min_price + ratio*max_price
    return gas_price


def maintain_pool(price: float, pool_size: int, nonce: int = None) -> int:
    logging.debug(f'Maintaining Pool of size:{pool_size} and price:{price}')
    confirm_pool_size, actual_pool_size = get_account_counts(price)
    accounts_to_create = max(pool_size - actual_pool_size, 0)
    gas_price = compute_gas_price(confirm_pool_size, actual_pool_size)
    logging.debug(f'Actual Pool Size: {confirm_pool_size} / {actual_pool_size}. gas_price: {gas_price} Need to create {accounts_to_create} accounts')
    if nonce is None:
        nonce = get_nonce()
    for _ in range(accounts_to_create):
        push_txn_hash, config, signer_pubkey, balance_oxt, escrow_oxt = fund_PAC(total_usd=price, nonce=nonce,)
        creation_time = datetime.datetime.utcnow().replace(tzinfo=datetime.timezone.utc).isoformat()
        creation_etime = int(time.time())
        item = {
            'signer': signer_pubkey,
            'price': price,
            'config': config,
            'push_txn_hash': push_txn_hash,
            'creation_time': creation_time,
            'creation_etime': creation_etime,
            'status': 'pending',
            'balance': balance_oxt,
            'escrow': escrow_oxt,
        }
        ddb_item = json.loads(json.dumps(item), parse_float=Decimal)  # Work around DynamoDB lack of float support
        table.put_item(Item=ddb_item)
        nonce += 3
    return nonce

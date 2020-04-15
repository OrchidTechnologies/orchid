import boto3
import datetime
import json
import logging
import os

from decimal import Decimal
from handler import fund_PAC, get_product_id_mapping
from utils import configure_logging, get_secret
from web3.auto.infura import w3


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
    funder_pubkey = get_secret(key='PAC_FUNDER_PUBKEY')
    nonce = w3.eth.getTransactionCount(account=funder_pubkey)
    for product_id in mapping:
        price = mapping[product_id]
        maintain_pool(price=price, nonce=nonce)
        nonce += 3


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

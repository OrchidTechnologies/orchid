import boto3
import logging
import os
import time

from metrics import metric
from recycle import recycle_account
from utils import configure_logging
from utils import get_min_escrow
from utils import get_secret
from w3 import get_block_number
from w3 import get_token_name
from w3 import get_token_symbol
from w3 import get_token_decimals
from w3 import get_transaction_confirm_count


configure_logging(level='DEBUG')


def get_transaction_status(txhash, blocknum):
    logging.debug(f'get_transaction_status() txhash:{txhash} blocknum:{blocknum}')
    status = "unknown"
    try:
        count = get_transaction_confirm_count(txhash, blocknum)
        logging.debug(f'count: {count}')
        if (count >= 12):
            status = "confirmed"
        else:
            status = "unconfirmed"
    except Exception:
        status = "unknown"
    logging.debug(f'status: {status}')
    return status


def update_statuses():
    logging.debug('update_statuses()')
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['TABLE_NAME'])
    response = table.scan()
    counts = {}
    funder_pubkey = get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET'])
    for item in response['Items']:
        signer = item['signer']
        price = item['price']
        push_txn_hash = item['push_txn_hash']
        status = item['status']
        balance = float(item.get('balance', 0))
        escrow = float(item.get('escrow', 0))
        blocknum = get_block_number()
        new_status = get_transaction_status(push_txn_hash, blocknum)

        if new_status in counts:
            counts[new_status][price] = counts[new_status].get(price, 0) + 1
        else:
            counts[new_status] = {
                price: 1,
            }

        if status != 'confirmed':
            if status != new_status:
                logging.debug(
                  f'Changing {push_txn_hash} with signer:{signer} and price:{price} '
                  f'from {status} to {new_status}'
                )
                table.update_item(
                  Key={
                    'price': price,
                    'signer': signer,
                  },
                  UpdateExpression="SET #status = :new_status",
                  ExpressionAttributeValues={
                    ':new_status': new_status,
                    ':old_status': status,
                  },
                  ExpressionAttributeNames={
                    "#status": "status"
                  },
                  ConditionExpression="#status = :old_status",
                )

                if new_status == 'confirmed':
                    token_name = get_token_name()
                    token_symbol = get_token_symbol()
                    token_decimals = get_token_decimals()
                    total = balance + escrow
                    min_escrow = get_min_escrow()
                    if escrow <= min_escrow:
                        logging.warning(
                            f'PAC with funder: {funder_pubkey} signer: {signer} balance: {balance} and '
                            f'escrow: {escrow} has escrow <= min escrow of {min_escrow}. Deleting.'
                        )
                        table.delete_item(
                            Key={
                              'price': price,
                              'signer': signer,
                            }
                        )
                        recycle_account(funder=funder_pubkey, signer=signer)
                    else:
                        metric(
                            metric_name='orchid.pac',
                            value=total,
                            tags=[
                                f'funder:{funder_pubkey}',
                                f'signer:{signer}',
                                f'price:{price}',
                                f'balance:{balance}',
                                f'escrow:{escrow}',
                                f'lottery_contract:{os.environ["LOTTERY"]}',
                                f'token_name:{token_name}',
                                f'token_symbol:{token_symbol}',
                                f'token_decimals:{token_decimals}',
                            ],
                        )
                else:
                    # new_status != 'confirmed'
                    creation_etime = item.get('creation_etime', 0)
                    epoch_time = int(time.time())
                    age = epoch_time - creation_etime
                    if age >= 10*60*60:  # 10 hours in seconds
                        logging.warning(
                            f'PAC with funder: {funder_pubkey} signer: {signer} balance: {balance} and '
                            f'escrow: {escrow} has status: {new_status} and age: {age} >= 10 hours. Deleting.'
                        )
                        table.delete_item(
                            Key={
                              'price': price,
                              'signer': signer,
                            }
                        )
                        recycle_account(funder=funder_pubkey, signer=signer)
            else:
                logging.debug(f'No need to update {push_txn_hash} with signer:{signer} and price:{price} from {status}')
        else:
            logging.debug(f'{push_txn_hash} with signer:{signer} and price:{price} already has status:{status}')
    for status in counts:
        for price in counts[status]:
            value = counts[status][price]
            logging.debug(f'There are {value} ${price} PACs with a status of {status}')
            metric(
                metric_name=f'orchid.pac.pool.{status}',
                value=value,
                tags=[
                    f'funder:{funder_pubkey}',
                    f'price:{price}',
                ],
            )


def main(event, context):
    logging.debug('Entering status.main()')
    update_statuses()

import boto3
import logging
import os

from utils import configure_logging
from w3 import get_block_number
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
    for item in response['Items']:
        signer = item['signer']
        price = item['price']
        push_txn_hash = item['push_txn_hash']
        status = item['status']
        if status != 'confirmed':
            blocknum = get_block_number()

            new_status = get_transaction_status(push_txn_hash, blocknum)

            if status != new_status:
                logging.debug(f'Changing {push_txn_hash} with signer:{signer} and price:{price} from {status} to {new_status}')
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
            else:
                logging.debug(f'No need to update {push_txn_hash} with signer:{signer} and price:{price} from {status}')
        else:
            logging.debug(f'{push_txn_hash} with signer:{signer} and price:{price} already has status:{status}')


def main(event, context):
    logging.debug('Entering status.main()')
    update_statuses()

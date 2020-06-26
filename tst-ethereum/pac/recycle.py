import boto3
import json
import logging
import os

from decimal import Decimal
from utils import configure_logging
from utils import get_latest_block
from utils import get_secret
from utils import is_true
from utils import keys
from utils import look
from utils import pull
from utils import warn


configure_logging()


def invalid_funder(funder: str, pac_funder: str):
    logging.debug(f'Invalid funder. Got: {funder} but Expected: {pac_funder}')
    response = {
        "isBase64Encoded": False,
        "statusCode": 400,
        "headers": {},
        "body": json.dumps({
            'message': f'Invalid funder: {funder} (Does not match expected {pac_funder})',
        })
    }
    return response


def invalid_signer(signer: str):
    logging.debug(f'Invalid signer. Got: {signer}')
    response = {
        "isBase64Encoded": False,
        "statusCode": 400,
        "headers": {},
        "body": json.dumps({
            'message': f'Invalid signer: {signer})',
        })
    }
    return response


def amount_too_high(amount: float, amount_threshold: float):
    logging.debug(f'Amount too high. {amount} is greater than threshold of {amount_threshold}')
    response = {
        "isBase64Encoded": False,
        "statusCode": 400,
        "headers": {},
        "body": json.dumps({
            'message': f'Amount too high. {amount} is greater than threshold of {amount_threshold}',
        })
    }
    return response


def escrow_too_high(escrow: float, escrow_threshold: float):
    logging.debug(f'Escrow too high. {escrow} is greater than threshold of {escrow_threshold}')
    response = {
        "isBase64Encoded": False,
        "statusCode": 400,
        "headers": {},
        "body": json.dumps({
            'message': f'Escrow too high. {escrow} is greater than threshold of {escrow_threshold}',
        })
    }
    return response


def store_account(funder: str, signer: str, unlock: str):
    logging.debug(f'Storing Account. Funder: {funder} Signer: {signer} Unlock: {unlock}')
    dynamodb = boto3.resource('dynamodb')
    recycle_table = dynamodb.Table(os.environ['RECYCLE_TABLE_NAME'])
    item = {
        'funder': funder,
        'signer': signer,
        'unlock': unlock
    }
    ddb_item = json.loads(json.dumps(item), parse_float=Decimal)  # Work around DynamoDB lack of float support
    recycle_table.put_item(Item=ddb_item)


def delete_account(signer: str):
    logging.debug(f'Deleting Account. Signer: {signer}')
    dynamodb = boto3.resource('dynamodb')
    recycle_table = dynamodb.Table(os.environ['RECYCLE_TABLE_NAME'])
    key = {
        'signer': signer,
    }
    recycle_table.delete_item(Key=key)


def account_queued_response():
    logging.debug('Account successfully queued for recycling.')
    response = {
        "isBase64Encoded": False,
        "statusCode": 201,
        "headers": {},
        "body": json.dumps({
            "message": 'Account successfully queued for recycling.',
        })
    }
    return response


def recycle_accounts(nonce: int):
    logging.debug('Recycling Accounts')
    dynamodb = boto3.resource('dynamodb')
    recycle_table = dynamodb.Table(os.environ['RECYCLE_TABLE_NAME'])
    response = recycle_table.scan()
    for item in response['Items']:
        funder = item['funder']
        signer = item['signer']
        unlock = item.get('unlock', 0)
        logging.debug(f'Processing item: Funder: {funder} Signer: {signer} Unlock: {unlock}')

        amount, escrow, actual_unlock = look(funder, signer)
        latest_block = get_latest_block()
        logging.debug(f'Actual Unlock: {actual_unlock}')

        if unlock != actual_unlock:
            logging.debug(f'Updating unlock from {unlock} to {actual_unlock}')
            store_account(funder, signer, actual_unlock)

        if actual_unlock == 0:
            logging.debug('Account is still locked')
            warn(signer, nonce)
            nonce += 1
        elif actual_unlock - 1 < latest_block['timestamp']:
            logging.debug(
              f'Account ({signer}) is unlocked ({unlock - 1} < {latest_block["timestamp"]}). '
              'Initiating pull()'
            )
            pull(
                signer=signer,
                target=funder,
                autolock=True,
                amount=amount,
                escrow=escrow,
                nonce=nonce,
            )
            nonce += 1
            delete_account(signer=signer)
        else:
            logging.debug(f'Account ({signer}) is still in the process of unlocking.')


def main(event, context):
    stage = os.environ['STAGE']
    body = json.loads(event.get('body', {}))

    if is_true(body.get('debug', '')):
        configure_logging(level="DEBUG")

    logging.debug(f'recycle() stage:{stage}')
    logging.debug(f'event: {event}')
    logging.debug(f'context: {context}')
    logging.debug(f'body: {body}')
    funder = body.get('funder', '')
    signer = body.get('signer', '')

    pac_funder = get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET'])

    if funder != pac_funder:
        return invalid_funder(funder, pac_funder)

    funder_keys = keys(funder)
    if signer == '' or signer not in funder_keys:
        return invalid_signer(signer)

    amount, escrow, unlock = look(funder, signer)

    amount_threshold = float("inf")
    escrow_threshold = float("inf")

    if amount > amount_threshold:
        return amount_too_high(amount, amount_threshold)

    if escrow > escrow_threshold:
        return escrow_too_high(escrow, escrow_threshold)

    store_account(funder, signer, unlock)
    return account_queued_response()

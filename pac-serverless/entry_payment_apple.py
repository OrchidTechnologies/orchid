import boto3
import json
import logging
import os
import w3_generic
import payments_apple

from decimal import Decimal
from utils import configure_logging, is_true

configure_logging(level="DEBUG")

def response_error(msg=None):
    logging.warning(msg)
    response = {
        "isBase64Encoded": False,
        "statusCode": 401,
        "headers": {},
        "body": json.dumps({
            "message": msg,
        })
    }
    return response

def response_success(receipt_hash, total_usd):
    msg = f'Successfully processed apple receipt with hash: {receipt_hash} for credit of ${total_usd}.'
    logging.debug(msg)
    response = {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": {},
        "body": json.dumps({
            "message": msg,
            "receipt_hash": receipt_hash,
            "total_usd": total_usd,
        })
    }
    return response


def main(event, context):
    stage = os.environ['STAGE']
    body = json.loads(event.get('body', {}))

    if is_true(body.get('debug', '')):
        configure_logging(level="DEBUG")

    logging.debug(f'refund_failed_txn() stage:{stage}')
    logging.debug(f'event: {event}')
    logging.debug(f'context: {context}')
    logging.debug(f'body: {body}')

    receipt     = body.get('receipt', '')
    bundle_id   = body.get('bundle_id', '')
    account_id  = body.get('account_id', '')
    product_id  = body.get('product_id', None)
    verify_receipt = True
    # todo: add optional existing account

    if os.environ['STAGE'] == 'dev':
        verify_receipt = is_true(body.get('verify_receipt', 'True'))

    if os.environ['STAGE'] != 'dev':
        if body.get('verify_receipt') or body.get('product_id'):
            return response_error("invalid_dev_param")

    msg, receipt_hash, total_usd = payments_apple.handle_receipt(receipt, bundle_id, product_id, stage, verify_receipt)

    if ((account_id is None) or (account_id == '')):
        account_id = receipt_hash

    if (msg == "success"):
        w3_generic.credit_account_balance(account_id, total_usd)
        return response_success(account_id, total_usd)
    else:
        return response_error(msg)

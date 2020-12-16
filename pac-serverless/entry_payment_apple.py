import boto3
import json
import logging
import os
import w3_generic
import payments_apple

from decimal import Decimal
from utils import configure_logging

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
        "statusCode": 201,
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

    receipt          = body.get('receipt', '')
    target_bundle_id = body.get('target_bundle_id', '')

    msg, receipt_hash, total_usd = handle_receipt_apple(receipt, target_bundle_id, Stage)

    if (msg == "success"):
        return response_success(receipt_hash, total_usd)
    else:
        return response_error(msg)

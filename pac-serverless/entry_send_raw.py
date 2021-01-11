import boto3
import json
import logging
import os
import w3_generic

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

def response_success(txnhash,cost_usd):
    logging.debug(f'Transaction submitted with txnhash: {txnhash}.')
    response = {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": {},
        "body": json.dumps({
            "message": 'Transaction submitted with txnhash: {txnhash}.',
            "txnhash": txnhash,
            "cost_usd": cost_usd,
        })
    }
    return response


def main(event, context):
    stage = os.environ['STAGE']
    body = json.loads(event.get('body', {}))

    if is_true(body.get('debug', '')):
        configure_logging(level="DEBUG")

    logging.debug(f'entry_send_raw() stage:{stage}')
    logging.debug(f'event: {event}')
    logging.debug(f'context: {context}')
    logging.debug(f'body: {body}')


    W3WSock     = body.get('W3WSock', '')
    txn         = body.get('txn', '')
    receiptHash = body.get('receiptHash', '')

    txnhash,cost_usd,msg = w3_generic.send_raw(W3WSock,txn,receiptHash)

    if (txnhash != None):
        response_success(txnhash,cost_usd)
    else:
        response_error(msg)

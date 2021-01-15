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

def response_success(txnhash):
    msg = f'Refund for failed transaction with txnhash: {txnhash}.'
    logging.debug(msg)
    response = {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": {},
        "body": json.dumps({
            "message": msg,
            "txnhash": txnhash,
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


    W3WSock     = body.get('W3WSock', '')
    txnhash     = body.get('txnhash', '')
    receiptHash = body.get('receiptHash', '')

    msg  = w3_generic.refund_failed_txn(W3WSock,txnhash,receiptHash)

    if (msg == "success"):
        return response_success(txnhash)
    else:
        return response_error(msg)

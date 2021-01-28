import boto3
import json
import logging
import os
import sys
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
    msg = f'Transaction submitted with txnhash: {txnhash}, cost_usd: {cost_usd}.'
    logging.debug(msg)
    response = {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": {},
        "body": json.dumps({
            "message": msg,
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


    try:
        #W3WSock     = body.get('W3WSock', '')
        W3WSock     = os.environ['WEB3_WEBSOCKET']
        txn         = body.get('txn', '')
        account_id  = body.get('account_id', '')

        txnhash,cost_usd,msg = w3_generic.send_raw(W3WSock,txn,account_id)

        logging.debug(f'send_raw txnhash({txnhash}) cost_usd({cost_usd}) msg({msg}) ')
    except ValueError as e:
        msg = str(e)
    except:
        msg = sys.exc_info()[0]

    if (msg == 'success'):
        return response_success(txnhash,cost_usd)
    else:
        return response_error(msg)

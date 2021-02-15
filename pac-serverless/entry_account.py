import boto3
import json
import logging
import os
import sys
import w3_generic

from web3 import Web3
from boto3.dynamodb.conditions import Key
from decimal import Decimal
from typing import Any, Dict, Optional, Tuple

from utils import configure_logging, is_true, response

configure_logging(level="INFO")


def main(event, context):
    body  = json.loads(event.get('body', {}))
    logging.info(f'event: {event}')
    logging.info(f'context: {context}')
    logging.info(f'body: {body}')

    W3WSock     = os.environ['WEB3_WEBSOCKET']
    account_id  = body.get('account_id')
    logging.info(f'entry_account account_id: {account_id} ')

    account     = w3_generic.dynamodb_read1(os.environ['BALANCES_TABLE_NAME'], 'account_id', account_id)

    if (account is not None):
        return response(200,account)
    else:
        return response(401,{'msg':'account not found!'})

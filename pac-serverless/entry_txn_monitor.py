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
    if os.environ['STAGE'] != 'dev':
        return response(404,{'msg':'Unknown resource.'})

    body  = json.loads(event.get('body', {}))
    logging.info(f'event: {event}')
    logging.info(f'context: {context}')
    logging.info(f'body: {body}')

    mode = os.environ['TXN_MONITOR_MODE']
    if (mode is 'manual'):
        txn_monitor.main(event, context)
        return response(200,{'msg':'Ran txn_monitor.'})
    else:
        return response(401,{'msg':'Txn monitor mode is: {mode}'})

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

from utils import configure_logging, is_true

configure_logging(level="INFO")


def update_txns():

    w3wsmap = w3_generic.get_w3wsock_providers()

    logging.info(f'update_txns  reading DB  w3wsmap: {str(w3wsmap)} ')
    results = w3_generic.dynamodb_readall(os.environ['TXNS_TABLE_NAME'])

    num_txns = results['Count']
    logging.info(f'update_txns  num_txns: {num_txns}')

    for txn in results['Items']:
        w3_generic.update_txn(w3wsmap, txn)
    return

def main(event, context):
#    if os.environ['STAGE'] == 'dev' and os.environ['TXN_MONITOR_MODE'] == 'manual':
#        return

    logging.info('main')
    update_txns()

    return

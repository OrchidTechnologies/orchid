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

def get_transaction_status(W3WSock,txn):

    w3 = Web3(Web3.WebsocketProvider(W3WSock, websocket_timeout=900))

    txnhash     = txn['txnhash']
    eth_txnhash = txn['eth_txnhash']


    logging.info(f'get_transaction_status W3WSock: {W3WSock} txnhash:{txnhash}  eth_txnhash:{eth_txnhash} ')
    success     = True
    txn_receipt = None
    try:
        txn_receipt = w3.eth.getTransactionReceipt(eth_txnhash)
        success     = txn_receipt['status']
    except Exception as e:
        logging.info(f'get_transaction_status exception: {str(e)} ')
        txn_receipt = None

    if (txn_receipt is not None):
        if (success):
            logging.info(f'success (txn_receipt found) ')
            return "success"
        else:
            logging.info(f'error (txn_receipt found) ')
            return  "error"

    pubkey     = txn['from']
    txn_nonce  = txn['nonce']
    cur_nonce  = w3_generic.get_nonce_(w3,pubkey)

    if (cur_nonce > txn_nonce):
        logging.info(f'clobbered {cur_nonce} > {txn_nonce}')
        return "clobbered"
    else:
        logging.info(f'pending {cur_nonce} <= {txn_nonce}')
        return "pending"


def update_txn(txn):
    txnhash     = txn.get('txnhash')
    status      = txn.get('status','')
    account_id  = txn.get('account_id')
    chainId     = txn.get('chainId','1')

    W3WSock     = w3_generic.get_w3wsock_provider(chainId)

    logging.info(f'update_txn txnhash:{txnhash}  status:{status}  account_id:{account_id} chainId:{chainId} W3WSock: {W3WSock}')

    if (account_id is None):
        return txn

    account     = w3_generic.dynamodb_read1(os.environ['BALANCES_TABLE_NAME'], 'account_id', account_id)

    # check txn status
    if (status != 'new'):
        status = get_transaction_status(W3WSock,txn)

    if ((status == 'new') or (status == 'clobbered')):
        txn_vnonce   = int(txn.get('vnonce',0))
        acc_nonces   = account.get('nonces')
        acc_vnonce   = 0
        if (acc_nonces is None):
            acc_vnonce = int(acc_nonces.get(chainId,0))
        acc_nonces = {}
        logging.info(f'update_txn txnhash:{txnhash} new/clobbered  txn_vnonce:{txn_vnonce}  acc_vnonce:{acc_vnonce}')
        if (txn_vnonce == acc_vnonce):
            txn.pop('nonce')
            txn,msg = w3_generic.send_raw(W3WSock,txn)
            logging.info(f'writing txn: {str(txn)}')
            w3_generic.dynamodb_write1(os.environ['TXNS_TABLE_NAME'],txn)
            logging.info(f'txn written')
        return txn

    if ((status == 'success') or (status == 'error')):
        #remove processed txns
        txn_vnonce   = int(txn.get('vnonce'))
        acc_nonces   = account.get('nonces')
        acc_vnonce   = 0
        if (acc_nonces is None):
            acc_nonces = {}
        acc_vnonce = int(acc_nonces.get(chainId,0))
        logging.info(f'update_txn txnhash:{txnhash} success/error  txn_vnonce:{txn_vnonce}  acc_vnonce:{acc_vnonce}')
        acc_vnonce   = max(acc_vnonce, txn_vnonce + 1)
        acc_nonces[chainId] = acc_vnonce
        account['nonces'] = acc_nonces
        w3_generic.dynamodb_write1(os.environ['BALANCES_TABLE_NAME'], account)
        w3_generic.dynamodb_delete1(os.environ['TXNS_TABLE_NAME'],'txnhash',txnhash)
        return txn

    if (status == 'pending'):
        #no op
        logging.info(f'update_txn txnhash:{txnhash} pending')
        return txn

    return txn

def update_txns():

    logging.info(f'update_txns  reading DB')
    results = w3_generic.dynamodb_readall(os.environ['TXNS_TABLE_NAME'])

    num_txns = results['Count']
    logging.info(f'update_txns  num_txns: {num_txns}')

    for txn in results['Items']:
        update_txn(txn)
    return

def main(event, context):

    logging.info('main')
    update_txns()

    return

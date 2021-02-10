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


wei_per_eth = 1000000000000000000


def new_txn(W3WSock,txn,account_id):

    txnhash = cost_usd = msg = None

    to = txn['to']
    if (w3_generic.target_in_whitelist(to) == False):
        msg = f'ERROR sendRaw: txn target: {to} not in whitelist'
        logging.warning(msg)
        return txnhash,cost_usd,msg

    if (account_id is None):
        account_id    = txn.get('from','')
    txn['account_id'] = account_id
    txn['status']     = 'new'

    chainId = txn.get('chainId',1)
    txn['chainId'] = chainId

    account = w3_generic.dynamodb_read1(os.environ['BALANCES_TABLE_NAME'], 'account_id', account_id)
    if (account is None):
        msg = f'account_id:{account_id} not found!'
        logging.warning(msg)
        return txnhash,cost_usd,msg

    balance      = account.get('balance',0.0)
    max_cost_usd = balance

    txn_vnonce   = txn.get('nonce')
    if (txn_vnonce is None):
        txn_vnonce = 0
        acc_nonces = account.get('nonces')
        if (acc_nonces is not None):
            txn_vnonce = acc_nonces.get(chainID,0)

    txn['vnonce']  = txn_vnonce

    txnhash = Web3.keccak(text=f"{chainId}:{account_id}:{txn_vnonce}").hex()
    txn['txnhash'] = txnhash

    usd_per_eth = w3_generic.get_usd_per_x_coinbase('ETH')
    if (usd_per_eth == 0.0):
        usd_per_eth = w3_generic.get_usd_per_x_binance('ETH')

    max_cost_eth = float(max_cost_usd) / float(usd_per_eth)
    max_cost_wei = float(max_cost_eth) * float(wei_per_eth)

    cost_wei     = float(w3_generic.get_txn_cost_wei(txn))

    logging.info(f'new_txn txnhash:{txnhash} cost_wei:{cost_wei} max_cost_wei:{max_cost_wei}')

    if (cost_wei > max_cost_wei):
        msg = f'new_txn cost_wei:{cost_wei} > max_cost_wei:{max_cost_wei}'
        logging.info(msg)
        return txnhash,cost_usd,msg

    #txnhash,cost_wei = send_raw_wei_(w3,txn, privkey,max_cost_wei)

    cost_eth = cost_wei / wei_per_eth
    cost_usd = cost_eth * usd_per_eth

    prev_txn = w3_generic.load_transaction(txnhash)
    prev_cost_usd = 0.0
    if (prev_txn is not None):
        prev_cost_usd = prev_txn['cost_usd']

    new_cost_usd  = cost_usd - prev_cost_usd
    if (new_cost_usd > max_cost_usd):
        msg = f'new_txn new_cost_usd({new_cost_usd}) > max_cost_usd({max_cost_usd})'
        return txnhash,cost_usd,msg

    w3_generic.debit_account_balance(account_id, new_cost_usd)

    txn['from'] = None
    txn['nonce'] = None

    txn['cost_usd'] = cost_usd
    w3_generic.save_transaction(txnhash, txn)

    return txnhash,cost_usd,'success'

def main(event, context):
    stage = os.environ['STAGE']
    body  = json.loads(event.get('body', {}))

    if is_true(body.get('debug', '')):
        configure_logging(level="DEBUG")

    logging.info(f'entry_send_raw() stage:{stage}')
    logging.info(f'event: {event}')
    logging.info(f'context: {context}')
    logging.info(f'body: {body}')

    #W3WSock     = body.get('W3WSock', '')
    W3WSock     = os.environ['WEB3_WEBSOCKET']
    txn         = body.get('txn', '')
    account_id  = body.get('account_id')

    txnhash,cost_usd,msg = new_txn(W3WSock,txn,account_id)
    logging.info(f'send_raw txnhash({txnhash}) cost_usd({cost_usd}) msg({msg}) ')

    if (msg == 'success'):
        return response(200,{'msg':msg,'txnhash':txnhash,'cost_usd':cost_usd})
    else:
        return response(401,{'msg':msg})

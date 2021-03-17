import boto3
import json
import logging
import os
import sys
import w3_generic

from web3 import Web3
from eth_account import Account, messages
from web3.auto import w3

from boto3.dynamodb.conditions import Key
from decimal import Decimal
from typing import Any, Dict, Optional, Tuple

from utils import configure_logging, is_true, response

configure_logging(level="INFO")


wei_per_eth = 1000000000000000000



def new_txn(W3WSock,txn):

    txnhash = cost_usd = msg = None

    to = txn['to']
    if (w3_generic.target_in_whitelist(to) == False):
        msg = f'ERROR sendRaw: txn target: {to} not in whitelist'
        logging.warning(msg)
        return txnhash,cost_usd,msg

    account_id    = txn.get('from','')
    txn['account_id'] = account_id
    txn['status']     = 'new'

    chainId = int(txn.get('chainId',1))
    txn['chainId'] = chainId

    account = w3_generic.dynamodb_read1(os.environ['BALANCES_TABLE_NAME'], 'account_id', account_id)
    if (account is None):
        msg = f'account_id:{account_id} not found!'
        logging.warning(msg)
        return txnhash,cost_usd,msg

    balance      = float(account.get('balance',0.0))
    max_cost_usd = balance

    logging.info(f'account_id: {account_id}  balance: {balance} chainId: {chainId}')

    txn_vnonce   = txn.get('nonce')
    if (txn_vnonce is None):
        txn_vnonce = 0
        logging.info(f' txn_vnonce is none  getting nonces for {account_id}')
        acc_nonces = account.get('nonces')
        if (acc_nonces is not None):
            txn_vnonce = acc_nonces.get(str(chainId),0)
            logging.info(f' acc_nonces: {str(acc_nonces)} chainId: {chainId}  txn_vnonce: {txn_vnonce} ')

    txn['vnonce']  = txn_vnonce

    txnhash = Web3.keccak(text=f"{chainId}:{account_id}:{txn_vnonce}").hex()
    txn['txnhash'] = txnhash

    cost_usd = w3_generic.get_txn_cost_usd(txn)
    prev_txn = w3_generic.load_transaction(txnhash)
    prev_cost_usd = 0.0

    logging.info(f'cost_usd:{cost_usd},prev_cost_usd:{prev_cost_usd}')

    if (prev_txn is not None):
        prev_cost_usd = float(prev_txn['cost_usd'])
        logging.info(f'found prev txn: {str(txn)}')

    new_cost_usd  = max(cost_usd, prev_cost_usd)
    diff_cost_usd = new_cost_usd - prev_cost_usd

    logging.info(f'diff_cost_usd: {diff_cost_usd} = max({cost_usd},{prev_cost_usd}) - {prev_cost_usd} ')

    if (diff_cost_usd > max_cost_usd):
        msg = f'new_txn new_cost_usd({new_cost_usd}) > max_cost_usd({max_cost_usd})'
        return txnhash,cost_usd,msg

    w3_generic.debit_account_balance(account_id, diff_cost_usd)

    txn['from'] = None
    txn['nonce'] = None
    txn['cost_usd'] = new_cost_usd

    logging.info(f'writing txn: {str(txn)}')

    w3_generic.save_transaction(txnhash, txn)

    return txnhash,cost_usd,'success'

def verify_txn_sig(txn, sig):
    txn_s = str(txn).replace("'", '"').replace(' ', '')
    logging.info(f'verify_txn_sig txn_s:')
    logging.info(txn_s)
    message = messages.encode_defunct(text=txn_s)
    rec_pubaddr = w3.eth.account.recover_message(message, signature=sig)
    txn_from = txn['from']
    logging.info(f'verify_txn_sig {txn_from} == {rec_pubaddr}')
    return txn['from'] == rec_pubaddr

def main(event, context):
    stage = os.environ['STAGE']
    body  = json.loads(event.get('body', {}))

    if is_true(body.get('debug', '')):
        configure_logging(level="DEBUG")

    logging.info(f'entry_send_raw() stage:{stage}')
    logging.info(f'event: {event}')
    logging.info(f'context: {context}')
    logging.info(f'body: {body}')

    txn         = json.loads(body.get('txn', ''))
    sig         = body.get('sig', '')
    if (sig != ''):
        if (verify_txn_sig(txn,sig) == False):
            return response(409,{'msg':'Signature verification failure','txnhash':0,'cost_usd':0.0})
            
    #account_id  = body.get('account_id')
    chainId     = txn.get('chainId',1)
    W3WSock     = w3_generic.get_w3wsock_provider(chainId)

    txnhash,cost_usd,msg = new_txn(W3WSock,txn)
    logging.info(f'send_raw txnhash({txnhash}) cost_usd({cost_usd}) msg({msg}) ')

    if (msg == 'success'):
        return response(200,{'msg':msg,'txnhash':txnhash,'cost_usd':cost_usd})
    else:
        return response(401,{'msg':msg,'txnhash':0,'cost_usd':0.0})

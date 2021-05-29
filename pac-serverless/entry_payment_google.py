import boto3
import json
import logging
import os
import w3_generic
import hashlib
import base64
import products

from decimal import Decimal
from utils import configure_logging, is_true, response, get_secret
from typing import Any, Dict, Optional, Tuple
from inapppy import GooglePlayVerifier, InAppPyValidationError

configure_logging(level="DEBUG")


def product_to_usd(product_id: str) -> float:
    mapping = products.get_product_id_mapping('google')
    return mapping.get(product_id, 0)

def verify_(GOOGLE_SERVICE_ACCOUNT_KEY_FILE, purchase_token, product_id, bundle_id):
    """
    Accepts receipt, validates in Google.
    """
    verifier = GooglePlayVerifier(
        bundle_id,
        GOOGLE_SERVICE_ACCOUNT_KEY_FILE,
    )
    response = {'valid': False, 'transactions': []}

    try:
        result = verifier.verify_with_result(
            purchase_token,
            product_id,
            is_subscription=False
        )
    except Exception as e:
        logging.info(f'verify exception: {str(e)} ')
        txn_receipt = None
        return 'Invalid Receipt', None, 0

    # result contains data
    raw_response = result.raw_response
    is_canceled = result.is_canceled
    is_expired = result.is_expired

    print(raw_response)

    receipt_data_str = str(purchase_token).encode('utf-8')
    receipt_hash = hashlib.sha256(receipt_data_str).hexdigest()
    logging.debug(f'receipt_hash: {receipt_hash}')

    total_usd = product_to_usd(product_id)

    msg = 'success'
    if (is_canceled):
        msg = 'Receipt is invalid/canceled'
        total_usd = 0

    if (is_expired):
        msg = 'Receipt is invalid/expired'
        total_usd = 0

    return msg, receipt_hash, total_usd

def main(event, context):
    stage = os.environ['STAGE']
    body = json.loads(event.get('body', {}))

    if is_true(body.get('debug', '')):
        configure_logging(level="DEBUG")

    logging.debug(f'entry_payment_google stage:{stage}')
    logging.debug(f'os.environ: {os.environ}')
    logging.debug(f'event: {event}')
    logging.debug(f'context: {context}')

    logging.debug(f'body: {body}')
    #receipt     = body.get('receipt', '')
    #bundle_id   = body.get('bundle_id', '')
    account_id  = body.get('account_id', '')
    verify_receipt = True
    # todo: add optional existing account

    if os.environ['STAGE'] == 'dev':
        verify_receipt = is_true(body.get('verify_receipt', 'True'))

    if os.environ['STAGE'] != 'dev':
        if body.get('verify_receipt',None) is not None:
            return response(402,{'msg':'invalid_dev_param'})

    GOOGLE_SERVICE_ACCOUNT_KEY_FILE = get_secret('ORCHID_GOOGLE_SERVICE_ACCOUNT2')
    logging.debug(f'{GOOGLE_SERVICE_ACCOUNT_KEY_FILE}')

    GOOGLE_SERVICE_ACCOUNT_KEY = json.loads(GOOGLE_SERVICE_ACCOUNT_KEY_FILE)
    
    purchase_token = body.get('receipt', '')
    product_id = body.get('product_id', '')
    bundle_id  = body.get('bundle_id', 'net.orchid.Orchid')

    msg, receipt_hash, total_usd = verify_(GOOGLE_SERVICE_ACCOUNT_KEY, purchase_token, product_id, bundle_id)

    if ((account_id is None) or (account_id == '')):
        account_id = receipt_hash

    if (msg == "success"):
        logging.debug(f'conditional writing receipt with hash: {receipt_hash}')
        try:
            w3_generic.dynamodb_cwrite1(os.environ['RECEIPT_TABLE_NAME'], 'receipt', receipt_hash )
        except Exception as e:
            logging.info(f'writing receipt exception: {str(e)} ')
            return response(403,{'msg':'Receipt already redeemed'})
        w3_generic.credit_account_balance(account_id, total_usd)
        return response(200,{'msg':msg,'account_id':account_id,'total_usd':total_usd})
    else:
        return response(402,{'msg':msg})

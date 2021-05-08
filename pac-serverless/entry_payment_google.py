import boto3
import json
import logging
import os
import w3_generic
import products

from decimal import Decimal
from utils import configure_logging, is_true, response
from typing import Any, Dict, Optional, Tuple
from inapppy import GooglePlayVerifier, InAppPyValidationError

configure_logging(level="DEBUG")


def product_to_usd(product_id: str) -> float:
    mapping = products.get_product_id_mapping('google')
    return mapping.get(product_id, 0)

def verify_receipt(GOOGLE_SERVICE_ACCOUNT_KEY_FILE, receipt):
    """
    Accepts receipt, validates in Google.
    """
    purchase_token = receipt['purchaseToken']
    product_id = receipt['productId']
    bundle_id  = receipt['packageName']
    verifier = GooglePlayVerifier(
        bundle_id,
        GOOGLE_SERVICE_ACCOUNT_KEY_FILE,
    )
    response = {'valid': False, 'transactions': []}

    result = verifier.verify_with_result(
        purchase_token,
        product_sku,
        is_subscription=True
    )

    # result contains data
    raw_response = result.raw_response
    is_canceled = result.is_canceled
    is_expired = result.is_expired

    print(raw_response)

    receipt_data_str = purchase_token
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

    logging.debug(f'refund_failed_txn() stage:{stage}')
    logging.debug(f'event: {event}')
    logging.debug(f'context: {context}')

    logging.debug(f'body: {body}')
    receipt     = body.get('receipt', '')
    #bundle_id   = body.get('bundle_id', '')
    account_id  = body.get('account_id', '')
    verify_receipt = True
    # todo: add optional existing account

    if os.environ['STAGE'] == 'dev':
        verify_receipt = is_true(body.get('verify_receipt', 'True'))

    if os.environ['STAGE'] != 'dev':
        if body.get('verify_receipt') or body.get('product_id'):
            return response(402,{'msg':'invalid_dev_param'})

    GOOGLE_SERVICE_ACCOUNT_KEY_FILE = os.environ['ORCHID_GOOGLE_SERVICE_ACCOUNT2']
    
    msg, receipt_hash, total_usd = verify_receipt(GOOGLE_SERVICE_ACCOUNT_KEY_FILE, receipt)

    if ((account_id is None) or (account_id == '')):
        account_id = receipt_hash

    if (msg == "success"):
        logging.debug(f'conditional writing receipt with hash: {receipt_hash}')
        w3_generic.dynamodb_cwrite1(os.environ['RECEIPT_TABLE_NAME'], 'receipt', receipt_hash )
        w3_generic.credit_account_balance(account_id, total_usd)
        return response(200,{'msg':msg,'account_id':account_id,'total_usd':total_usd})
    else:
        return response(402,{'msg':msg})

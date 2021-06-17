import boto3
import json
import logging
import os
import w3_generic
import payments_apple

from decimal import Decimal
from utils import configure_logging, is_true, response

configure_logging(level="DEBUG")

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
    product_id  = body.get('product_id', None)
    verify_receipt = True
    # todo: add optional existing account

    if os.environ['STAGE'] == 'dev':
        verify_receipt = is_true(body.get('verify_receipt', 'True'))

    if os.environ['STAGE'] != 'dev':
        if body.get('verify_receipt'):
            return response(402,{'msg':'invalid_dev_param'})

    msg, receipt_hash, total_usd = payments_apple.handle_receipt(receipt, product_id, stage, verify_receipt)

    if ((account_id is None) or (account_id == '')):
        account_id = receipt_hash

    if (msg == "success"):
        logging.debug(f'conditional writing receipt with hash: {receipt_hash}')
        try:
            w3_generic.dynamodb_cwrite1(os.environ['RECEIPT_TABLE_NAME'], 'receipt', receipt_hash )
        except Exception as e:
            logging.info(f'writing receipt exception: {str(e)} ')
            return response(403,{'msg':f'Receipt {receipt_hash} already redeemed'})
        w3_generic.credit_account_balance(account_id, total_usd)
        return response(200,{'msg':msg,'account_id':account_id,'total_usd':total_usd})
    else:
        return response(402,{'msg':msg})

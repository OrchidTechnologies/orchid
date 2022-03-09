import boto3
import json
import logging
import os
import requests
#import sha3
import time
import hashlib
import base64
import products

from decimal import Decimal
from ecdsa import SigningKey, SECP256k1
from inapppy import AppStoreValidator, InAppPyValidationError
from typing import Any, Dict, Optional, Tuple
from asn1crypto.cms import ContentInfo
from utils import configure_logging, is_true



def get_product_id_mapping(store: str = 'apple') -> dict:
    return products.get_product_id_mapping(store)


def hash_receipt_body(receipt):

    # receipt_hash = hashlib.sha256(receipt.encode('utf-8')).hexdigest()

    # Load the contents of the receipt file
    # receipt_file = open('./receipt_data.bin', 'rb').read()
    logging.debug('hashing receipt')
    # receipt_file = bytearray.fromhex(receipt);
    # receipt_file = bytes.fromhex(receipt)
    receipt_file = base64.decodebytes(receipt.encode('utf-8'))

    # Use asn1crypto's cms definitions to parse the PKCS#7 format
    pkcs_container = ContentInfo.load(receipt_file)

    # Extract the certificates, signature, and receipt_data
    certificates = pkcs_container['content']['certificates']
    signer_info = pkcs_container['content']['signer_infos'][0]
    receipt_data = pkcs_container['content']['encap_content_info']['content']
    logging.debug(
      f'extracted certificates {len(str(certificates))}B signer_info {len(str(signer_info))}B '
      f'receipt_data {len(str(receipt_data))}B'
    )

    receipt_data_str = str(receipt_data).encode('utf-8')[50:]  # slice the string to remove random header
    logging.debug(f'receipt_data_str: \n{receipt_data_str}')

    receipt_hash = hashlib.sha256(receipt_data_str).hexdigest()
    logging.debug(f'receipt_hash: {receipt_hash}')

    return receipt_hash

def hash_string(x):
    data_str = str(x).encode('utf-8')
    logging.debug(f'hash_string: {data_str}')

    data_hash = hashlib.sha256(data_str).hexdigest()
    logging.debug(f'data_hash: {data_hash}')

    return data_hash

def process_app_pay_receipt(
    receipt,
    shared_secret=None
) -> Tuple[bool, dict]:
    bundle_id = os.environ['BUNDLE_ID']
    # if True, automatically query sandbox endpoint
    # if validation fails on production endpoint
    if is_true(os.environ['AUTO_RETRY_WRONG_ENV_REQUEST']):
        auto_retry_wrong_env_request = True
    else:
        auto_retry_wrong_env_request = False
    validator = AppStoreValidator(
        bundle_id=bundle_id,
        sandbox=is_true(os.environ['RECEIPT_SANDBOX']),
        auto_retry_wrong_env_request=auto_retry_wrong_env_request,
    )
    try:
        # if True, include only the latest renewal transaction
        exclude_old_transactions = False
        logging.debug("Validating AppStore Receipt:")
        validation_result: Dict[Any, Any] = validator.validate(
            receipt=receipt,
            shared_secret=shared_secret,
            exclude_old_transactions=exclude_old_transactions
        )
        logging.debug(f'Validation Result: {validation_result}')
    except InAppPyValidationError as ex:
        # handle validation error
        # contains actual response from AppStore service.
        response_from_apple = ex.raw_response
        logging.debug(f"validation failure: {response_from_apple}")
        return (False, response_from_apple)

    return (True, validation_result)


def wildcard_product_to_usd(product_id: str) -> float:
    mapping = products.get_product_id_mapping()
    for id in mapping:
        if id.split('.')[-1] == product_id.split('.')[-1]:
            return mapping[id]
    return -1


def product_to_usd(product_id: str) -> float:
    mapping = products.get_product_id_mapping()
    return mapping.get(product_id, -1)

def handle_receipt(receipt, product_id_claim, Stage, verify_receipt):

    # extract and hash the receipt body payload
    #receipt_hash = hash_receipt_body(receipt)

    apple_response = process_app_pay_receipt(receipt)

    if (verify_receipt) and (apple_response[0] is None):
        return f"invalid_receipt: {apple_response[1]}", None, 0

    validation_result: dict = apple_response[1]
    bundle_id = 0

    if (verify_receipt):
        if validation_result is None:
            return "invalid_null_bundle_id", None, 0
        else:
            bundle_id = validation_result.get('receipt', {}).get('bundle_id', '')

        if (bundle_id != os.environ['BUNDLE_ID']):
            return f"bad bundle_id{bundle_id} != {os.environ['BUNDLE_ID']}", None, 0

        if (validation_result['receipt']['in_app'] is None) or (len(validation_result['receipt']['in_app']) == 0):
            return "unexpected in_app result is empty", None, 0

    product_objs = validation_result['receipt']['in_app']
    num_products = len(product_objs)
    prod_idx     = num_products-1
    last_product = product_objs[prod_idx]

    receipt_hash = hash_string(last_product['transaction_id'])

    product_id   = last_product['product_id']
    if (product_id_claim is None):
        product_id_claim = product_id
    if product_id != product_id_claim:
        logging.debug(f"handle_receipt_apple  invalid_product_id  {product_id} != {product_id_claim}")
        return f"invalid_product_id {product_id} != {product_id_claim}", None, 0

    quantity = int(last_product['quantity'])
    if Stage == 'dev':
        total_usd = wildcard_product_to_usd(product_id=product_id) * quantity
    else:
        total_usd = product_to_usd(product_id=product_id) * quantity

    logging.debug(f"handle_receipt_apple  product_id: {product_id}  bundle_id: {bundle_id}  quantity: {quantity}  total_usd: {total_usd}")

    if total_usd <= 0:
        return "invalid_product_id total_usd <= 0", None, 0

    return "success", receipt_hash, total_usd

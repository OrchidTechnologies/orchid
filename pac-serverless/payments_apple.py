import boto3
import json
import logging
import os
import requests
import sha3
import time
import hashlib
import base64

from decimal import Decimal
from ecdsa import SigningKey, SECP256k1
from inapppy import AppStoreValidator, InAppPyValidationError
from typing import Any, Dict, Optional, Tuple
from asn1crypto.cms import ContentInfo
from utils import configure_logging, is_true



def get_product_id_mapping(store: str = 'apple') -> dict:
    mapping = {}
    mapping['apple'] = {
        'net.orchid.pactier1': 39.99,
        'net.orchid.pactier2': 79.99,
        'net.orchid.pactier3': 199.99,
        'net.orchid.pactier4': 0.99,
        'net.orchid.pactier5': 9.99,
        'net.orchid.pactier6': 99.99
    }
#     mapping['google'] = {
#         'net.orchid.pactier1': 4.99,
#         'net.orchid.pactier2': 9.99,
#         'net.orchid.pactier3': 19.99,
#     }
    return mapping.get(store, {})


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
    mapping = get_product_id_mapping()
    for id in mapping:
        if id.split('.')[-1] == product_id.split('.')[-1]:
            return mapping[id]
    return -1


def product_to_usd(product_id: str) -> float:
    mapping = get_product_id_mapping()
    return mapping.get(product_id, -1)

def handle_receipt(receipt, product_id, Stage, verify_receipt):

    # extract and hash the receipt body payload
    receipt_hash = hash_receipt_body(receipt)

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

    if (product_id is None):
        product_id = validation_result['receipt']['in_app'][0]['product_id']
    quantity = int(validation_result['receipt']['in_app'][0]['quantity'])

    if Stage == 'dev':
        total_usd = wildcard_product_to_usd(product_id=product_id) * quantity
    else:
        total_usd = product_to_usd(product_id=product_id) * quantity

    logging.debug(f"handle_receipt_apple  product_id: {product_id}  bundle_id: {bundle_id}  quantity: {quantity}  total_usd: {total_usd}")

    if total_usd <= 0:
        return "invalid_product_id total_usd <= 0", None, 0

    return "success", receipt_hash, total_usd

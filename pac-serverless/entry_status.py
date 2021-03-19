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

messages = {
    "": {"en": ""},
    "0.9.24": {"en": "Got 0.9.24"}
}

sellers = {
    100: "seller": "0xabEB207C9C82c80D2c03545A73F234d0544172A2"
}

def main(event, context):
    body  = json.loads(event.get('body', {}))
    logging.info(f'event: {event}')
    logging.info(f'context: {context}')
    logging.info(f'body: {body}')

    client_version  = body.get('client_version', '')
    client_locale = body.get('client_locale', 'en')
    logging.info(f'entry_status client_version: {client_version} ')

    messages_for_version = messages.get(client_version, messages[''])

    products = payments_apple.get_product_id_mapping()

    status = {
        "store_status": 1, # 1 -> up, 0 -> down
        "message": messages_for_version.get(client_locale, messages_for_version['']),
        "sellers": sellers,
        "products": products
    }

    return response(200,status)

import boto3
import logging
import os

from abis import token_abi
from web3 import Web3


w3 = Web3(Web3.WebsocketProvider(os.environ['WEB3_WEBSOCKET'], websocket_timeout=900))


def configure_logging(level=os.environ.get('LOG_LEVEL', "DEBUG")):
    logging.debug(f'Setting log level: {level}')
    if len(logging.getLogger().handlers) > 0:
        # The Lambda environment pre-configures a handler logging to stderr.
        # If a handler is already configured, `.basicConfig` does not execute.
        # Thus we set the level directly.
        logging.getLogger().setLevel(level=level)
    else:
        logging.basicConfig(level=level)


def get_secret(key: str) -> str:
    client = boto3.client('ssm')
    resp: dict = client.get_parameter(
        Name=key,
        WithDecryption=True,
    )
    return resp['Parameter']['Value']


def is_false(value: str) -> bool:
    return value.lower() in ['false', '0', 'no']


def is_true(value: str) -> bool:
    return value.lower() in ['true', '1', 'yes']


def get_token_name(address: str):
    token_addr = w3.toChecksumAddress(address)
    token_contract = w3.eth.contract(
        abi=token_abi,
        address=token_addr,
    )
    token_name = token_contract.functions.name().call()
    logging.debug(f'Token Name: {token_name}')
    return token_name


def get_token_symbol(address: str):
    token_addr = w3.toChecksumAddress(address)
    token_contract = w3.eth.contract(
        abi=token_abi,
        address=token_addr,
    )
    token_symbol = token_contract.functions.symbol().call()
    logging.debug(f'Token Symbol: {token_symbol}')
    return token_symbol


def get_token_decimals(address: str):
    token_addr = w3.toChecksumAddress(address)
    token_contract = w3.eth.contract(
        abi=token_abi,
        address=token_addr,
    )
    token_decimals = token_contract.functions.decimals().call()
    logging.debug(f'Token Decimals: {token_decimals}')
    return token_decimals

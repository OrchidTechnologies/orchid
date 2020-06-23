import logging
import os

from abis import token_abi
from metrics import metric
from utils import configure_logging, get_secret, get_token_decimals, get_token_name, get_token_symbol, is_true
from web3 import Web3


w3 = Web3(Web3.WebsocketProvider(os.environ['WEB3_WEBSOCKET'], websocket_timeout=900))
configure_logging(level="DEBUG")


def get_oxt_balance(address=get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET'])) -> float:
    token_addr = w3.toChecksumAddress(os.environ['TOKEN'])
    token_contract = w3.eth.contract(
        abi=token_abi,
        address=token_addr,
    )
    token_name = get_token_name(token_addr)
    token_symbol = get_token_symbol(token_addr)
    token_decimals = get_token_decimals(token_addr)
    DECIMALS = 10 ** token_decimals
    raw_balance = token_contract.functions.balanceOf(address).call()
    balance = raw_balance / DECIMALS
    logging.info(
        f"Balance of {address}: {balance} {token_name} ({token_symbol})")
    metric(
        metric_name=f"orchid.pac.balance.{token_symbol.lower()}",
        value=balance,
        tags=[
            f'account:{address}',
            f'token_name:{token_name}',
            f'token_symbol:{token_symbol}',
            f'token_decimals:{token_decimals}',
        ]
    )
    return balance


def get_eth_balance(address=get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET'])) -> float:
    token_name = 'Ethereum'
    token_symbol = 'ETH'
    token_decimals = 18
    DECIMALS = 10 ** token_decimals
    raw_balance = w3.eth.getBalance(address)
    balance = raw_balance / DECIMALS
    logging.info(
        f"Balance of {address}: {balance} {token_name} ({token_symbol})")
    metric(
        metric_name=f"orchid.pac.balance.{token_symbol.lower()}",
        value=balance,
        tags=[
            f'account:{address}',
            f'token_name:{token_name}',
            f'token_symbol:{token_symbol}',
            f'token_decimals:{token_decimals}',
        ]
    )
    return balance


def check_oxt():
    warn_threshold = float(os.environ['OXT_WARN_THRESHOLD'])
    alert_threshold = float(os.environ['OXT_ALERT_THRESHOLD'])
    balance = get_oxt_balance()
    if balance >= alert_threshold:
        alert(
            message="OXT Balance is critically low!",
            value=balance,
            threshold=alert_threshold,
        )
    elif balance >= warn_threshold:
        warn(
            message="OXT Balance is getting low!",
            value=balance,
            threshold=warn_threshold,
        )
    else:
        ok(
            message=f"OXT Balance of {balance} is within acceptable bounds.",
            value=balance,
        )


def ok(message: str, value: float):
    pass


def warn(message: str, value: float, threshold: float):
    pass


def alert(message: str, value: float, threshold: float):
    pass


def main(event, context):
    configure_logging(level="DEBUG")
    logging.debug(f'Event: {event}')
    logging.debug(f'Context: {context}')

    get_oxt_balance()
    get_eth_balance()


if __name__ == "__main__":
    main(event='', context='')

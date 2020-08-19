import logging
import os

from abis import lottery_abi, token_abi
from eth_account.messages import encode_defunct
from utils import configure_logging, get_secret
from web3 import Web3


configure_logging()


def refresh_w3(w3=None):
    if not w3 or not w3.isConnected():
        logging.debug('Refreshing Web3 Connection...')
        w3 = Web3(Web3.WebsocketProvider(os.environ['WEB3_WEBSOCKET'], websocket_timeout=900))
    if not w3 or not w3.isConnected():
        raise Exception('Unable to establish connection to Web3!')
    return w3


def get_token_name(address: str = os.environ['TOKEN']):
    logging.debug(f'get_token_name() address: {address}')
    w3 = refresh_w3()
    token_contract = w3.eth.contract(
        abi=token_abi,
        address=address,
    )
    token_name = token_contract.functions.name().call()
    logging.debug(f'Token Name: {token_name}')
    return token_name


def get_token_symbol(address: str = os.environ['TOKEN']):
    logging.debug(f'get_token_symbol() address: {address}')
    w3 = refresh_w3()
    token_contract = w3.eth.contract(
        abi=token_abi,
        address=address,
    )
    token_symbol = token_contract.functions.symbol().call()
    logging.debug(f'Token Symbol: {token_symbol}')
    return token_symbol


def get_token_decimals(address: str = os.environ['TOKEN']):
    logging.debug(f'get_token_decimals() address: {address}')
    w3 = refresh_w3()
    token_contract = w3.eth.contract(
        abi=token_abi,
        address=address,
    )
    token_decimals = token_contract.functions.decimals().call()
    logging.debug(f'Token Decimals: {token_decimals}')
    return token_decimals


def balanceOf(address: str, token_addr: str = os.environ['TOKEN']) -> float:
    logging.debug(f'balanceOf() address: {address} token_addr: {token_addr}')
    w3 = refresh_w3()
    token_contract = w3.eth.contract(
      abi=token_abi,
      address=token_addr,
    )
    balance = token_contract.functions.balanceOf(address).call()
    logging.debug(f'balanceOf {address}: {balance}')
    return balance


def get_eth_balance(address: str) -> float:
    logging.debug(f'get_eth_balance() address: {address}')
    w3 = refresh_w3()
    balance = w3.eth.getBalance(address)
    logging.debug(f'ETH Balance of {address}: {balance}')
    return balance


def look(funder: str, signer: str):
    logging.debug(f'look() funder: {funder} signer: {signer}')
    w3 = refresh_w3()
    lottery_addr = w3.toChecksumAddress(os.environ['LOTTERY'])
    edited_lottery_abi = lottery_abi.copy()
    for function in edited_lottery_abi:
        if function.get('name') == 'look':
            for output in function['outputs']:
                if output['type'] == 'bytes':
                    output['type'] = 'uint256'
                    break
            break
    lottery_contract = w3.eth.contract(
        abi=edited_lottery_abi,
        address=lottery_addr,
    )
    amount, escrow, unlock, _, _, _ = lottery_contract.functions.look(funder, signer).call()
    account_total = amount + escrow
    logging.debug(
      f'Account Total (funder: {funder}, signer: {signer}): {amount} (amount) + '
      f'{escrow} (escrow) = {account_total} (total)'
    )
    return amount, escrow, unlock


def keys(funder: str):
    logging.debug(f'keys() funder: {funder}')
    w3 = refresh_w3()
    lottery_addr = os.environ['LOTTERY']
    lottery_contract = w3.eth.contract(
        abi=lottery_abi,
        address=lottery_addr,
    )
    keys = lottery_contract.functions.keys(funder).call()

    logging.debug(f'keys: {keys}')
    return keys


def warn(signer: str, nonce: int):
    logging.debug(f'warn() signer: {signer} nonce: {nonce}')
    w3 = refresh_w3()
    lottery_addr = w3.toChecksumAddress(os.environ['LOTTERY'])
    gas_price = int(os.environ['DEFAULT_GAS'])
    funder_pubkey = get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET'])
    funder_privkey = get_secret(key=os.environ['PAC_FUNDER_PRIVKEY_SECRET'])
    lottery_contract = w3.eth.contract(
        abi=lottery_abi,
        address=lottery_addr,
    )
    warn_txn = lottery_contract.functions.warn(
        signer,
    ).buildTransaction(
        {
            'chainId': 1,
            'from': funder_pubkey,
            'gas': 50000,
            'gasPrice': w3.toWei(gas_price, 'gwei'),
            'nonce': nonce,
        }
    )
    logging.debug(warn_txn)
    warn_txn_signed = w3.eth.account.sign_transaction(
        warn_txn,
        private_key=funder_privkey,
    )
    logging.debug(warn_txn_signed)

    logging.debug('Submitting warn transaction')

    warn_txn_hash = w3.eth.sendRawTransaction(
        warn_txn_signed.rawTransaction,
    )
    logging.debug(f"Submitted warn transaction with hash: {warn_txn_hash.hex()}")
    return warn_txn_hash.hex()


def kill(signer: str, nonce: int):
    logging.debug(f'kill() signer: {signer} nonce: {nonce}')
    w3 = refresh_w3()
    lottery_addr = w3.toChecksumAddress(os.environ['LOTTERY'])
    gas_price = int(os.environ['DEFAULT_GAS'])
    funder_pubkey = get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET'])
    funder_privkey = get_secret(key=os.environ['PAC_FUNDER_PRIVKEY_SECRET'])
    lottery_contract = w3.eth.contract(
        abi=lottery_abi,
        address=lottery_addr,
    )
    kill_txn = lottery_contract.functions.kill(
        signer,
    ).buildTransaction(
        {
            'chainId': 1,
            'from': funder_pubkey,
            'gas': 150000,
            'gasPrice': w3.toWei(gas_price, 'gwei'),
            'nonce': nonce,
        }
    )
    logging.debug(kill_txn)
    kill_txn_signed = w3.eth.account.sign_transaction(
        kill_txn,
        private_key=funder_privkey,
    )
    logging.debug(kill_txn_signed)

    logging.debug('Submitting kill transaction')

    kill_txn_hash = w3.eth.sendRawTransaction(
        kill_txn_signed.rawTransaction,
    )
    logging.debug(f"Submitted warn transaction with hash: {kill_txn_hash.hex()}")
    return kill_txn_hash.hex()


def pull(signer: str, target: str, autolock: bool, amount: float, escrow: float, nonce: int):
    logging.debug(
      f'pull() signer: {signer} target: {target} autolock: {autolock} amount: {amount} '
      f'escrow: {escrow} nonce: {nonce}'
    )
    w3 = refresh_w3()
    lottery_addr = w3.toChecksumAddress(os.environ['LOTTERY'])
    gas_price = int(os.environ['DEFAULT_GAS'])
    funder_pubkey = get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET'])
    funder_privkey = get_secret(key=os.environ['PAC_FUNDER_PRIVKEY_SECRET'])
    lottery_contract = w3.eth.contract(
        abi=lottery_abi,
        address=lottery_addr,
    )
    pull_txn = lottery_contract.functions.pull(
        signer,
        target,
        autolock,
        amount,
        escrow,
    ).buildTransaction(
        {
            'chainId': 1,
            'from': funder_pubkey,
            'gas': 150000,
            'gasPrice': w3.toWei(gas_price, 'gwei'),
            'nonce': nonce,
        }
    )
    logging.debug(pull_txn)
    pull_txn_signed = w3.eth.account.sign_transaction(
        pull_txn,
        private_key=funder_privkey,
    )
    logging.debug(pull_txn_signed)

    logging.debug('Submitting pull transaction')

    pull_txn_hash = w3.eth.sendRawTransaction(
        pull_txn_signed.rawTransaction,
    )
    logging.debug(f'Submitted pull transaction with hash: {pull_txn_hash.hex()}')
    return pull_txn_hash.hex()


def approve(spender: str, amount: float, nonce: int, gas_price: float = float(os.environ['DEFAULT_GAS'])):
    logging.debug(f'approve() spender: {spender} amount: {amount} gas_price: {gas_price} nonce: {nonce}')

    w3 = refresh_w3()

    funder_pubkey = get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET'])
    funder_privkey = get_secret(key=os.environ['PAC_FUNDER_PRIVKEY_SECRET'])

    token_addr = w3.toChecksumAddress(os.environ['TOKEN'])
    token_contract = w3.eth.contract(
        abi=token_abi,
        address=token_addr,
    )

    approve_txn = token_contract.functions.approve(
        spender,
        amount,
    ).buildTransaction(
        {
            'chainId': 1,
            'from': funder_pubkey,
            'gas': 50000,
            'gasPrice': w3.toWei(gas_price, 'gwei'),
            'nonce': nonce,
        }
    )
    logging.debug(f'approve_txn: {approve_txn}')

    approve_txn_signed = w3.eth.account.sign_transaction(
        approve_txn,
        private_key=funder_privkey,
    )
    logging.debug(f'approve_txn_signed: {approve_txn_signed}')

    approve_txn_hash = w3.eth.sendRawTransaction(approve_txn_signed.rawTransaction)
    logging.debug(f'Submitted approve transaction with hash: {approve_txn_hash.hex()}')
    return approve_txn_hash.hex()


def bind(
  signer: str,
  verifier: str,
  nonce: int,
  shared: str = '0x',
  gas_price: float = float(os.environ['DEFAULT_GAS'])
  ):
    logging.debug(
      f'bind() signer: {signer} verifier: {verifier} shared: {shared} '
      f'nonce: {nonce} gas_price: {gas_price}'
    )

    w3 = refresh_w3()

    funder_pubkey = get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET'])
    funder_privkey = get_secret(key=os.environ['PAC_FUNDER_PRIVKEY_SECRET'])

    lottery_addr = w3.toChecksumAddress(os.environ['LOTTERY'])
    lottery_contract = w3.eth.contract(
        abi=lottery_abi,
        address=lottery_addr,
    )

    bind_txn = lottery_contract.functions.bind(
        signer,
        verifier,
        shared,
    ).buildTransaction(
        {
            'chainId': 1,
            'from': funder_pubkey,
            'gas': 200000,
            'gasPrice': w3.toWei(gas_price, 'gwei'),
            'nonce': nonce,
        }
    )
    logging.debug(f'bind_txn: {bind_txn}')

    bind_txn_signed = w3.eth.account.sign_transaction(
      bind_txn,
      private_key=funder_privkey,
    )
    logging.debug(f'bind_txn_signed: {bind_txn_signed}')

    bind_txn_hash = w3.eth.sendRawTransaction(bind_txn_signed.rawTransaction)
    logging.debug(f'Submitted bind transaction with hash: {bind_txn_hash.hex()}')
    return bind_txn_hash.hex()


def push(signer: str, total: float, escrow: float, nonce: int, gas_price: float = float(os.environ['DEFAULT_GAS'])):
    logging.debug(f'push() signer: {signer} total: {total} escrow: {escrow} nonce: {nonce} gas_price: {gas_price}')

    w3 = refresh_w3()

    funder_pubkey = get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET'])
    funder_privkey = get_secret(key=os.environ['PAC_FUNDER_PRIVKEY_SECRET'])

    lottery_addr = w3.toChecksumAddress(os.environ['LOTTERY'])
    lottery_contract = w3.eth.contract(
        abi=lottery_abi,
        address=lottery_addr,
    )

    push_txn = lottery_contract.functions.push(
        signer,
        total,
        escrow,
    ).buildTransaction(
        {
            'chainId': 1,
            'from': funder_pubkey,
            'gas': 200000,
            'gasPrice': w3.toWei(gas_price, 'gwei'),
            'nonce': nonce,
        }
    )
    logging.debug(f'push_txn: {push_txn}')

    push_txn_signed = w3.eth.account.sign_transaction(
      push_txn,
      private_key=funder_privkey,
    )
    logging.debug(f'push_txn_signed: {push_txn_signed}')

    push_txn_hash = w3.eth.sendRawTransaction(push_txn_signed.rawTransaction)
    logging.debug(f'Submitted push transaction with hash: {push_txn_hash.hex()}')
    return push_txn_hash.hex()


def get_nonce() -> int:
    logging.debug('get_nonce()')
    w3 = refresh_w3()

    funder_pubkey = get_secret(key=os.environ['PAC_FUNDER_PUBKEY_SECRET'])
    nonce = w3.eth.getTransactionCount(account=funder_pubkey)
    logging.debug(f'nonce: {nonce}')
    return nonce


def get_latest_block():
    logging.debug('get_latest_block()')
    w3 = refresh_w3()

    latest_block = w3.eth.getBlock('latest')
    logging.debug(f'latest_block: {latest_block}')
    return latest_block


def get_transaction_confirm_count(txhash, blocknum):
    logging.debug(f'get_transaction_confirm_count({txhash})')
    w3 = refresh_w3()
    # blocknum = w3.eth.blockNumber
    # block = w3.eth.getBlock('latest')
    # blocknum2 = block['number']
    trans = w3.eth.getTransaction(txhash)
    diff = blocknum - trans['blockNumber']
    logging.debug(f'get_transaction_confirm_count({txhash}): blocknum({blocknum}) diff({diff}) ')
    return diff


def get_block_number():
    logging.debug('get_block_number()')
    w3 = refresh_w3()
    blockNumber = w3.eth.blockNumber
    logging.debug(f'Block Number: {blockNumber}')
    return blockNumber


def toWei(value: float, currency: str):
    logging.debug(f'toWei() value: {value} currency: {currency}')
    w3 = refresh_w3()
    wei = w3.toWei(value, currency)
    logging.debug(f'wei: {wei}')
    return wei


def toChecksumAddress(address):
    logging.debug(f'toChecksumAddress() address: {address}')
    w3 = refresh_w3()
    checksum = w3.toChecksumAddress(address)
    logging.debug(f'checksum: {checksum}')
    return checksum


def allowance(owner: str, spender: str = os.environ['LOTTERY']):
    logging.debug(f'allowance() owner: {owner} spender: {spender}')
    w3 = refresh_w3()
    token_contract = w3.eth.contract(
        abi=token_abi,
        address=os.environ['TOKEN'],
    )
    spending_allowance = token_contract.functions.allowance(owner, spender).call()
    logging.debug(f'Spending Allowance of {owner} by {spender}: {spending_allowance}')
    return spending_allowance


def verifyMessage(message_text: str, signed_message: str):
    logging.debug(f'verifyMessage() message_text: {message_text} signed_message: {signed_message}')
    w3 = refresh_w3()
    message = encode_defunct(text=message_text)
    verified = w3.eth.account.recover_message(message, signature=signed_message)
    logging.debug(f'Verified: {verified}')
    return verified

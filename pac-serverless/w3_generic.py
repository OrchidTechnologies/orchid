import logging
import os
import requests
import random
from web3 import Web3

LocalTest = False


if (LocalTest == False):

    import boto3
    from boto3.dynamodb.conditions import Key

    def dynamodb_readall(tableName):
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(os.environ['tableName'])
        results = table.query()
        return results

    def dynamodb_read1(tableName, keyname, key):
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(os.environ['tableName'])
        results = table.query(ConsistentRead=True, KeyConditionExpression=Key(keyname).eq(key))
        result = None
        if (results['Count'] > 0):  # we found a match, return it
            result = results['Items'][0]
        return result

    def dynamodb_write1(tableName, item):
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(os.environ['tableName'])
        ddb_item = json.loads(json.dumps(item), parse_float=Decimal)  # Work around DynamoDB lack of float support
        table.put_item(Item=ddb_item)
        return item

    def get_account_balance(receiptHash):
        item = dynamodb_read1('BALANCES_TABLE_NAME', 'receiptHash', receiptHash)
        balance = 0
        if (item != None):
            balance = item['balance']
        return balance

    def credit_account_balance(receiptHash, cost_usd):
        item = dynamodb_read1('BALANCES_TABLE_NAME', 'receiptHash', receiptHash)
        balance = 0
        if (item != None):
            balance = item['balance'] = item['balance'] + cost_usd
            dynamodb_write1('BALANCES_TABLE_NAME', item)
        return balance

    def debit_account_balance(receiptHash, cost_usd):
        item = dynamodb_read1('BALANCES_TABLE_NAME', 'receiptHash', receiptHash)
        balance = 0
        if (item != None):
            balance = item['balance'] = item['balance'] - cost_usd
            dynamodb_write1('BALANCES_TABLE_NAME', item)
        return balance

    def save_transaction(txnhash, txn):
        txn['txnhash'] = txnhash
        dynamodb_write1('TXNS_TABLE_NAME', txn)
        return txn

    def load_transaction(txnhash):
        txn = dynamodb_read1('TXNS_TABLE_NAME', 'txnhash', txnhash)
        return txn

    def get_executor_account():
        results = dynamodb_readall('EXECUTORS_TABLE_NAME')
        num_execs = results['Count']
        index = randit(0,num_execs-1)
        pubkey = None
        privkey = None
        if (num_execs > 0):
            result = results['Items'][index]
            pubkey = result['pubkey']
            privkey = result['privkey']
        return pubkey,privkey

else :

    balances = {}
    transactions = {}

    def get_account_balance(receiptHash):
        balance = balances[receiptHash]
        return balance

    def credit_account_balance(receiptHash, cost_usd):
        balance = balances[receiptHash] + cost_usd
        return balance

    def debit_account_balance(receiptHash, cost_usd):
        balance = balances[receiptHash] - cost_usd
        return balance

    def save_transaction(txnhash, txn):
        transactions[txnhash] = txn
        return txn

    def load_transaction(txnhash):
        txn = transactions[txnhash]
        return txn

    def get_executor_account():
        pubkey = 0xCA9E026D96829f5805B14Fb8223db4a0822D72a7
        privkey = 0x64a31b5a2cd7d11cfd349cb52408b98b8d9c4161fa3f914929913791e49a4a93
        return pubkey,privkey




def get_usd_per_x_coinbase(token_sym) -> float:
    r = requests.get(url="https://api.coinbase.com/v2/prices/" + token_sym + "-USD/spot")
    data = r.json()
    logging.debug(data)
    usd_per_x = float(0.0);
    if ('data' in data):
        usd_per_x = float(data['data']['amount'])
    else:
        logging.debug(f"invalid token or not found: {token_sym}")
    logging.debug(f"usd_per_x_coinbase {token_sym}: {usd_per_eth}")
    return usd_per_x

# example: OXT ETH BTC DAI BNB AVAX
def get_usd_per_x_binance(token_sym) -> float:
    r = requests.get(url="https://api.binance.com/api/v3/avgPrice?symbol=" + token_sym + "USDT")
    data = r.json()
    logging.debug(data)
    usd_per_x = float(0.0);
    if ('price' in data):
        usd_per_x = float(data['price'])
    else:
        logging.debug(f"invalid token or not found: {token_sym}")
    logging.debug(f"usd_per_x_binance {token_sym}: {usd_per_eth}")
    return usd_per_x

def get_txn_cost_wei(txn):
    value_wei    = txn['value']
    gas          = txn['gas']
    gasPrice     = txn['gasPrice']
    gascost_wei  = gas*gasPrice
    cost_wei     = value_wei + gascost_wei
    return cost_wei

wei_per_eth = 1000000000000000000

def get_txn_cost_usd(txn):
    cost_wei  = get_txn_cost_wei(txn)
    cost_eth  = cost_wei / wei_per_eth
    cost_usd  = cost_eth * usd_per_eth
    return cost_usd

def sendRaw_wei_(w3,txn,  pubkey,privkey,nonce,max_cost_wei):

    cost_wei     = get_txn_cost_wei(txn)
    if (cost_wei > max_cost_wei):
        logging.debug(f'sign_send_Transaction cost_wei({cost_wei}) > max_cost_wei({max_cost_wei})')
        return None,0.0

    #w3       = Web3(Web3.WebsocketProvider(W3WSock, websocket_timeout=900))

    txn['from']  = pubkey
    txn['nonce'] = nonce

    txn_signed = w3.eth.account.sign_transaction(txn, private_key=privkey,)
    logging.debug(f'sign_send_Transaction txn_signed: {txn_signed}')

    txn_hash = w3.eth.sendRawTransaction(txn_signed.rawTransaction)
    logging.debug(f'sign_send_Transaction submitted transaction with hash: {txn_hash.hex()}')
    return txn_hash.hex(),cost_wei


def sendRaw_usd_(w3,txn, pubkey,privkey,nonce,max_cost_usd):

    usd_per_eth = get_usd_per_x_coinbase('ETH')
    if (usd_per_eth == 0.0):
        usd_per_eth = get_usd_per_x_binance('ETH')

    max_cost_eth = max_cost_usd / usd_per_eth
    max_cost_wei = max_cost_eth * wei_per_eth

    txnhash,cost_wei = sendRaw_wei_(w3,txn, pubkey,privkey,nonce,max_cost_wei)

    cost_eth = cost_wei / wei_per_eth
    cost_usd = cost_eth * usd_per_eth

    return txnhash,cost_usd

def get_nonce_(w3,pubkey):
    nonce = w3.eth.getTransactionCount(account=pubkey)
    return nonce


def sendRaw(W3WSock,txn,receiptHash):

    w3 = Web3(Web3.WebsocketProvider(W3WSock, websocket_timeout=900))

    max_cost_usd     = get_account_balance(receiptHash)
    pubkey,privkey   = get_executor_account()
    nonce            = get_nonce_(w3,pubkey)

    txnhash,cost_usd = sendRaw_usd_(w3,txn, pubkey,privkey,nonce,max_cost_usd)

    if (txnhash != None):
        save_transaction(txnhash, txn)
        debit_account_balance(receiptHash, cost_usd)

    return txnhash


def has_transaction_failed(W3WSock,txnhash,txn):

    w3 = Web3(Web3.WebsocketProvider(W3WSock, websocket_timeout=900))
    success     = True
    txn_receipt = None
    try:
        txn_receipt = w3.eth.getTransactionReceipt(txnhash)
        success     = Bool(txn_receipt['status'])
    except (Web3.exceptions.TransactionNotFound, TransactionNotFound):
        txn_receipt = None

    pubkey     = txn['from']
    txn_nonce  = txn['nonce']
    cur_nonce  = get_nonce_(w3,pubkey)

    result = (success == False) or ((txn_receipt == None) and (cur_nonce > txn_nonce))

    return result



def refund_failed_txn(W3WSock,txnhash,receiptHash):

    txn = load_transaction(txnhash)

    if (has_transaction_failed(W3WSock,txn) == False):
        return "error: transaction {} is still pending"

    cost_usd = get_txn_cost_usd(txn)
    credit_account_balance(receiptHash, cost_usd)

    return "success"


'''
def build_sign_send_Transaction(web3_websock,contract_addr,func_name,args,value,gas,gasprice,  pubkey,privkey,nonce,max_cost_usd):
    #w3       = Web3(Web3.WebsocketProvider(os.environ['WEB3_WEBSOCKET'], websocket_timeout=900))
    w3       = Web3(Web3.WebsocketProvider(web3_websock, websocket_timeout=900))
    contract = w3.eth.contract( abi=get_contract_abi(contract_addr), address=contract_addr, )
    #method   = getattr(contract.functions, func_name)
    method   = contract.get_function_by_name(func_name)

    txn = method(**args).buildTransaction(
        {
            'chainId': 1,
            'from': pubkey,
            'gas': gas,
            'gasPrice': gasprice,
            'nonce': nonce,
        }
    )
    logging.debug(f'build_sign_send_Transaction txn: {txn}')

    txn_signed = w3.eth.account.sign_transaction(txn, private_key=privkey,)
    logging.debug(f'build_sign_send_Transaction txn_signed: {txn_signed}')

    txn_hash = w3.eth.sendRawTransaction(txn_signed.rawTransaction)
    logging.debug(f'build_sign_send_Transaction submitted transaction with hash: {txn_hash.hex()}')
    return txn_hash.hex()
'''

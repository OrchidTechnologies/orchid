import boto3
import json
import logging
import os
import sys
import requests
import random

from web3 import Web3
from boto3.dynamodb.conditions import Key
from decimal import Decimal
from typing import Any, Dict, Optional, Tuple

LocalTest = False


def default(obj):
    if isinstance(obj, Decimal):
        return str(obj)
    raise TypeError("Object! of type '%s' is not JSON serializable" % type(obj).__name__)


if (LocalTest == False):

    import boto3
    from boto3.dynamodb.conditions import Key

    def dynamodb_readall(tableName):
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(tableName)
        results = table.scan()
        return results

    def dynamodb_read1(tableName, keyname, key):
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(tableName)
        results = table.query(ConsistentRead=True, KeyConditionExpression=Key(keyname).eq(key))
        result = None
        if (results['Count'] > 0):  # we found a match, return it
            result = results['Items'][0]
        return result

    def dynamodb_write1(tableName, item):
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(tableName)
        ddb_item = json.loads(json.dumps(item,default=default), parse_float=Decimal)  # Work around DynamoDB lack of float support
        table.put_item(Item=ddb_item)
        return item


    def dynamodb_cwrite1(tableName, key, value):
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(tableName)
        item = {key: value}
        ddb_item = json.loads(json.dumps(item), parse_float=Decimal)  # Work around DynamoDB lack of float support
        # fail if already exists, raises ConditionalCheckFailedException
        table.put_item(Item=ddb_item, ConditionExpression='attribute_not_exists(' + key + ')')
        return item;


    def dynamodb_delete1(tableName,keyname,key):
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(tableName)
        delete_response = table.delete_item(Key={keyname: key}, ReturnValues='ALL_OLD')
        return delete_response

    def get_account_balance(account_id):
        account = dynamodb_read1(os.environ['BALANCES_TABLE_NAME'], 'account_id', account_id)
        balance = 0
        if (account is not None):
            balance = account['balance']
        return balance

    def credit_account_balance(account_id, cost_usd):
        logging.info(f"credit_account_balance({account_id},{cost_usd})")
        account = dynamodb_read1(os.environ['BALANCES_TABLE_NAME'], 'account_id', account_id)
        balance = cost_usd
        if (account is None):
            account = {}
            account['nonces'] = {}
        else:
            balance += float(account['balance'])
        account['balance'] = balance
        account['account_id'] = account_id
        dynamodb_write1(os.environ['BALANCES_TABLE_NAME'], account)
        return balance

    def debit_account_balance(account_id, cost_usd):
        logging.info(f"debit_account_balance({account_id},{cost_usd})")
        account = dynamodb_read1(os.environ['BALANCES_TABLE_NAME'], 'account_id', account_id)
        balance = 0
        if (account is not None):
            balance = float(account['balance']) - cost_usd
            account['balance'] = balance
            dynamodb_write1(os.environ['BALANCES_TABLE_NAME'], account)
        else:
            logging.warning(f"debit_account_balance account {account_id} not found")
        return account

    def save_transaction(txnhash, txn):
        txn['txnhash'] = txnhash
        dynamodb_write1(os.environ['TXNS_TABLE_NAME'], txn)
        return txn

    def load_transaction(txnhash):
        txn = dynamodb_read1(os.environ['TXNS_TABLE_NAME'], 'txnhash', txnhash)
        return txn

    def get_executor_account():
        results = dynamodb_readall(os.environ['EXECUTORS_TABLE_NAME'])
        num_execs = results['Count']
        index = random.randint(0,num_execs-1)
        pubkey = None
        privkey = None
        if (num_execs > 0):
            result = results['Items'][index]
            pubkey = result['pubkey']
            privkey = result['privkey']
        logging.info(f"get_executor_account {pubkey} {privkey}")
        return pubkey,privkey

    def target_in_whitelist(pubkey):
        result = dynamodb_read1(os.environ['TARGETS_TABLE_NAME'], 'pubkey', pubkey)
        return result != None


else :

    balances = {}
    transactions = {}
    whitelist_targets = { 0xCA9E026D96829f5805B14Fb8223db4a0822D72a7 }

    def get_account_balance(account_id):
        balance = balances[account_id]
        return balance

    def credit_account_balance(account_id, cost_usd):
        balance = balances[account_id] + cost_usd
        return balance

    def debit_account_balance(account_id, cost_usd):
        balance = balances[account_id] - cost_usd
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

    def target_in_whitelist(target):
        return target in whitelist_targets




def get_usd_per_x_coinbase(token_sym) -> float:
    r = requests.get(url="https://api.coinbase.com/v2/prices/" + token_sym + "-USD/spot")
    data = r.json()
    logging.debug(data)
    usd_per_x = float(0.0);
    if ('data' in data):
        usd_per_x = float(data['data']['amount'])
    else:
        logging.info(f"invalid token or not found: {token_sym}")
    logging.info(f"usd_per_x_coinbase {token_sym}: {usd_per_x}")
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
        logging.info(f"invalid token or not found: {token_sym}")
    logging.info(f"usd_per_x_binance {token_sym}: {usd_per_x}")
    return usd_per_x

def get_txn_cost_wei(txn):
    value_wei    = txn.get('value',0)
    gas          = txn.get('gas',0)
    gasPrice     = txn.get('gasPrice',0)
    gascost_wei  = int(gas,0)*int(gasPrice,0)
    cost_wei     = int(value_wei,0) + int(gascost_wei)
    logging.info(f"get_txn_cost_wei gas({gas}) gasPrice({gasPrice}) gascost_wei({gascost_wei}) cost_wei({cost_wei})")
    return cost_wei

wei_per_eth = 1000000000000000000


def get_txn_cost_usd(txn):
    chainId = txn['chainId']
    symbol = get_symbol_from_chainId(chainId)
    usd_per_eth = get_usd_per_x_coinbase(symbol)
    if (usd_per_eth == 0.0):
        usd_per_eth = get_usd_per_x_binance(symbol)

    cost_wei = float(get_txn_cost_wei(txn))
    cost_eth = cost_wei / wei_per_eth
    cost_usd = cost_eth * usd_per_eth
    logging.info(f'get_txn_cost_usd cost_wei:{cost_wei} cost_usd:{cost_usd}')
    return cost_usd


def get_nonce_(w3,pubkey):
    logging.info(f'get_nonce_ pubkey:{pubkey} type:{type(pubkey)}')
    nonce = w3.eth.getTransactionCount(account=pubkey)
    logging.info(f'get_nonce_ pubkey:{pubkey} nonce:{nonce}')
    return nonce


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

    result = (success == False) or ((txn_receipt is None) and (cur_nonce > txn_nonce))

    return result



def refund_failed_txn(W3WSock,txnhash,account_id):

    # store W3WSock with transaction
    txn = load_transaction(txnhash)
    cost_usd = txn['cost_usd']

    if (cost_usd == 0):
        return f"error: transaction {txnhash} already redeemed"

    if (txn is None):
        return f"error: transaction {txnhash} not found"

    if (has_transaction_failed(W3WSock,txn) == False):
        return f"error: transaction {txnhash} is still pending"

    #symbol = '?'
    #cost_usd = get_txn_cost_usd(txn,symbol)
    credit_account_balance(account_id, cost_usd)

    #erase txn on success
    txn['cost_usd'] = 0
    save_transaction(txn,txnhash)

    return "success"




def send_raw_(w3,txn_,privkey):

    txn   = txn_.copy();

    if ('status' in txn):
        txn.pop('status')
    if ('account_id' in txn):
        txn.pop('account_id')
    if ('txnhash' in txn):
        txn.pop('txnhash')
    if ('vnonce' in txn):
        txn.pop('vnonce')
    if ('cost_usd' in txn):
        txn.pop('cost_usd')
    if ('chainId' in txn):
        txn.pop('chainId')
    if ('eth_txnhash' in txn):
        txn.pop('eth_txnhash')

    txn_s = str(txn)
    logging.info(f'send_raw_ privkey:{privkey}  txn: {txn_s}  ')

    txn_signed = w3.eth.account.sign_transaction(txn, private_key=privkey)
    logging.info(f'sign_send_Transaction txn_signed: {txn_signed} with privkey:{privkey}')

    txn_hash = w3.eth.sendRawTransaction(txn_signed.rawTransaction)
    logging.info(f'sign_send_Transaction submitted transaction with hash: {txn_hash.hex()}')

    return txn_hash.hex()

def send_raw(w3,txn):

    txnhash = txn['txnhash']
    logging.info(f'send_raw  txnhash:{txnhash}')

    #w3 = Web3(Web3.WebsocketProvider(W3WSock, websocket_timeout=900))

    to = txn['to']
    if (target_in_whitelist(to) == False):
        msg = f'ERROR sendRaw: txn target: {to} not in whitelist'
        logging.warning(msg)
        return None,msg

    pubkey = txn['from']

    if (txn.get('from') is None):
        pubkey,privkey = get_executor_account()
        txn['from']    = pubkey

    executor = dynamodb_read1(os.environ['EXECUTORS_TABLE_NAME'], 'pubkey', pubkey)
    privkey  = executor['privkey']

    if (txn.get('nonce') is None):
        nonce        = get_nonce_(w3,pubkey)
        txn['nonce'] = nonce

    logging.info(f'sending txn')

    eth_txnhash = None
    #eth_txnhash = send_raw_(w3,txn,privkey)

    msg = 'success'
    eth_txnhash = send_raw_(w3,txn,privkey)


    """
    try:
        msg = 'success'
        eth_txnhash = send_raw_(w3,txn,privkey)
    except ValueError as e:
        msg = str(e)
        logging.warning(f'ERROR: {msg}')
    except:
        msg = sys.exc_info()[0]
        logging.warning(f'ERRORs: {msg}')

    """


    txn['eth_txnhash'] = eth_txnhash
    txn['status'] = 'pending'

    return txn,msg


def test_connections(providers):

    for x in providers:
        if ((x[0:4] == 'wss:') or (x[0:3] == 'ws:')):
            w3 = Web3(Web3.WebsocketProvider(x, websocket_timeout=400))
        else:
            w3 = Web3(Web3.HTTPProvider(x, request_kwargs={'timeout':3,'headers':{'referer':'https://account.orchid.com'}}) )
        try:
            if (w3.isConnected() == False):
                w3 = None
                logging.info(f'test_connections  {x} not connected')
            #w3.eth.getTransactionCount(account='0xA67D6eCAaE2c0073049BB230FB4A8a187E88B77b')
        except Exception as ex:
            logging.info(f'test_connections  {x}  failure: {str(ex)}')
            w3 = None
        if (w3 is not None):
            logging.info(f'test_connections  {x}  success')
            return w3
    return None


def get_w3wsock_providers():

    providers = {}

    providers[1]   = test_connections([os.environ['WEB3_WEBSOCKET']])
    providers[100] = test_connections(['https://rpc.gnosischain.com','https://rpc.ankr.com/gnosis','https://gnosischain-rpc.gateway.pokt.network','https://gnosis-mainnet.public.blastapi.io'])
    #providers[100] = test_connections(['https://rpc.xdaichain.com/','https://xdai.poanetwork.dev','wss://rpc.xdaichain.com/wss','wss://xdai.poanetwork.dev/wss'])

    logging.info(f'get_w3wsock_providers:  {str(providers)} ')

    return providers

def get_chainIds():
    return [1,100]

def get_w3wsock_provider(chainId_):

    W3WSock = None
    chainId = int(chainId_)
    if (chainId == 1):
        W3WSock = os.environ['WEB3_WEBSOCKET']
    if (chainId == 100):
        W3WSock = 'wss://rpc.xdaichain.com/wss'

    logging.info(f'get_w3wsock_provider  chainId:{chainId} W3WSock:{W3WSock}')

    return W3WSock

def get_symbol_from_chainId(chainId_):
    symbol = None
    chainId = int(chainId_)
    if (chainId == 1):
        symbol = 'ETH'
    if (chainId == 100):
        symbol = 'DAI'
    return symbol


def get_transaction_status(w3,txn):

    txnhash     = txn['txnhash']
    eth_txnhash = txn['eth_txnhash']

    logging.info(f'get_transaction_status  txnhash:{txnhash}  eth_txnhash:{eth_txnhash} ')
    success     = True
    txn_receipt = None
    try:
        txn_receipt = w3.eth.getTransactionReceipt(eth_txnhash)
        success     = txn_receipt['status']
    except Exception as e:
        logging.info(f'get_transaction_status exception: {str(e)} ')
        txn_receipt = None

    if (txn_receipt is not None):
        if (success):
            logging.info(f'success (txn_receipt found) ')
            return "success"
        else:
            logging.info(f'error (txn_receipt found) ')
            return  "error"

    pubkey     = txn['from']
    txn_nonce  = txn['nonce']
    cur_nonce  = get_nonce_(w3,pubkey)

    if (cur_nonce > txn_nonce):
        logging.info(f'clobbered {cur_nonce} > {txn_nonce}')
        return "clobbered"
    else:
        logging.info(f'pending {cur_nonce} <= {txn_nonce}')
        return "pending"


def update_txn(w3wsmap, txn):
    txnhash     = txn.get('txnhash')
    status      = txn.get('status','')
    account_id  = txn.get('account_id')
    chainId     = int(txn.get('chainId','1'))
    logging.info(f'update_txn w3wsmap: {str(w3wsmap)} txnhash:{txnhash}  status:{status}  account_id:{account_id} chainId:{chainId} ')

    w3          = w3wsmap.get(int(chainId))

    if (w3 is None):
        msg = f'w3 provider for chainId:{chainId} not found!'
        logging.error(msg)
        raise Exception(msg)
        return txn

    if (account_id is None):
        return txn

    account     = dynamodb_read1(os.environ['BALANCES_TABLE_NAME'], 'account_id', account_id)

    # check txn status
    if (status != 'new'):
        status = get_transaction_status(w3,txn)

    if ((status == 'new') or (status == 'clobbered')):
        txn_vnonce   = int(txn.get('vnonce',0))
        acc_nonces   = account.get('nonces')
        acc_vnonce   = 0
        if (acc_nonces is not None):
            acc_vnonce = int(acc_nonces.get(str(chainId),0))
        acc_nonces = {}
        logging.info(f'update_txn txnhash:{txnhash} new/clobbered  txn_vnonce:{txn_vnonce}  acc_vnonce:{acc_vnonce}')
        if (txn_vnonce == acc_vnonce):
            txn.pop('nonce')
            txn,msg = send_raw(w3,txn)
            logging.info(f'writing txn: {str(txn)}')
            dynamodb_write1(os.environ['TXNS_TABLE_NAME'],txn)
            logging.info(f'txn written')
        return txn

    if ((status == 'success') or (status == 'error')):
        #remove processed txns
        txn_vnonce   = int(txn.get('vnonce'))
        acc_nonces   = account.get('nonces')
        acc_vnonce   = 0
        if (acc_nonces is None):
            acc_nonces = {}
        acc_vnonce = int(acc_nonces.get(str(chainId),0))
        logging.info(f'update_txn txnhash:{txnhash} success/error  txn_vnonce:{txn_vnonce}  acc_vnonce:{acc_vnonce}')
        acc_vnonce   = max(acc_vnonce, txn_vnonce + 1)
        acc_nonces[str(chainId)] = acc_vnonce
        account['nonces'] = acc_nonces
        logging.info(f'writing account: {str(account)}')
        dynamodb_write1(os.environ['BALANCES_TABLE_NAME'], account)
        logging.info(f'deleting txn: {txnhash}')
        dynamodb_delete1(os.environ['TXNS_TABLE_NAME'],'txnhash',txnhash)
        return txn

    if (status == 'pending'):
        #no op
        logging.info(f'update_txn txnhash:{txnhash} pending')
        return txn

    return txn

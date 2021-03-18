import unittest
import requests
import json
from web3 import Web3
from eth_account.messages import encode_defunct, encode_intended_validator
import sys
from time import sleep
from eth_abi import encode_abi
from eth_abi.packed import encode_single_packed, encode_abi_packed

w3 = None
testdata = {}

empty_nonces = {"100": "0"}

def setUpModule():
    thismod = sys.modules[__name__]
    with open('test_data.json.local') as f:
        data = json.load(f)
        thismod.testdata = data[data['target']]
    thismod.w3 = Web3(Web3.HTTPProvider(thismod.testdata['jsonrpc']))
    thismod.lottery1 = w3.eth.contract(address=thismod.testdata['lottery1']['address'], abi=thismod.testdata['lottery1']['abi'])
    thismod.seller = w3.eth.contract(address=thismod.testdata['seller']['address'], abi=thismod.testdata['seller']['abi'])
    thismod.testdata['accounts'] = []
    acc = thismod.w3.eth.account.create()
    thismod.testdata['accounts'].append(acc)
    print(f"Using account: {acc.address} with key {acc.key.hex()}")

class TestPacService(unittest.TestCase):
    def payment_apple(self, receipt, account_id):
        reqdata = {'receipt': receipt, 'account_id': account_id}
        return requests.post('{}{}'.format(testdata['url'], 'payment_apple'), json=reqdata)

    def get_account(self, account_id):
        reqdata = {'account_id': account_id}
        return requests.post('{}{}'.format(testdata['url'], 'get_account'), json=reqdata)

    def send_raw(self, account_id, chain_id, txn, sig):
        reqdata = {'account_id': account_id, 'chainId': chain_id, 'txn': txn, 'sig': sig}
        return requests.post('{}{}'.format(testdata['url'], 'send_raw'), json=reqdata)

    def add_value_txn(self, acct, l2nonce, balance, deposit):
        chainid = 100
        tokenid = '0x0000000000000000000000000000000000000000'
        amount = int((balance + deposit) * pow(10,18))
        adjust = int(deposit * pow(10,18))
        lock = retrieve = 0
        refill = 1
        acstat = seller.functions.read(acct.address).call()
        print(f"acstat: {acstat}")
        l3nonce = int(('0'*16+hex(acstat)[2:])[-16:], 16)
        print(f"l3nonce: {l3nonce}")
#        msg = encode_abi_packed(['bytes1', 'bytes1', 'address', 'uint256', 'uint64', 'address', 'uint256', 'int256', 'int256', 'uint256', 'uint128'],
#                         [b'\x19', b'\x00', testdata['seller']['address'], chainid, l3nonce, tokenid, amount, adjust, lock, retrieve, refill])
        msg = encode_abi_packed(['uint256', 'uint64', 'address', 'uint256', 'int256', 'int256', 'uint256', 'uint256'],
                         [chainid, l3nonce, tokenid, amount, adjust, lock, retrieve, refill])
        message = encode_intended_validator(validator_address=testdata['seller']['address'], primitive=msg)
        sig = w3.eth.account.sign_message(message, private_key=acct.key)
        txn = {
            "from": acct.address,
            "to": testdata['seller']['address'],
            "gas": hex(175000),
            "gasPrice": hex(pow(10,9)),
            "value": hex(int((balance + deposit) * pow(10,18))),
            "chainId": chainid,
            "nonce": l2nonce,
            "data": seller.encodeABI(fn_name='edit', args=[acct.address, sig.v, bytearray.fromhex(hex(sig.r)[2:]), bytearray.fromhex(hex(sig.s)[2:]), l3nonce, adjust, lock, retrieve, refill]),
        }
        txstr = json.dumps(txn)
        txmsg = encode_defunct(text=txstr)
        print(txmsg)
        txsig = w3.eth.account.sign_message(txmsg, private_key=acct.key).signature.hex()
        print(txsig)
        return txstr, txsig

    def test_00_add_value(self):
        r = self.payment_apple(testdata['receipts'][0]['data'], testdata['accounts'][0].address)
        self.assertEqual(r.status_code, 200)
        response = json.loads(r.text)
        self.assertEqual(response['msg'], 'success')
        self.assertEqual(response['total_usd'], testdata['receipts'][0]['value'])

    @unittest.expectedFailure
    def test_01_check_balance(self):
        id = testdata['accounts'][0].address
        r = self.get_account(id)
        response = json.loads(r.text)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(response['account_id'], id)
        self.assertEqual(float(response['balance']), testdata['receipts'][0]['value'])
        self.assertEqual(response['nonces'], empty_nonces)

    def test_02_create_account(self):
        id = testdata['accounts'][0].address
        txn, sig = self.add_value_txn(testdata['accounts'][0], 0, 0.9, 0.1)
        print("txn: ", txn)
        r = self.send_raw(id, 100, txn, sig)
        print(r.text)
        self.assertEqual(r.status_code, 200)

    def test_03_check_reduced_balance(self):
        id = testdata['accounts'][0].address
        waiting = True
        c = 0
        while waiting:
            r = self.get_account(id)
            response = json.loads(r.text)
            print(r.text)
            if '100' in response['nonces'].keys():
                if int(response['nonces']['100']) > 0:
                    waiting = False
            if c > 24:
                waiting = False
            c += 1
            sleep(5)
        r = self.get_account(id)
        response = json.loads(r.text)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(response['account_id'], id)
        rcpt_val = testdata['receipts'][0]['value']
        balance = float(response['balance'])
        self.assertNotEqual(rcpt_val, balance)
        self.assertTrue(((rcpt_val - (1.1 + balance)) / rcpt_val) < 0.001) # should only differ by gas cost

    def test_04_exceed_balance(self):
        id = testdata['accounts'][0].address
        txn, sig = self.add_value_txn(testdata['accounts'][0], 1, testdata['receipts'][0]['value'] + 10, 1)
        r = self.send_raw(id, 100, txn, sig)
        self.assertEqual(r.status_code, 401)
        # XXX TODO - compare the error msg

TODO = '''
1) Multiple jobs hitting the same executor at the same time
   a) verify all jobs are submitted to the mempool
   b) verify jobs are resubmitted when L1 nonce is consumed
   c) verify all jobs from the same account are dropped when one is successfully mined
2) Transaction failing at blockchain
   a) verify only correct cost is debited from account
3) Transaction succeeding at blockchain
X   a) verify correct cost is debited from account
4) Transaction constraints
   a) verify whitelisting of only the funder contract
X   b) verify transaction requiring more value than account has is rejected
   c) verify L2 nonces higher than current one are rejected
   d) verify L2 nonces lower than current one are rejected
'''

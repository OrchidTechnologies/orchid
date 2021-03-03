import unittest
import requests
import json
from web3 import Web3
import sys

w3 = None
testdata = {}

def setUpModule():
    thismod = sys.modules[__name__]
    with open('test_data.json.local') as f:
        data = json.load(f)
        thismod.testdata = data[data['target']]
    thismod.w3 = Web3(Web3.HTTPProvider(thismod.testdata['jsonrpc']))
    thismod.lottery = w3.eth.contract(address=thismod.testdata['lottery']['address'], abi=thismod.testdata['lottery']['abi'])
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

    def send_raw(self, account_id, chain_id, txn):
        reqdata = {'account_id': account_id, 'chainId': chain_id, 'txn': txn}
        return requests.post('{}{}'.format(testdata['url'], 'send_raw'), json=reqdata)

    def test_00_add_value(self):
        r = self.payment_apple(testdata['receipts'][0]['data'], testdata['accounts'][0].address)
        self.assertEqual(r.status_code, 200)
        response = json.loads(r.text)
        self.assertEqual(response['msg'], 'success')
        self.assertEqual(response['total_usd'], testdata['receipts'][0]['value'])

    def test_01_check_balance(self):
        id = testdata['accounts'][0].address
        r = self.get_account(id)
        response = json.loads(r.text)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(response['account_id'], id)
        self.assertEqual(float(response['balance']), testdata['receipts'][0]['value'])
        self.assertEqual(response['nonces'], {})

    def test_02_create_account(self):
        id = testdata['accounts'][0].address
        txn = {}
        txn['from'] = id
        txn['to'] = testdata['lottery']['address']
        txn['gas'] = "0x2ab98"
        txn['gasPrice'] = "0x3b9aca00"
        txn['value'] = "0x14"
        txn['chainId'] = 100
        txn['data'] = lottery.encodeABI(fn_name='move', args=[testdata['accounts'][0].address, 10])
        print(txn)

        r = self.send_raw(id, 100, txn)
        print(r.text)
        self.assertEqual(r.status_code, 200)


TODO = '''
1) Multiple jobs hitting the same executor at the same time
   a) verify all jobs are submitted to the mempool
   b) verify jobs are resubmitted when L1 nonce is consumed
   c) verify all jobs from the same account are dropped when one is successfully mined
2) Transaction failing at blockchain
   a) verify only correct cost is debited from account
3) Transaction succeeding at blockchain
   a) verify correct cost is debited from account
4) Transaction constraints
   a) verify whitelisting of only the funder contract
   b) verify transaction requiring more value than account has is rejected
   c) verify L2 nonces higher than current one are rejected
'''

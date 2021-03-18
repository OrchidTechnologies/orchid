import json
import logging
import os
import sys

from web3 import Web3
from web3.auto import w3
from decimal import Decimal
from typing import Any, Dict, Optional, Tuple
from eth_account import Account, messages

def verify_txn_sig(msg):
    txn_s  = msg['txn']
    sig  = msg['sig']
    txn = json.loads(txn_s)

#    msg = str(txn).replace("'", '"').replace(' ', '')
    print("msg:\n", txn_s)
    message = messages.encode_defunct(text=txn_s)
    print("encoded message:\n", message)
    rec_pubaddr = w3.eth.account.recover_message(message, signature=sig)
    print("from =", txn['from'])
    print("rec_pubaddr =", rec_pubaddr)

    assert(txn['from'] == rec_pubaddr)

def sig_test(filename, pubaddr, privkey):

    #acct = w3.eth.account.create('dkapd98fy7sd7dd')
    #print(acct.address)
    #print(acct.privateKey.hex())
    print(pubaddr)
    print(privkey)

    file = open(filename, 'r')
    txnfile = file.read()
    print("file:")
    print(txnfile)
    txnjson = json.loads(txnfile)
    print(f'json: {json.dumps(txnjson)}')

    txn = json.loads(txnjson['txn'])
    print(f'txn: {str(txn)}')

    #// This part prepares "version E" messages, using the EIP-191 standard
    msg = str(txn).replace("'", '"').replace(' ', '')
    print("msg:\n", msg)
    message = messages.encode_defunct(text=msg)
    print("encoded message:\n", message)

    #// This part signs any EIP-191-valid message
    signed_message = Account.sign_message(message, private_key=privkey)
    print("signature =", signed_message.signature.hex())

    txnjson['sig'] = signed_message.signature

    verify_txn_sig(txnjson)



def main():
    print("sig test")
    args = sys.argv[1:]
    sig_test(args[0], args[1], args[2])

if __name__ == "__main__":
    main()

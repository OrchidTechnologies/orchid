import json
import logging
import os
import sys

from web3 import Web3
#from web3.auto import w3
#from eth_account import Account, messages



def filter_test(w3):
    print("filter_test")

    contract_address = '0x4505b262DC053998C10685DC5F9098af8AE5C8ad'
    event_filter = w3.eth.filter({'fromBlock':15095349})
    #event_filter = w3.eth.filter('latest')
    print(event_filter)

    for event in event_filter.get_new_entries():
        print(event)

    return True

def block_test(w3):
    print("block_test")

    latest_block = w3.eth.getBlock('latest',full_transactions=True)
    for txn in latest_block['transactions']:
        print("\n")
        print(txn)

def main():
    args = sys.argv[1:]
    #filter_test(args[0], args[1], args[2])


    w3 = Web3(Web3.HTTPProvider('https://rpc.xdaichain.com/', request_kwargs={'headers':{'referer':'https://account.orchid.com'}}) )

    print(w3.api)
    print(w3.clientVersion)

    print(w3)
    print(w3.isConnected())

    block_test(w3)
    #filter_test(w3)

if __name__ == "__main__":
    main()

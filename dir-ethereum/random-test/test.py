from binascii import hexlify, unhexlify
from collections import Counter
import os
import random
import sys

from solc import compile_standard # py-solc
from sha3 import keccak_256 # pysha3
from web3 import Web3, HTTPProvider # web3

if len(sys.argv) < 3:
    print("Usage: test.py <filename> <random seed>, e.g. test.py ../directory.sol 1234")
    sys.exit(1)

filename = sys.argv[1]
random.seed(int(sys.argv[2]))

# run ganache-cli -a 11 to create enough accounts
web3 = Web3(HTTPProvider('http://localhost:8545'))
web3.eth.defaultAccount = web3.eth.accounts[0]

def deploy(filename, contractName, *args):
    filename = os.path.abspath(filename)
    path = os.path.dirname(filename)

    compiled = compile_standard({
        'language': 'Solidity',
        'sources': {
            filename: {
                'urls': [os.path.abspath(filename)],
            },
        },
        'settings': {
            'outputSelection': {
                '*': {
                    '*': ['evm.bytecode', 'abi'],
                }
            },
        },
    }, allow_paths=os.path.abspath(os.path.join(path, '..')) + ',' + path)

    contract = compiled['contracts'][filename][contractName]

    bytecode = contract['evm']['bytecode']['object']
    abi = contract['abi']

    transaction_hash = web3.eth.contract(abi=abi, bytecode=bytecode).constructor(*args).transact()
    address = web3.eth.waitForTransactionReceipt(transaction_hash).contractAddress
    deployed = web3.eth.contract(abi=abi, address=address)

    return deployed

accounts = web3.eth.accounts[1:11]

token = deploy('token.sol', 'DummyToken')

directory = deploy(filename, 'OrchidDirectory', token.address)

token_balances = {}

# all accounts start with 1000 tokens (1000 * 10**18 token units)
for account in accounts:
    token.functions.transfer(account, 1000 * 10**18).transact()
    token_balances[account] = 1000 * 10**18

stakee_totals = Counter()
staker_stakee_amount = Counter()

withdrawal_index = 0
for _ in range(100):
    staker = random.choice(accounts)
    stakee = random.choice(accounts)
    amount = random.randrange(1, 20) * 10**18
    # flip a coin to see whether we're increasing or decreasing stake
    if random.random() < 0.5:
        # decrease stake

        # max decrease is the amount staked already
        amount = min(amount, staker_stakee_amount[(staker, stakee)])
        if amount == 0:
            # if no stake, nothing to decrease
            continue

        # log progress
        print(f'Adjusting stake for ({staker}, {stakee}) by {-amount}')

        # call pull()
        directory.functions.pull(stakee, amount, withdrawal_index).transact({'from': staker})
        withdrawal_index += 1

        # accounting
        stakee_totals[stakee] -= amount
        staker_stakee_amount[(staker, stakee)] -= amount
    else:
        # log progress
        print(f'Adjusting stake for ({staker}, {stakee}) by {amount}')

        # call push()
        directory.functions.push(stakee, amount, 1234).transact({'from': staker})

        # accounting
        token_balances[staker] -= amount
        stakee_totals[stakee] += amount
        staker_stakee_amount[(staker, stakee)] += amount

# check that have() returns the total we expect
print('Checking total staked...')
assert directory.functions.have().call() == sum(stakee_totals.values())

# check token balances
for account in accounts:
    print(f'Checking {account} balances...')
    assert token.functions.balanceOf(account).call() == token_balances[account]
    assert directory.functions.heft(account).call() == stakee_totals[account]

# check staked amount per pair
for staker in accounts:
    for stakee in accounts:
        print(f'Checking ({staker}, {stakee}) stake...')
        name = keccak_256(unhexlify(staker[2:] + stakee[2:])).hexdigest()
        amount = int('{:>064}'.format(hexlify(web3.eth.getStorageAt(directory.address, int(keccak_256(unhexlify(name.encode() + b'0'*63 + b'2')).hexdigest(), 16) + 1)).decode())[32:], 16)
        assert amount == staker_stakee_amount[(staker, stakee)]

BYTES32_ZERO = '0'*64

# for a given "name" (staker/stakee pair) and "p" (parent), check that:
# 1. the parent is as expected
# 2. before is correct (matches recursive total for left subtree)
# 3. after is correct (matches recursive total for right subtree)
# returns total stake for the named subtree
def check_tree(name, p):
    def fetch(n):
        # this reads word `n` from the struct found at stakes_[name] (slot 2) via keccak256(name . slot) + n
        return '{:>064}'.format(hexlify(web3.eth.getStorageAt(directory.address, int(keccak_256(unhexlify(name.encode() + b'0'*63 + b'2')).hexdigest(), 16) + n)).decode())
    def split(n):
        # this fetches a word that contains two uint128s and returns the constituent parts
        x = fetch(n)
        return int(x[32:], 16), int(x[:32], 16)

    before, after = split(0)
    amount, delay = split(1)
    stakee = fetch(2)[24:]
    parent = fetch(3)
    left = fetch(4)
    right = fetch(5)

    assert parent == p
    if left != BYTES32_ZERO:
        assert before == check_tree(left, name)
    else:
        assert before == 0
    if right != BYTES32_ZERO:
        assert after == check_tree(right, name)
    else:
        assert after == 0

    return before + amount + after

# slot 3 is root_
root = hexlify(web3.eth.getStorageAt(directory.address, 3)).decode()
assert check_tree(root, BYTES32_ZERO) == sum(stakee_totals.values())

print('Deleting everything...')

for staker in accounts:
    for stakee in accounts:
        amount = staker_stakee_amount[(staker, stakee)]
        if amount > 0:
            directory.functions.pull(stakee, amount, withdrawal_index).transact({'from': staker})
            withdrawal_index += 1

root = '{:>064}'.format(hexlify(web3.eth.getStorageAt(directory.address, 3)).decode())
assert root == BYTES32_ZERO
assert directory.functions.have().call() == 0

print("Done.")

# flake8: noqa

token_abi = [
    {
        'inputs': [],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'constructor',
        },
    {
        'anonymous': False,
        'inputs': [{
            'indexed': True,
            'internalType': 'address',
            'name': 'owner',
            'type': 'address',
            }, {
            'indexed': True,
            'internalType': 'address',
            'name': 'spender',
            'type': 'address',
            }, {
            'indexed': False,
            'internalType': 'uint256',
            'name': 'value',
            'type': 'uint256',
            }],
        'name': 'Approval',
        'type': 'event',
        },
    {
        'anonymous': False,
        'inputs': [{
            'indexed': True,
            'internalType': 'address',
            'name': 'from',
            'type': 'address',
            }, {
            'indexed': True,
            'internalType': 'address',
            'name': 'to',
            'type': 'address',
            }, {
            'indexed': False,
            'internalType': 'uint256',
            'name': 'value',
            'type': 'uint256',
            }],
        'name': 'Transfer',
        'type': 'event',
        },
    {
        'constant': True,
        'inputs': [{'internalType': 'address', 'name': 'owner',
                   'type': 'address'}, {'internalType': 'address',
                   'name': 'spender', 'type': 'address'}],
        'name': 'allowance',
        'outputs': [{'internalType': 'uint256', 'name': '',
                    'type': 'uint256'}],
        'payable': False,
        'stateMutability': 'view',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'address', 'name': 'spender',
                   'type': 'address'}, {'internalType': 'uint256',
                   'name': 'amount', 'type': 'uint256'}],
        'name': 'approve',
        'outputs': [{'internalType': 'bool', 'name': '', 'type': 'bool'
                    }],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': True,
        'inputs': [{'internalType': 'address', 'name': 'account',
                   'type': 'address'}],
        'name': 'balanceOf',
        'outputs': [{'internalType': 'uint256', 'name': '',
                    'type': 'uint256'}],
        'payable': False,
        'stateMutability': 'view',
        'type': 'function',
        },
    {
        'constant': True,
        'inputs': [],
        'name': 'decimals',
        'outputs': [{'internalType': 'uint8', 'name': '',
                    'type': 'uint8'}],
        'payable': False,
        'stateMutability': 'view',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'address', 'name': 'spender',
                   'type': 'address'}, {'internalType': 'uint256',
                   'name': 'subtractedValue', 'type': 'uint256'}],
        'name': 'decreaseAllowance',
        'outputs': [{'internalType': 'bool', 'name': '', 'type': 'bool'
                    }],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'address', 'name': 'spender',
                   'type': 'address'}, {'internalType': 'uint256',
                   'name': 'addedValue', 'type': 'uint256'}],
        'name': 'increaseAllowance',
        'outputs': [{'internalType': 'bool', 'name': '', 'type': 'bool'
                    }],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': True,
        'inputs': [],
        'name': 'name',
        'outputs': [{'internalType': 'string', 'name': '',
                    'type': 'string'}],
        'payable': False,
        'stateMutability': 'view',
        'type': 'function',
        },
    {
        'constant': True,
        'inputs': [],
        'name': 'symbol',
        'outputs': [{'internalType': 'string', 'name': '',
                    'type': 'string'}],
        'payable': False,
        'stateMutability': 'view',
        'type': 'function',
        },
    {
        'constant': True,
        'inputs': [],
        'name': 'totalSupply',
        'outputs': [{'internalType': 'uint256', 'name': '',
                    'type': 'uint256'}],
        'payable': False,
        'stateMutability': 'view',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'address', 'name': 'recipient',
                   'type': 'address'}, {'internalType': 'uint256',
                   'name': 'amount', 'type': 'uint256'}],
        'name': 'transfer',
        'outputs': [{'internalType': 'bool', 'name': '', 'type': 'bool'
                    }],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'address', 'name': 'sender',
                   'type': 'address'}, {'internalType': 'address',
                   'name': 'recipient', 'type': 'address'},
                   {'internalType': 'uint256', 'name': 'amount',
                   'type': 'uint256'}],
        'name': 'transferFrom',
        'outputs': [{'internalType': 'bool', 'name': '', 'type': 'bool'
                    }],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    ]

lottery_abi = [
    {
        'inputs': [{'internalType': 'contract IERC20', 'name': 'token',
                   'type': 'address'}],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'constructor',
        },
    {
        'anonymous': False,
        'inputs': [{
            'indexed': True,
            'internalType': 'address',
            'name': 'funder',
            'type': 'address',
            }, {
            'indexed': True,
            'internalType': 'address',
            'name': 'signer',
            'type': 'address',
            }, {
            'indexed': False,
            'internalType': 'uint128',
            'name': 'amount',
            'type': 'uint128',
            }, {
            'indexed': False,
            'internalType': 'uint128',
            'name': 'escrow',
            'type': 'uint128',
            }, {
            'indexed': False,
            'internalType': 'uint256',
            'name': 'unlock',
            'type': 'uint256',
            }],
        'name': 'Update',
        'type': 'event',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'address', 'name': 'signer',
                   'type': 'address'},
                   {'internalType': 'contract OrchidVerifier',
                   'name': 'verify', 'type': 'address'},
                   {'internalType': 'bytes', 'name': 'shared',
                   'type': 'bytes'}],
        'name': 'bind',
        'outputs': [],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'address', 'name': 'funder',
                   'type': 'address'},
                   {'internalType': 'address payable', 'name': 'target'
                   , 'type': 'address'}, {'internalType': 'uint128',
                   'name': 'amount', 'type': 'uint128'},
                   {'internalType': 'bytes', 'name': 'receipt',
                   'type': 'bytes'}],
        'name': 'give',
        'outputs': [],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [
            {'internalType': 'bytes32', 'name': 'seed',
             'type': 'bytes32'},
            {'internalType': 'bytes32', 'name': 'hash',
             'type': 'bytes32'},
            {'internalType': 'bytes32', 'name': 'nonce',
             'type': 'bytes32'},
            {'internalType': 'uint256', 'name': 'start',
             'type': 'uint256'},
            {'internalType': 'uint128', 'name': 'range',
             'type': 'uint128'},
            {'internalType': 'uint128', 'name': 'amount',
             'type': 'uint128'},
            {'internalType': 'uint128', 'name': 'ratio',
             'type': 'uint128'},
            {'internalType': 'address', 'name': 'funder',
             'type': 'address'},
            {'internalType': 'address payable', 'name': 'target',
             'type': 'address'},
            {'internalType': 'bytes', 'name': 'receipt', 'type': 'bytes'
             },
            {'internalType': 'uint8', 'name': 'v', 'type': 'uint8'},
            {'internalType': 'bytes32', 'name': 'r', 'type': 'bytes32'
             },
            {'internalType': 'bytes32', 'name': 's', 'type': 'bytes32'
             },
            {'internalType': 'bytes32[]', 'name': 'old',
             'type': 'bytes32[]'},
            ],
        'name': 'grab',
        'outputs': [],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': True,
        'inputs': [{'internalType': 'address', 'name': 'funder',
                   'type': 'address'}],
        'name': 'keys',
        'outputs': [{'internalType': 'address[]', 'name': '',
                    'type': 'address[]'}],
        'payable': False,
        'stateMutability': 'view',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'bytes32', 'name': 'ticket',
                   'type': 'bytes32'}],
        'name': 'kill',
        'outputs': [],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'address', 'name': 'signer',
                   'type': 'address'}],
        'name': 'lock',
        'outputs': [],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': True,
        'inputs': [{'internalType': 'address', 'name': 'funder',
                   'type': 'address'}, {'internalType': 'address',
                   'name': 'signer', 'type': 'address'}],
        'name': 'look',
        'outputs': [{'internalType': 'uint128', 'name': '',
                    'type': 'uint128'}, {'internalType': 'uint128',
                    'name': '', 'type': 'uint128'},
                    {'internalType': 'uint256', 'name': '',
                    'type': 'uint256'},
                    {'internalType': 'contract OrchidVerifier',
                    'name': '', 'type': 'address'},
                    {'internalType': 'bytes', 'name': '',
                    'type': 'bytes'}],
        'payable': False,
        'stateMutability': 'view',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'address', 'name': 'signer',
                   'type': 'address'}, {'internalType': 'uint128',
                   'name': 'amount', 'type': 'uint128'}],
        'name': 'move',
        'outputs': [],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': True,
        'inputs': [{'internalType': 'address', 'name': 'funder',
                   'type': 'address'}, {'internalType': 'uint256',
                   'name': 'offset', 'type': 'uint256'},
                   {'internalType': 'uint256', 'name': 'count',
                   'type': 'uint256'}],
        'name': 'page',
        'outputs': [{'internalType': 'address[]', 'name': '',
                    'type': 'address[]'}],
        'payable': False,
        'stateMutability': 'view',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'address', 'name': 'signer',
                   'type': 'address'},
                   {'internalType': 'address payable', 'name': 'target'
                   , 'type': 'address'}],
        'name': 'pull',
        'outputs': [],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'address', 'name': 'signer',
                   'type': 'address'},
                   {'internalType': 'address payable', 'name': 'target'
                   , 'type': 'address'}, {'internalType': 'uint128',
                   'name': 'amount', 'type': 'uint128'}],
        'name': 'pull',
        'outputs': [],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'address', 'name': 'signer',
                   'type': 'address'}, {'internalType': 'uint128',
                   'name': 'total', 'type': 'uint128'},
                   {'internalType': 'uint128', 'name': 'escrow',
                   'type': 'uint128'}],
        'name': 'push',
        'outputs': [],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': True,
        'inputs': [{'internalType': 'address', 'name': 'funder',
                   'type': 'address'}, {'internalType': 'uint256',
                   'name': 'offset', 'type': 'uint256'}],
        'name': 'seek',
        'outputs': [{'internalType': 'address', 'name': '',
                    'type': 'address'}],
        'payable': False,
        'stateMutability': 'view',
        'type': 'function',
        },
    {
        'constant': True,
        'inputs': [{'internalType': 'address', 'name': 'funder',
                   'type': 'address'}],
        'name': 'size',
        'outputs': [{'internalType': 'uint256', 'name': '',
                    'type': 'uint256'}],
        'payable': False,
        'stateMutability': 'view',
        'type': 'function',
        },
    {
        'constant': False,
        'inputs': [{'internalType': 'address', 'name': 'signer',
                   'type': 'address'}],
        'name': 'warn',
        'outputs': [],
        'payable': False,
        'stateMutability': 'nonpayable',
        'type': 'function',
        },
    {
        'constant': True,
        'inputs': [],
        'name': 'what',
        'outputs': [{'internalType': 'contract IERC20', 'name': '',
                    'type': 'address'}],
        'payable': False,
        'stateMutability': 'view',
        'type': 'function',
        },
    ]

import json
import web3

from ticket import Ticket

# Gnosis - default
rpc_url_default = 'https://rpc.gnosischain.com/'
chain_id_default = 100

# Polygon - default
# rpc_url_default = 'https://polygon-rpc.com'
# chain_id_default = 137

# Gas default
gas_amount_default = 100000

uint64 = pow(2, 64) - 1     # 18446744073709551615
uint128 = pow(2, 128) - 1   # 340282366920938463463374607431768211455

def to_32byte_hex(val):
    return web3.Web3.to_hex(web3.Web3.to_bytes(hexstr=val).rjust(32, b'\0'))


class Lottery:
    addr_type = pow(2, 20 * 8) - 1
    contract_addr = '0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82'
    token = '0x' + '0' * 40
    contract_abi_str = "[ { \"inputs\": [ { \"internalType\": \"uint64\", \"name\": \"day\", \"type\": \"uint64\" } ], \"stateMutability\": \"nonpayable\", \"type\": \"constructor\" }, { \"anonymous\": false, \"inputs\": [ { \"indexed\": true, \"internalType\": \"contract IERC20\", \"name\": \"token\", \"type\": \"address\" }, { \"indexed\": true, \"internalType\": \"address\", \"name\": \"funder\", \"type\": \"address\" }, { \"indexed\": true, \"internalType\": \"address\", \"name\": \"signer\", \"type\": \"address\" } ], \"name\": \"Create\", \"type\": \"event\" }, { \"anonymous\": false, \"inputs\": [ { \"indexed\": true, \"internalType\": \"bytes32\", \"name\": \"key\", \"type\": \"bytes32\" }, { \"indexed\": false, \"internalType\": \"uint256\", \"name\": \"unlock_warned\", \"type\": \"uint256\" } ], \"name\": \"Delete\", \"type\": \"event\" }, { \"anonymous\": false, \"inputs\": [ { \"indexed\": true, \"internalType\": \"address\", \"name\": \"funder\", \"type\": \"address\" }, { \"indexed\": true, \"internalType\": \"address\", \"name\": \"recipient\", \"type\": \"address\" } ], \"name\": \"Enroll\", \"type\": \"event\" }, { \"anonymous\": false, \"inputs\": [ { \"indexed\": true, \"internalType\": \"bytes32\", \"name\": \"key\", \"type\": \"bytes32\" }, { \"indexed\": false, \"internalType\": \"uint256\", \"name\": \"escrow_amount\", \"type\": \"uint256\" } ], \"name\": \"Update\", \"type\": \"event\" }, { \"inputs\": [ { \"internalType\": \"contract IERC20\", \"name\": \"token\", \"type\": \"address\" }, { \"internalType\": \"address\", \"name\": \"recipient\", \"type\": \"address\" }, { \"components\": [ { \"internalType\": \"bytes32\", \"name\": \"data\", \"type\": \"bytes32\" }, { \"internalType\": \"bytes32\", \"name\": \"reveal\", \"type\": \"bytes32\" }, { \"internalType\": \"uint256\", \"name\": \"packed0\", \"type\": \"uint256\" }, { \"internalType\": \"uint256\", \"name\": \"packed1\", \"type\": \"uint256\" }, { \"internalType\": \"bytes32\", \"name\": \"r\", \"type\": \"bytes32\" }, { \"internalType\": \"bytes32\", \"name\": \"s\", \"type\": \"bytes32\" } ], \"internalType\": \"struct OrchidLottery1.Ticket[]\", \"name\": \"tickets\", \"type\": \"tuple[]\" }, { \"internalType\": \"bytes32[]\", \"name\": \"refunds\", \"type\": \"bytes32[]\" } ], \"name\": \"claim\", \"outputs\": [], \"stateMutability\": \"nonpayable\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"contract IERC20\", \"name\": \"token\", \"type\": \"address\" }, { \"internalType\": \"uint256\", \"name\": \"amount\", \"type\": \"uint256\" }, { \"internalType\": \"address\", \"name\": \"signer\", \"type\": \"address\" }, { \"internalType\": \"int256\", \"name\": \"adjust\", \"type\": \"int256\" }, { \"internalType\": \"int256\", \"name\": \"warn\", \"type\": \"int256\" }, { \"internalType\": \"uint256\", \"name\": \"retrieve\", \"type\": \"uint256\" } ], \"name\": \"edit\", \"outputs\": [], \"stateMutability\": \"nonpayable\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"address\", \"name\": \"signer\", \"type\": \"address\" }, { \"internalType\": \"int256\", \"name\": \"adjust\", \"type\": \"int256\" }, { \"internalType\": \"int256\", \"name\": \"warn\", \"type\": \"int256\" }, { \"internalType\": \"uint256\", \"name\": \"retrieve\", \"type\": \"uint256\" } ], \"name\": \"edit\", \"outputs\": [], \"stateMutability\": \"payable\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"bool\", \"name\": \"cancel\", \"type\": \"bool\" }, { \"internalType\": \"address[]\", \"name\": \"recipients\", \"type\": \"address[]\" } ], \"name\": \"enroll\", \"outputs\": [], \"stateMutability\": \"nonpayable\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"address\", \"name\": \"funder\", \"type\": \"address\" }, { \"internalType\": \"address\", \"name\": \"recipient\", \"type\": \"address\" } ], \"name\": \"enrolled\", \"outputs\": [ { \"internalType\": \"uint256\", \"name\": \"\", \"type\": \"uint256\" } ], \"stateMutability\": \"view\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"contract IERC20\", \"name\": \"token\", \"type\": \"address\" }, { \"internalType\": \"address\", \"name\": \"signer\", \"type\": \"address\" }, { \"internalType\": \"uint64\", \"name\": \"marked\", \"type\": \"uint64\" } ], \"name\": \"mark\", \"outputs\": [], \"stateMutability\": \"nonpayable\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"address\", \"name\": \"sender\", \"type\": \"address\" }, { \"internalType\": \"uint256\", \"name\": \"amount\", \"type\": \"uint256\" }, { \"internalType\": \"bytes\", \"name\": \"data\", \"type\": \"bytes\" } ], \"name\": \"onTokenTransfer\", \"outputs\": [ { \"internalType\": \"bool\", \"name\": \"\", \"type\": \"bool\" } ], \"stateMutability\": \"nonpayable\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"contract IERC20\", \"name\": \"token\", \"type\": \"address\" }, { \"internalType\": \"address\", \"name\": \"funder\", \"type\": \"address\" }, { \"internalType\": \"address\", \"name\": \"signer\", \"type\": \"address\" } ], \"name\": \"read\", \"outputs\": [ { \"internalType\": \"uint256\", \"name\": \"\", \"type\": \"uint256\" }, { \"internalType\": \"uint256\", \"name\": \"\", \"type\": \"uint256\" } ], \"stateMutability\": \"view\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"uint256\", \"name\": \"count\", \"type\": \"uint256\" }, { \"internalType\": \"bytes32\", \"name\": \"seed\", \"type\": \"bytes32\" } ], \"name\": \"save\", \"outputs\": [], \"stateMutability\": \"nonpayable\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"address\", \"name\": \"sender\", \"type\": \"address\" }, { \"internalType\": \"uint256\", \"name\": \"amount\", \"type\": \"uint256\" }, { \"internalType\": \"bytes\", \"name\": \"data\", \"type\": \"bytes\" } ], \"name\": \"tokenFallback\", \"outputs\": [], \"stateMutability\": \"nonpayable\", \"type\": \"function\" }]"
    contract_abi= None

    contract= None
    rpc_url= None
    chain_id = None
    gas_amount = None

    def __init__(self, rpc_url=rpc_url_default, chain_id=chain_id_default, gas_amount=gas_amount_default):
        self.rpc_url = rpc_url
        self.chain_id = chain_id
        self.gas_amount = gas_amount

        self.contract_abi = json.loads(self.contract_abi_str)

    def init_contract(self, web3):
        self.web3 = web3
        self.contract = self.web3.eth.contract(address=self.contract_addr, abi=self.contract_abi)


    @staticmethod
    def prepareTicket(tk:Ticket, reveal):
        return [tk.data, to_32byte_hex(reveal), tk.packed0, tk.packed1, to_32byte_hex(tk.sig_r), to_32byte_hex(tk.sig_s)]
        return [tk.data.hex(), reveal, tk.packed0, tk.packed1, tk.sig_r, tk.sig_s]
    
    # Ticket object, L1 address & key
    def claim_ticket(self, ticket, recipient, executor_key, reveal):
        tk = Lottery.prepareTicket(ticket, reveal)
        executor_address = self.web3.eth.account.from_key(executor_key).address
        l1nonce = self.web3.eth.get_transaction_count(executor_address)
        func = self.contract.functions.claim(self.token, recipient, [tk], [])

        tx = func.build_transaction({
            'chainId': self.chain_id,
            'gas': self.gas_amount,
            'maxFeePerGas': self.web3.to_wei('100', 'gwei'),
            'maxPriorityFeePerGas': self.web3.to_wei('40', 'gwei'),
            'nonce': l1nonce
            })

        # Polygon Estimates
        # if (self.chain_id == 137):
            # gas_estimate = self.web3.eth.estimate_gas(tx)
            # print("gas ", gas_estimate)
            # tx.update({'gas': gas_estimate})

        signed = self.web3.eth.account.sign_transaction(tx, private_key=executor_key)
        txhash = self.web3.eth.send_raw_transaction(signed.rawTransaction)
        return txhash.hex()
    
    def check_balance(self, addressL1, addressL2):
        escrow_amount = self.contract.functions.read(self.token, addressL1, addressL2).call(block_identifier='latest')[0]
        balance = float(escrow_amount & uint128) / pow(10,18)
        escrow = float(escrow_amount >> 128) / pow(10,18)
        return balance, escrow
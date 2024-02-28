import datetime
import web3
from eth_abi.packed import encode_packed
import eth_account
import ethereum

uint64 = pow(2, 64) - 1     # 18446744073709551615
uint128 = pow(2, 128) - 1   # 340282366920938463463374607431768211455
addrtype = pow(2, 20 * 8) - 1


class Ticket:
    def __init__(self, web3_provider, data, lot_addr, token_addr, amount, ratio, funder, recipient, commitment, key):

        self.web3 = web3_provider
        self.data = data
        self.lot_addr = lot_addr
        self.token_addr = token_addr
        self.amount = amount
        self.ratio = ratio
        self.commitment = commitment
        self.funder = funder
        self.recipient = recipient
        self.key = key

        # Check if we have all the variables
        if all(v is not None for v in [web3_provider, recipient, commitment, ratio, funder, amount, lot_addr, token_addr, key]):
            issued = int(datetime.datetime.now().timestamp())
            l2nonce = int(web3.Web3.keccak(text=(f'{datetime.datetime.now()}')).hex(), base=16) & (pow(2, 64) - 1)
            expire = pow(2, 31) - 1
            packed0 = issued << 192 | l2nonce << 128 | amount
            packed1 = expire << 224 | ratio << 160 | int(funder, base=16)

            digest = web3.Web3.solidity_keccak(
                ['bytes1', 'bytes1', 'address', 'bytes32', 'address', 'address',
                'bytes32', 'uint256', 'uint256', 'bytes32'],
                [b'\x19', b'\x00',
                self.lot_addr, b'\x00' * 31 + b'\x64',
                self.token_addr, recipient,
                web3.Web3.solidity_keccak(['bytes32'], [self.commitment]), packed0, 
                packed1, self.data])

            sig = self.web3.eth.account.signHash(digest, private_key=key.hex())
            packed1 = packed1 << 1 | ((sig.v - 27) & 1)

            self.packed0 = packed0
            self.packed1 = packed1
            self.sig_r = Ticket.to_32byte_hex(sig.r)
            self.sig_s = Ticket.to_32byte_hex(sig.s)
            self.sig_v = (sig.v - 27) & 1
    
    def digest(self, packed0 = None, packed1 = None):
        _packed0 = self.packed0 if packed0 is None else packed0
        _packed1 = self.packed1 if packed1 is None else packed1
        _packed1 = _packed1 >> 1
        types = ['bytes1', 'bytes1', 'address', 'bytes32', 'address', 'address',
                'bytes32', 'uint256', 'uint256', 'bytes32']
        vals = [b'\x19', b'\x00',
                self.lot_addr, b'\x00' * 31 + b'\x64',
                self.token_addr, self.recipient,
                bytes.fromhex(self.commitment[2:]), _packed0, 
                _packed1, self.data]
        packed = encode_packed(types, vals) 
        return ethereum.utils.sha3(packed)


    @staticmethod
    def to_32byte_hex(val):
        return web3.Web3.to_hex(web3.Web3.to_bytes(hexstr=val).rjust(32, b'\0'))

    def serialize_ticket(self):
        return Ticket.to_32byte_hex(self.packed0)[2:] + Ticket.to_32byte_hex(self.packed1)[2:] + self.sig_r[2:] + self.sig_s[2:]

    @staticmethod
    def deserialize_ticket(tstr, reveal = None, commitment = None, recipient = None,
                           lotaddr = '0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82',
                           tokenaddr = '0x0000000000000000000000000000000000000000'):
        tk = [tstr[i:i+64] for i in range(0, len(tstr), 64)]
        print(tk)
        tk_temp = Ticket(None, None, None, None, None, None, None, None, None, None)
        tk_temp.packed0 = int(tk[0], base=16)
        tk_temp.packed1 = int(tk[1], base=16)
        tk_temp.amount = tk_temp.packed0 & uint128
        tk_temp.ratio = (tk_temp.packed1 >> 161) & uint64
        tk_temp.sig_r = tk[2]
        tk_temp.sig_s = tk[3]
        tk_temp.sig_v = tk_temp.packed1 & 1
        tk_temp.data = b'\x00' * 32
        tk_temp.reveal = Ticket.to_32byte_hex(reveal)
        tk_temp.commitment = Ticket.to_32byte_hex(commitment)
        tk_temp.lot_addr = lotaddr
        tk_temp.token_addr = tokenaddr
        tk_temp.recipient = recipient
        digest = tk_temp.digest()
        signer = ethereum.utils.checksum_encode(ethereum.utils.sha3(ethereum.utils.ecrecover_to_pub(digest,
                                                                      tk_temp.sig_v,
                                                                      bytes.fromhex(tk_temp.sig_r[2:]), 
                                                                      bytes.fromhex(tk_temp.sig_s[2:])
                                                                     ))[-20:])
        return tk_temp

    def is_winner(self, reveal):
        ratio = uint64 & (self.packed1 >> 161)
        issued_nonce = (self.packed0 >> 128)
        hash = ethereum.utils.sha3(bytes.fromhex(reveal[2:]) + 
                                   issued_nonce.to_bytes(length=16, byteorder='big'))
        comp = uint64 & int(hash.hex(), base=16)
        if ratio < comp:
            return False
        return True

    def face_value(self):
        return self.amount * self.ratio / uint64

    def print_ticket(self):
        amount = self.packed0 & uint128
        nonce = (self.packed0 >> 128) & uint64
        funder = addrtype & (self.packed1 >> 1)
        ratio = uint64 & (self.packed1 >> 161)


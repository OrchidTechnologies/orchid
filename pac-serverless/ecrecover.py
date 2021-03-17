from ethereum.utils import sha3, ecrecover_to_pub
from eth_utils import decode_hex
import sys


if len(sys.argv) != 5:
    print("Wrong number of arguments. Should be ecrecovery.py msghash v r s.")
    print(sys.argv)
    sys.exit()

prog, hash, vstr, rstr, str = sys.argv

msg_hash = decode_hex(hash)
v = int(vstr)
r = int(rstr)
s = int(str)

pubkey = ecrecover_to_pub(msg_hash, v, r, s)
addr = sha3(pubkey)[-20:].hex()
print('0x' + addr)

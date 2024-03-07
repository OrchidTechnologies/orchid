import galois
import numpy as np
from galois import FieldArray
from numpy._typing import NDArray

# The largest prime that fits in 256 bits / 32 bytes
p = 2 ** 256 - 189

# For very large primes galois can take a long time to infer the primitive element; Specifying it is much faster.
primitive_element = 2

# The field scalars are read at the rounded down byte size (to guarantee that they remain less than p).
FIELD_SAFE_SCALAR_SIZE_BYTES: int = 31

# The stored size of the element is the rounded up byte size.
FIELD_ELEMENT_SIZE_BYTES: int = 32


# Initialize the Galois field object for the order of the field used in the BLS12-381 curve.
def get_field():
    # Order / characteristic is q and degree is 1 for a prime field
    return galois.GF(p, 1, primitive_element=primitive_element, verify=False)


def symbol_to_bytes(
        symbol: FieldArray,
        element_size: int,
) -> bytes:
    return int(symbol).to_bytes(element_size, byteorder='big')


# Take the list or array of GF symbols and render them to a list of byte strings, each of length element_size.
def symbols_to_bytes_list(
        symbols: list[FieldArray] | NDArray[FieldArray],
        element_size: int,
) -> list[bytes]:
    return [symbol_to_bytes(el, element_size) for el in symbols]


# Take the list or array of GF symbols and render them to a flattened byte string of
# length len(symbols) * element_size.
def symbols_to_bytes(
        symbols: list[FieldArray] | NDArray[FieldArray],
        element_size: int,
) -> bytes:
    return b''.join(symbols_to_bytes_list(symbols, element_size))

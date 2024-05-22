import ctypes

from blst_ctypes import add_points, add_scalars

##
## Test point addition
##

p1_bytes = bytes.fromhex(
    'ac7f57b508dd812eaf42bce53b1e210dd933ea55a84371d10b2ff11735016e431df88ed513b1a832eeb579ba3806d8e3')
p2_bytes = bytes.fromhex(
    'ac7f57b508dd812eaf42bce53b1e210dd933ea55a84371d10b2ff11735016e431df88ed513b1a832eeb579ba3806d8e3')

result_bytes = add_points(p1_bytes, p2_bytes)
print("Result:", result_bytes.hex())

assert (result_bytes.hex() ==
        '90e8df266fc322a336be51e682a95ebbd6288f1acca3a2d19a661f158db6ed10dd65449fe8973d797ae80d2c655ecd59')

##
## Test scalar addition
##

# Example scalars, ensure these are valid and initialized properly
scalar_bytes1 = (ctypes.c_byte * 32)(*([0] * 32))  # Example byte array
scalar_bytes2 = (ctypes.c_byte * 32)(*([1] * 32))  # Example byte array
# scalar_bytes1 = bytes.fromhex('76b729a94f4831ba2c20f9014ae8be2e300454716223872ecab4572a15c4a72b')
# scalar_bytes2 = bytes.fromhex('76b729a94f4831ba2c20f9014ae8be2e300454716223872ecab4572a15c4a72b')

result_bytes = add_scalars(scalar_bytes1, scalar_bytes2)
print("Resulting Scalar:", result_bytes.hex())

assert result_bytes.hex() == '0101010101010101010101010101010101010101010101010101010101010101'

import os
import site
import ctypes.util

#
# Use the blst library via ctypes
# Note: This is a little ugly but I think it's cleanest to use the same lib that ckzg uses.
#

# TODO: The architecture dependent library name
libname = 'ckzg.cpython-311-darwin.so'

# Get all site-packages directories (includes both global and virtualenv)
site_packages = site.getsitepackages() + [site.getusersitepackages()]

# Look for the library within site-packages directories
for dir in site_packages:
    path = os.path.join(dir, libname)
    if os.path.exists(path):
        print(f"Library found at: {path}")
        break
else:
    print("Library not found.")
    exit()

# path = '.././venv/lib/python3.11/site-packages/ckzg.cpython-311-darwin.so'
print("Library path:", path)

# Load the library
lib = ctypes.CDLL(path)
print("Library:", lib)


# Define explicitly without relying on sizeof
class BlstFp(ctypes.Structure):
    _fields_ = [("l", ctypes.c_uint64 * (384 // 64))]


class BlstP1(ctypes.Structure):
    _fields_ = [("x", BlstFp), ("y", BlstFp), ("z", BlstFp)]


class BlstP1Affine(ctypes.Structure):
    _fields_ = [("x", BlstFp), ("y", BlstFp)]


class BlstScalar(ctypes.Structure):
    _fields_ = [("b", ctypes.c_byte * 32)]  # 256 bits or 32 bytes


# Define the function signature
lib.blst_p1_uncompress.argtypes = [ctypes.POINTER(BlstP1Affine), ctypes.c_char_p]
lib.blst_p1_uncompress.restype = ctypes.c_int  # or BLST_ERROR

lib.blst_p1_from_affine.argtypes = [ctypes.POINTER(BlstP1), ctypes.POINTER(BlstP1Affine)]
lib.blst_p1_from_affine.restype = None

lib.blst_p1_add_or_double.argtypes = [ctypes.POINTER(BlstP1), ctypes.POINTER(BlstP1), ctypes.POINTER(BlstP1)]
lib.blst_p1_add_or_double.restype = None

lib.blst_p1_compress.argtypes = [ctypes.c_char_p, ctypes.POINTER(BlstP1)]
lib.blst_p1_compress.restype = None

lib.blst_p1_on_curve.argtypes = [ctypes.POINTER(BlstP1)]
lib.blst_p1_on_curve.restype = ctypes.c_bool

lib.blst_sk_add_n_check.argtypes = [ctypes.POINTER(BlstScalar), ctypes.POINTER(BlstScalar), ctypes.POINTER(BlstScalar)]
lib.blst_sk_add_n_check.restype = ctypes.c_bool


def add_points(p1_bytes: bytes, p2_bytes: bytes) -> bytes:
    # Allocate memory for the points
    p1_affine = BlstP1Affine()
    p2_affine = BlstP1Affine()

    if lib.blst_p1_uncompress(ctypes.byref(p1_affine), p1_bytes) != 0:
        raise ValueError("Invalid point encoding for point 1")
    if lib.blst_p1_uncompress(ctypes.byref(p2_affine), p2_bytes) != 0:
        raise ValueError("Invalid point encoding for point 2")

    p1 = BlstP1()
    p2 = BlstP1()
    lib.blst_p1_from_affine(ctypes.byref(p1), ctypes.byref(p1_affine))
    lib.blst_p1_from_affine(ctypes.byref(p2), ctypes.byref(p2_affine))
    result_p1 = BlstP1()  # This will hold the resulting projective point

    # Perform the addition
    lib.blst_p1_add_or_double(ctypes.byref(result_p1), ctypes.byref(p1), ctypes.byref(p2))

    result_bytes = ctypes.create_string_buffer(48)
    lib.blst_p1_compress(result_bytes, ctypes.byref(result_p1))
    # print("Result:", result_bytes.raw.hex())

    # Check if the resulting point is on the curve
    if not lib.blst_p1_on_curve(ctypes.byref(result_p1)):
        print("Resulting point is not on the curve.")

    return result_bytes.raw


def add_scalars(scalar_bytes1: bytes, scalar_bytes2: bytes) -> bytes:
    scalar1 = BlstScalar()
    scalar2 = BlstScalar()
    ctypes.memmove(ctypes.byref(scalar1), scalar_bytes1, 32)
    ctypes.memmove(ctypes.byref(scalar2), scalar_bytes2, 32)

    result_scalar = BlstScalar()

    success = lib.blst_sk_add_n_check(ctypes.byref(result_scalar), ctypes.byref(scalar1), ctypes.byref(scalar2))
    if not success:
        raise ValueError("Scalar addition failed or result is invalid")

    # result_bytes = bytearray(result_scalar.b)
    result_bytes = bytes(result_scalar.b)
    # print("Resulting Scalar:", result_bytes.hex())
    return result_bytes

import filecmp
import os
from typing import BinaryIO

import paramiko
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric.rsa import RSAPublicKey
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes, AEADEncryptionContext, \
    AEADDecryptionContext, AEADCipherContext
from paramiko.rsakey import RSAKey

from storage.repository import Repository

chunk_size = 64 * 1024  # 64 KB chunks
symmetric_key_size = 32
nonce_size = 16


# Encrypt a file using an OpenSSH compatible key and AES symmetric encryption
# key_path: An RSA key
def encrypt(key_path: str, input_file_path: str, encrypted_file_path: str):
    with open(input_file_path, "rb") as infile, open(encrypted_file_path, "wb") as outfile:
        # Open an encrypted stream
        encryptor: AEADEncryptionContext = start_encrypted_stream(key_path, outfile)

        # Write the data
        while chunk := infile.read(chunk_size):
            outfile.write(encryptor.update(chunk))

        # Finalize the stream (not really necessary for CTR mode)
        end_encrypted_stream(encryptor, outfile)


# Init an encryptor for a stream using the specified OpenSSH compatible public key and AES symmetric encryption.
# key_path: Path to the RSA public key
def get_encryptor(key_path: str) -> (AEADEncryptionContext, bytes, bytes):
    # Load the private key
    private_key = paramiko.RSAKey(filename=key_path)

    # Get the public key from the private key
    public_key: RSAPublicKey = serialization.load_ssh_public_key(
        (private_key.get_name() + " " + private_key.get_base64()).encode())

    # Generate a symmetric key for AES encryption
    symmetric_key = os.urandom(symmetric_key_size)
    nonce = os.urandom(nonce_size)

    cipher = get_symmetric_cipher(nonce, symmetric_key)

    # Encrypt the symmetric key with RSA
    encrypted_symmetric_key = public_key.encrypt(
        symmetric_key,
        padding.OAEP(mgf=padding.MGF1(algorithm=hashes.SHA256()), algorithm=hashes.SHA256(), label=None)
    )

    return cipher.encryptor(), encrypted_symmetric_key, nonce


# Encrypt a stream using the specified OpenSSH compatible public key and AES symmetric encryption
# This method writes the key and nonce to the stream.
# public_key: the RSA public key
def start_encrypted_stream(key_path: str, out_stream: BinaryIO):
    encryptor, encrypted_key, nonce, = get_encryptor(key_path)
    # write out the encrypted symmetric key and nonce and return the encryptor
    out_stream.write(encrypted_key)
    out_stream.write(nonce)
    return encryptor


# AES CTR (Counter) block cipher mode encryption is a streaming mode that does not require padding.
# CTR does not implement integrity checking so there is no tag required to terminate the stream.
# Note that we don't need integrity checking at this level since the storage layer will perform committments.
def get_symmetric_cipher(nonce, symmetric_key):
    return Cipher(algorithms.AES(symmetric_key), modes.CTR(nonce), backend=default_backend())


# Finalize the encryption stream.
# For CTR Mode finalizing is not actually required / does nothing since we are not writing a tag.
def end_encrypted_stream(encryptor: AEADEncryptionContext, out_stream: BinaryIO):
    out_stream.write(encryptor.finalize())
    # out_stream.write(encryptor.tag) # CTR mode does not use a tag


# Decrypt an RSA/AES encrypted file created with this module.
# key_path: path to the RSA private key used for encryption.
def decrypt(key_path: str, encrypted_file_path: str, decrypted_file_path: str):
    with open(encrypted_file_path, "rb") as infile, open(decrypted_file_path, "wb") as outfile:
        decryptor = start_decryption_stream(key_path, infile)

        while chunk := infile.read(chunk_size):
            outfile.write(decryptor.update(chunk))

        decryptor.finalize()  # doesn't really do anything since we have no tag


def get_decryptor(key_path: str, encrypted_symmetric_key: bytes, nonce: bytes) -> AEADCipherContext:
    private_key = paramiko.RSAKey(filename=key_path)
    return get_decryptor_with(private_key, encrypted_symmetric_key, nonce)


def get_decryptor_with(private_key: RSAKey, encrypted_symmetric_key: bytes, nonce: bytes) -> AEADDecryptionContext:
    # decrypt the symmetric key
    symmetric_key = private_key.key.decrypt(
        encrypted_symmetric_key,
        padding.OAEP(mgf=padding.MGF1(algorithm=hashes.SHA256()), algorithm=hashes.SHA256(), label=None)
    )
    cipher = get_symmetric_cipher(nonce, symmetric_key)
    return cipher.decryptor()


# Decrypt an RSA/AES encrypted file stream created with this module.
# This method reads the key and nonce from the stream.
# key_path: path to the RSA private key used for encryption.
def start_decryption_stream(key_path: str, in_stream: BinaryIO):
    private_key = paramiko.RSAKey(filename=key_path)

    # read the encrypted symmetric key and nonce
    key_size = private_key.key.key_size // 8
    encrypted_key: bytes = in_stream.read(key_size)
    nonce: bytes = in_stream.read(16)

    return get_decryptor_with(private_key, encrypted_key, nonce)


if __name__ == '__main__':

    def test():
        # Random test file paths
        repo = Repository.default()
        filename = 'file_1MB.dat'
        file_path = repo.tmp_file_path(filename)
        encrypted_file_path = repo.tmp_file_path("encrypted.dat")
        decrypted_file_path = repo.tmp_file_path("decrypted.dat")

        # If the file doesn't exist create it
        if not os.path.exists(file_path):
            with open(file_path, "wb") as f:
                f.write(os.urandom(1 * 1024 * 1024))

        key_path = "test_key"
        encrypt(key_path, file_path, encrypted_file_path)
        decrypt(key_path, encrypted_file_path, decrypted_file_path)
        print("Passed" if filecmp.cmp(file_path, decrypted_file_path) else "Failed")


    test()
    ...

import hashlib
import os
from contextlib import ExitStack

import paramiko
from icecream import ic
from numpy._typing import NDArray

from commitments.kzg_commitment import FileCommitments
from encoding.encrypt import get_encryptor
from encoding.fields import get_field, FIELD_SAFE_SCALAR_SIZE_BYTES, FIELD_ELEMENT_SIZE_BYTES, symbols_to_bytes
from encoding.chunks import ChunkReader
from encoding.twin_coding import rs_generator_matrix, Code, twin_code
from storage.storage_model import EncodedFile, NodeType0, NodeType1, FileEncryption
from storage.repository import Repository
from tqdm import tqdm
import time

from storage.util import get_or_create_random_test_file


# Erasure code a file into two sets of shards, one for each node type in the twin coding scheme.
# The output path will be an encoded storage directory containing both sets of files and a
# config.json file capturing the parameters.
#
# See `twin_coding.py` for more details on twin coding recovery. The encoding procedure in summary
# erasure-encodes the file twice, once with each of the supplied generators, where the data blocks
# of the second type are transposed before encoding.
#
# An optional, OpenSSH compatible key can be provided to encrypt the file as it is read and encoded.
#
# Note: We will parallelize this in a future update.  Lots of opportunity here to read chunks
# Note: in batches and perform encoding in parallel.
#
class FileEncoder(ChunkReader):
    def __init__(self,
                 node_type0: NodeType0,
                 node_type1: NodeType1,
                 input_file: str,
                 output_path: str = None,  # output dir path
                 overwrite: bool = False,
                 encryption_key_path: str = None,
                 ):

        node_type0.assert_reed_solomon()
        node_type1.assert_reed_solomon()
        assert node_type0.k == node_type1.k, "The two node types must have the same k."
        assert node_type0.n > node_type0.k and node_type1.n > node_type1.k, "The node type must have n > k."

        self.node_type0 = node_type0
        print(f"node_type0 = {node_type0}")
        self.node_type1 = node_type1
        print(f"node_type1 = {node_type1}")
        self.k = node_type0.k
        print(f"k = {self.k}")
        self.path = input_file
        self.filename: str = os.path.basename(self.path)
        self.encoded_output_dir = output_path or input_file + '.encoded'
        self.overwrite = overwrite
        self._file_hash = None
        num_elements = self.k ** 2

        # Optional encryption
        self.encryptor, self.encrypted_symmetric_key, self.nonce = get_encryptor(
            encryption_key_path) if encryption_key_path else (None, None, None)

        super().__init__(path=input_file,
                         num_elements=num_elements,
                         element_size=FIELD_SAFE_SCALAR_SIZE_BYTES,
                         cipher=self.encryptor)
        print(f"element size = {self.element_size}, num_elements = 'k^2' = {num_elements}")
        print(f"FileEncoder: chunk size = {self.chunk_size}, num_chunks = {self.num_chunks}")

    # Initialize the output directory that will hold the erasure-encoded chunks.
    def init_output_dir(self) -> bool:
        if os.path.exists(self.encoded_output_dir):
            if not self.overwrite:
                print(f"Output directory already exists: {self.encoded_output_dir}.")
                return False
        else:
            os.makedirs(self.encoded_output_dir)

        self.write_config()
        return True

    def write_config(self):
        file_config = EncodedFile(
            name=os.path.basename(self.path),
            file_hash=self.file_hash(),
            file_length=self.file_length,
            type0=self.node_type0,
            type1=self.node_type1,
            file_encryption=FileEncryption(
                type='AES-CTR',
                encrypted_symmetric_key=self.encrypted_symmetric_key.hex(),
                initialization_vector=self.nonce.hex()
            ) if self.encryptor else None
        )
        config_path = Repository.file_config_path_from(self.encoded_output_dir)
        file_config.save(config_path)

    def write_commitments(self):
        t0_files: dict[str, int]
        t1_files: dict[str, int]
        t0_files, t1_files = Repository.map_shards_from(self.encoded_output_dir)
        all_shards = list(t0_files.keys()) + list(t1_files.keys())
        for shard_file in tqdm(all_shards, desc="Generating commitments"):
            # Output commitments to the same directory as the shards
            commitments_file_path = Repository.shard_commits_path_from_shard_path(shard_file)
            FileCommitments(file_path=shard_file).save(commitments_file_path)
        ...

    # Encode the file to the output dir
    def encode(self):
        self.encode_shards()
        self.write_commitments()

    def encode_shards(self):
        if not self.init_output_dir():
            print(f"Skipping encoding.")
            return

        # The symbol space
        GF = get_field()

        # The two coding schemes.
        k, n0, n1 = self.k, self.node_type0.n, self.node_type1.n
        C0 = Code(k=k, n=n0, GF=GF, G=rs_generator_matrix(GF, k=k, n=n0))
        C1 = Code(k=k, n=n1, GF=GF, G=rs_generator_matrix(GF, k=k, n=n1))

        # Check for existing files
        filenames0 = [f"{self.encoded_output_dir}/type0_node{i}.dat" for i in range(n0)]
        filenames1 = [f"{self.encoded_output_dir}/type1_node{i}.dat" for i in range(n1)]
        if not self.overwrite:
            existing = [f for f in (filenames0 + filenames1) if os.path.exists(f)]
            if existing:
                raise FileExistsError(f"Files already exist: {existing}")

        with ExitStack() as stack:
            # The output files
            files0 = [stack.enter_context(open(f, 'wb')) for f in filenames0]
            files1 = [stack.enter_context(open(f, 'wb')) for f in filenames1]

            # The main encoding loop
            start = time.time()
            with tqdm(total=self.num_chunks, desc='Encoding', unit='chunk') as pbar:
                for ci in range(self.num_chunks):
                    # Get the next chunk, converting each element to a big integer
                    chunk_ints: NDArray[int] = self.get_chunk_ints(ci)

                    # Twin code the chunk (returns two lists of ndarray of symbols)
                    cols0, cols1 = twin_code(GF(chunk_ints), C0, C1)

                    # Write the data to the respective files
                    # print(f"Writing chunk {ci} to files.")
                    for fi in range(n0):
                        files0[fi].write(symbols_to_bytes(cols0[fi], FIELD_ELEMENT_SIZE_BYTES))
                    for fi in range(n1):
                        files1[fi].write(symbols_to_bytes(cols1[fi], FIELD_ELEMENT_SIZE_BYTES))

                    self.update_pbar(ci=ci, pbar=pbar, start=start)
        ...

    def file_hash(self):
        if self._file_hash:
            return self._file_hash
        hash_sha256 = hashlib.sha256()
        with open(self.path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_sha256.update(chunk)
        self._file_hash = hash_sha256.hexdigest()
        return self._file_hash

    def close(self):
        self.mmap.close()


if __name__ == '__main__':
    repo = Repository.default()

    # Random test file
    filename = 'file_1MB.dat'
    path = get_or_create_random_test_file(filename, 1 * 1024 * 1024)

    # Generate a test RSA key if neeeded
    key_path = repo.tmp_file_path('test_key')
    if not os.path.exists(key_path):
        key = paramiko.RSAKey.generate(bits=2048)
        key.write_private_key_file(key_path)

    encoder = FileEncoder(
        node_type0=NodeType0(k=3, n=5, encoding='reed_solomon'),
        node_type1=NodeType1(k=3, n=5, encoding='reed_solomon'),
        input_file=path,
        output_path=repo.file_dir_path(filename, expected=False),
        overwrite=True,
        encryption_key_path=key_path
    )
    encoder.encode()

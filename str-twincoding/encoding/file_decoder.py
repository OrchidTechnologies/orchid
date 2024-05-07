import filecmp
import os
import time
import uuid
from collections import OrderedDict
from typing import Optional

import numpy as np
from galois import FieldArray
from numpy._typing import NDArray
from tqdm import tqdm

from encoding.encrypt import get_decryptor
from encoding.fields import get_field, FIELD_SAFE_SCALAR_SIZE_BYTES, FIELD_ELEMENT_SIZE_BYTES, symbols_to_bytes
from storage.storage_model import NodeType, EncodedFile, FileEncryption
from storage.repository import Repository

from encoding.chunks import ChunksReader, open_output_file
from encoding.twin_coding import rs_generator_matrix


# Decode a set of erasure-coded files supplied as a file map or from a storage-encoded directory.
# When a storage directory with config.json is provided the decoder will determine if a viable set
# of files is present and use them to decode the original file.  In either case at least k files of
# the same node type will be required.  Files are an array of encoded chunks of the original data,
# with the final chunk zero padded.
#
# Use `from_encoded_dir` for initializing a FileDecoder from an encoded dir with a config.json file.
#
# An optional, OpenSSH compatible key can be provided to decrypt the file as it is read and decoded.
#
# Note: We will parallelize this in a future update.  Lots of opportunity here to read chunks
# Note: in batches and perform decoding in parallel.
#
class FileDecoder(ChunksReader):
    def __init__(self,
                 node_type: NodeType,
                 file_map: dict[str, int] = None,
                 output_path: str = None,
                 overwrite: bool = False,
                 org_file_length: int = None,  # original file length without encoder padding
                 encryption_key_path: Optional[str] = None,
                 file_encryption: Optional[FileEncryption] = None,
                 ):

        node_type.assert_reed_solomon()
        self.k = node_type.k
        self.transpose = node_type.transpose
        self.node_type = node_type

        if file_map is None or len(file_map) != self.k:
            raise ValueError(f"file_map must be a dict of exactly {self.k} files.")

        self.output_path = output_path or f"decoded_{uuid.uuid4()}.dat"
        self.overwrite = overwrite
        assert org_file_length is not None
        self.org_file_length = org_file_length
        num_elements = self.k

        # Optional decryption
        if encryption_key_path and not file_encryption:
            raise ValueError("An encryption key was provided but no file encryption metadata.")
        self.decryptor = get_decryptor(encryption_key_path, file_encryption.key, file_encryption.iv) \
            if encryption_key_path else None

        super().__init__(file_map=file_map,
                         num_elements=num_elements,
                         element_size=FIELD_ELEMENT_SIZE_BYTES)
        # print(f"num_elements = 'k' = {num_elements}, element size = {self.element_size}")

    # Init a file decoder from an encoded file dir.  The dir must contain a config.json file and
    # at least k files of the same type.
    @staticmethod
    def from_encoded_dir(
            path: str, output_path: str = None, overwrite: bool = False,
            encryption_key_path: str = None
    ):

        file_config = EncodedFile.load(os.path.join(path, 'config.json'))
        assert file_config.type0.k == file_config.type1.k, "Config node types must have the same k."
        recover_from_files = FileDecoder.get_threshold_files(path, k=file_config.type0.k)
        if os.path.basename(list(recover_from_files)[0]).startswith("type0_"):
            node_type = file_config.type0
        else:
            node_type = file_config.type1
            print("Decoding type 1 node: transposing.")

        return FileDecoder(
            node_type=node_type,
            file_map=recover_from_files,
            output_path=output_path,
            overwrite=overwrite,
            org_file_length=file_config.file_length,
            # Optional decryption
            encryption_key_path=encryption_key_path,
            file_encryption=file_config.file_encryption
        )

    # Map the files in a file store encoded directory. At least k files of the same type must be present
    # to succeed. Returns a map of the first k files of either type found.
    @classmethod
    def get_threshold_files(cls, files_dir: str, k: int) -> dict[str, int]:
        type0_files, type1_files = Repository.map_files(files_dir)
        if len(type0_files) >= k:
            return OrderedDict(list(type0_files.items())[:k])
        elif len(type1_files) >= k:
            return OrderedDict(list(type1_files.items())[:k])
        else:
            raise ValueError(
                f"Insufficient files in {files_dir} to recover: {len(type0_files)} type 0 files, "
                f"{len(type1_files)} type 1 files.")

    # Decode the file to the output path.
    def decode(self):
        with (open_output_file(output_path=self.output_path, overwrite=self.overwrite) as out):
            k, n = self.node_type.k, self.node_type.n
            GF = get_field()
            G = rs_generator_matrix(GF, k=k, n=n)
            g = G[:, self.files_indices]
            ginv = np.linalg.inv(g)

            # TODO: This will be parallelized
            start = time.time()
            with tqdm(total=self.num_chunks, desc='Decoding', unit='chunk') as pbar:
                for ci in range(self.num_chunks):
                    # list of ndarrays, each containing num_elements big ints.
                    file_chunks_ints = self.get_chunks_ints(ci)

                    # Reshape each chunk as a stack of column vectors forming a k x k matrix
                    matrix = np.hstack([chunk.reshape(-1, 1) for chunk in file_chunks_ints])

                    # Decode the original data
                    decoded = GF(matrix) @ ginv

                    if self.transpose:
                        decoded = decoded.T

                    # Flatten the matrix back to an array of symbols
                    symbols: NDArray[FieldArray] = decoded.reshape(-1)

                    # Convert each symbol to bytes at the original size.
                    chunk = symbols_to_bytes(symbols, FIELD_SAFE_SCALAR_SIZE_BYTES)

                    # Optional decryption
                    if self.decryptor:
                        chunk = self.decryptor.update(chunk)

                    # Write to the output file
                    out.write(chunk)

                    # Progress bar
                    self.update_pbar(ci=ci, num_files=k, pbar=pbar, start=start)
                ...
            ...
        ...

        # Trim the output file to the original file length to account for padding at ingestion time.
        with open(self.output_path, 'rb+') as f:
            f.truncate(self.org_file_length)

    def close(self):
        [mm.close() for mm in self.mmaps]


if __name__ == '__main__':
    repo = Repository.default()
    filename = 'file_1MB.dat'
    original_file = repo.tmp_file_path(filename)
    encoded_file = repo.file_dir_path(filename)
    recovered_file = repo.tmp_file_path(f'recovered_{filename}')

    file_status = repo.file_status(filename)
    print(file_status.status_str())

    # optional encryption key
    key_path = repo.tmp_file_path('test_key')

    decoder = FileDecoder.from_encoded_dir(
        path=encoded_file,
        output_path=recovered_file,
        overwrite=True,
        encryption_key_path=key_path
    )
    decoder.decode()
    print("Passed" if filecmp.cmp(original_file, recovered_file) else "Failed")

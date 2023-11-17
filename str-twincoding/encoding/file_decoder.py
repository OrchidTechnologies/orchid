import filecmp
import os
import time
import uuid
from collections import OrderedDict
import galois
import numpy as np
from tqdm import tqdm

from storage.config import NodeType, EncodedFileConfig
from storage.util import assert_rs
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
# Note: We will parallelize this in a future update.  Lots of opportunity here to read chunks
# Note: in batches and perform decoding in parallel.
#
class FileDecoder(ChunksReader):
    def __init__(self,
                 node_type: NodeType,
                 file_map: dict[str, int] = None,
                 output_path: str = None,
                 overwrite: bool = False,
                 org_file_length: int = None  # original file length without encoder padding
                 ):

        assert_rs(node_type)
        self.k = node_type.k
        self.transpose = node_type.transpose
        self.node_type = node_type

        if file_map is None or len(file_map) != self.k:
            raise ValueError(f"file_map must be a dict of exactly {self.k} files.")

        self.output_path = output_path or f"decoded_{uuid.uuid4()}.dat"
        self.overwrite = overwrite
        self.org_file_length = org_file_length

        chunk_size = self.k  # individual columns of size k
        super().__init__(file_map=file_map, chunk_size=chunk_size)

    # Init a file decoder from an encoded file dir.  The dir must contain a config.json file and
    # at least k files of the same type.
    @staticmethod
    def from_encoded_dir(path: str, output_path: str = None, overwrite: bool = False):
        file_config  = EncodedFileConfig.load(os.path.join(path, 'config.json'))
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
            org_file_length=file_config.file_length
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
        with open_output_file(output_path=self.output_path, overwrite=self.overwrite) as out:
            k, n = self.node_type.k, self.node_type.n
            GF = galois.GF(2 ** 8)
            G = rs_generator_matrix(GF, k=k, n=n)
            g = G[:, self.files_indices]
            ginv = np.linalg.inv(g)

            # TODO: This will be parallelized
            start = time.time()
            with tqdm(total=self.num_chunks, desc='Decoding', unit='chunk') as pbar:
                for ci in range(self.num_chunks):
                    chunks = self.get_chunks(ci)

                    # Decode each chunk as a stack of column vectors forming a k x k matrix
                    matrix = np.hstack([chunk.reshape(-1, 1) for chunk in chunks])
                    decoded = GF(matrix) @ ginv
                    if self.transpose:
                        decoded = decoded.T
                    bytes = decoded.reshape(-1).tobytes()

                    # Trim the last chunk if it is padded
                    size = (ci + 1) * self.chunk_size * k
                    if size > self.org_file_length:
                        bytes = bytes[:self.org_file_length - size]

                    # Write the data to the output file
                    out.write(bytes)

                    # Progress bar
                    self.update_pbar(ci=ci, num_files=k, pbar=pbar, start=start)
        ...

    def close(self):
        [mm.close() for mm in self.mmaps]


if __name__ == '__main__':
    repo = Repository('./repository')
    filename = 'file_1KB.dat'
    original_file = repo.tmp_file_path(filename)
    encoded_file = repo.file_path(filename)
    print(repo.status_str(filename))

    recovered_file = repo.tmp_file_path(f'recovered_{filename}')
    decoder = FileDecoder.from_encoded_dir(
        path=encoded_file,
        output_path=recovered_file,
        overwrite=True
    )
    decoder.decode()
    print("Passed" if filecmp.cmp(original_file, recovered_file) else "Failed")

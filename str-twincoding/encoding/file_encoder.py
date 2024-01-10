import hashlib
import os
from contextlib import ExitStack
import galois
from icecream import ic

from encoding.chunks import ChunkReader
from encoding.twin_coding import rs_generator_matrix, Code, twin_code
from storage.storage_model import EncodedFile, NodeType0, NodeType1, assert_rs
from storage.repository import Repository
from tqdm import tqdm
import time


# Erasure code a file into two sets of shards, one for each node type in the twin coding scheme.
# The output path will be an encoded storage directory containing both sets of files and a
# config.json file capturing the parameters.
#
# See `twin_coding.py` for more details on twin coding recovery. The encoding procedure in summary
# erasure-encodes the file twice, once with each of the supplied generators, where the data blocks
# of the second type are transposed before encoding.
#
# Note: We will parallelize this in a future update.  Lots of opportunity here to read chunks
# Note: in batches and perform encoding in parallel.
#
class FileEncoder(ChunkReader):
    def __init__(self,
                 node_type0: NodeType0,
                 node_type1: NodeType1,
                 input_file: str,
                 output_path: str = None,
                 overwrite: bool = False):

        assert_rs(node_type0)
        assert_rs(node_type1)
        assert node_type0.k == node_type1.k, "The two node types must have the same k."
        assert node_type0.n > node_type0.k and node_type1.n > node_type1.k, "The node type must have n > k."

        self.node_type0 = node_type0
        self.node_type1 = node_type1
        self.k = node_type0.k
        self.path = input_file
        self.output_dir = output_path or input_file + '.encoded'
        self.overwrite = overwrite
        self._file_hash = None
        chunk_size = self.k ** 2
        super().__init__(path=input_file, chunk_size=chunk_size)

    # Initialize the output directory that will hold the erasure-encoded chunks.
    def init_output_dir(self) -> bool:
        if os.path.exists(self.output_dir):
            if not self.overwrite:
                print(f"Output directory already exists: {self.output_dir}.")
                return False
        else:
            os.makedirs(self.output_dir)

        with open(os.path.join(self.output_dir, 'config.json'), 'w') as f:
            file_config = EncodedFile(
                name=os.path.basename(self.path),
                file_hash=self.file_hash(),
                file_length=self.file_length,
                type0=self.node_type0,
                type1=self.node_type1,
            )
            f.write(file_config.model_dump_json(indent=2, exclude_defaults=True))
        return True

    # Encode the file to the output dir
    def encode(self):
        if not self.init_output_dir():
            print(f"Skipping encoding.")
            return

        # The symbol space
        GF = galois.GF(2 ** 8)

        # The two coding schemes.
        k, n0, n1 = self.k, self.node_type0.n, self.node_type1.n
        C0 = Code(k=k, n=n0, GF=GF, G=rs_generator_matrix(GF, k=k, n=n0))
        C1 = Code(k=k, n=n1, GF=GF, G=rs_generator_matrix(GF, k=k, n=n1))

        # Check for existing files
        filenames0 = [f"{self.output_dir}/type0_node{i}.dat" for i in range(n0)]
        filenames1 = [f"{self.output_dir}/type1_node{i}.dat" for i in range(n1)]
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
                    # Twin code the chunk
                    chunk = self.get_chunk(ci)
                    cols0, cols1 = twin_code(GF(chunk), C0, C1)

                    # Write the data to the respective files
                    for fi in range(n0):
                        files0[fi].write(cols0[fi].tobytes())
                    for fi in range(n1):
                        files1[fi].write(cols1[fi].tobytes())

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
    filename = 'file_1KB.dat'
    file = repo.tmp_file_path(filename)
    ic(file)
    # If the file doesn't exist create it
    if not os.path.exists(file):
        with open(file, "wb") as f:
            f.write(os.urandom(1024))

    encoder = FileEncoder(
        node_type0=NodeType0(k=3, n=5, encoding='reed_solomon'),
        node_type1=NodeType1(k=3, n=5, encoding='reed_solomon'),
        input_file=file,
        output_path=repo.file_dir_path(filename, expected=False),
        overwrite=True
    )
    encoder.encode()

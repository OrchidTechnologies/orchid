import filecmp
import os

from galois import FieldArray
from icecream import ic

from encoding.fields import get_field, FIELD_SAFE_SCALAR_SIZE_BYTES, symbols_to_bytes
from encoding.chunks import ChunkReader
from storage.repository import Repository
from tqdm import tqdm
import time

from storage.util import get_or_create_random_test_file


# Test the round trip of a file through the Galois Field symbol encoding and decoding.
class GFFileRoundtripTest(ChunkReader):
    def __init__(self, input_file: str, output_path: str = None):
        self.path = input_file
        self.output_path = output_path
        self.k = 3  # example
        num_elements = self.k ** 2
        super().__init__(path=input_file,
                         num_elements=num_elements,
                         element_size=FIELD_SAFE_SCALAR_SIZE_BYTES)
        print(f"element size = {self.element_size}, num_elements = 'k^2' = {num_elements}")
        print(f"FileEncoder: chunk size = {self.chunk_size}, num_chunks = {self.num_chunks}")

    # Encode the file to the output path
    def encode(self):
        # The symbol space
        GF = get_field()

        # Round trip chunks to field elements and back
        with open(self.output_path, 'wb') as outfile:
            start = time.time()
            with tqdm(total=self.num_chunks, desc='Encoding', unit='chunk') as pbar:
                for ci in range(self.num_chunks):
                    # Get a chunk as ints
                    chunk_ints = self.get_chunk_ints(ci)

                    # Convert to symbols
                    chunk_gf: FieldArray = GF(chunk_ints)

                    # Write the data back to the output file
                    outfile.write(symbols_to_bytes(chunk_gf, FIELD_SAFE_SCALAR_SIZE_BYTES))

                    self.update_pbar(ci=ci, pbar=pbar, start=start)
                ...
            ...
        ...
        # Trim the output file to the original file length to account for padding at ingestion time.
        with open(self.output_path, 'rb+') as f:
            # input file length
            f.truncate(self.file_length)


def test_gf_file_roundtrip():
    repo = Repository.default()

    # Random test file and output path
    filename = 'file_1MB.dat'
    file = get_or_create_random_test_file(filename, 1 * 1024 * 1024)
    outpath = repo.tmp_file_path('gf_test.dat')

    encoder = GFFileRoundtripTest(
        input_file=file,
        output_path=outpath,
    )
    encoder.encode()
    print("Passed" if filecmp.cmp(file, outpath) else "Failed")


def test_simple():
    # generate 31 random bytes
    bytes = os.urandom(31)

    # convert to hex
    print(f"Bytes: {len(bytes)}, {bytes.hex()}")
    GF = get_field()
    el_int = int.from_bytes(bytes=bytes, byteorder='big')
    el_gf: FieldArray = GF(el_int)
    print(f"Element: {el_gf}")
    print("back to int: ", int(el_gf))
    print("back to bytes: ", int(el_gf).to_bytes(31, byteorder='big').hex())


if __name__ == '__main__':
    test_simple()
    test_gf_file_roundtrip()

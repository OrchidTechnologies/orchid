import io
import os
import time
from typing import Optional

import math
import numpy as np
from cryptography.hazmat.primitives.ciphers import AEADEncryptionContext, AEADCipherContext
from icecream import ic
from numpy._typing import NDArray
from tqdm import tqdm


# Note: We will parallelize these in a future update.  Lots of opportunity here to read chunks
# Note: in batches and perform encoding/decoding in parallel.

#
# Base for classes that read chunks from a single input file.
# File chunks are read using mmap in fixed size chunks with padding if necessary.
# The chunks are reshaped to have the correct number of elements and can optionally be read
# as big integers.
#
# An optional AES encryption context can be provided to encrypt or decrypt the chunks as they are read.
#
class ChunkReader:
    def __init__(self, path: str, num_elements: int, element_size: int,
                 cipher: Optional[AEADCipherContext] = None):
        self.path = path
        self.num_elements = num_elements
        self.element_size = element_size
        self.chunk_size = num_elements * element_size
        self.file_length = os.path.getsize(path)
        self.num_chunks = math.ceil(self.file_length / self.chunk_size)
        self.mmap = None
        self.cipher = cipher

    # Returns an ndarray of shape (num_elements, elements_size) bytes that shares memory with the mmap.
    # The final chunk will be padded with zeros if required to fill the chunk size.
    def get_chunk(self, i: int):
        if self.mmap is None:
            self.mmap = np.memmap(self.path, dtype='uint8', mode='r')

        start_idx = i * self.chunk_size
        end_idx = start_idx + self.chunk_size

        if start_idx >= self.file_length:
            raise IndexError("Start index is out of bounds.")

        # Ensure end_idx does not exceed the file length.
        end_idx = min(end_idx, self.file_length)

        # Read the data chunk.
        chunk = self.mmap[start_idx:end_idx]

        # Pad if necessary.
        if end_idx - start_idx < self.chunk_size:
            padding_length = self.chunk_size - (end_idx - start_idx)
            chunk = np.concatenate((chunk, np.zeros(padding_length, dtype='uint8')))

        # Apply the cipher if provided.
        if self.cipher:
            chunk = self.cipher.update(chunk)
            chunk = np.frombuffer(chunk, dtype=np.uint8) # back to numpy

        # Reshape the chunk to have the correct number of elements.
        chunk = chunk.reshape((self.num_elements, self.element_size))

        return chunk

    # Returns an ndarray of num_elements where the elements are transformed to (possibly very large) ints.
    def get_chunk_ints(self, i: int):
        chunk = self.get_chunk(i)
        return np.array([int.from_bytes(bytes=element, byteorder='big') for element in chunk])

    def update_pbar(self, ci: int, pbar: tqdm, start: float):
        rate = ci * self.chunk_size / (time.time() - start)
        pbar.set_postfix({"Rate": f"{rate / (1024 * 1024):.4f}MB/s"}, refresh=True)
        pbar.update(1)


# Base for classes that read chunks from multiple files in parallel.
class ChunksReader:
    def __init__(self, file_map: dict[str, int], num_elements: int, element_size: int):
        self.files: [str] = list(file_map.keys())
        self.files_indices: list[int] = list(file_map.values())

        self.num_elements = num_elements
        self.element_size = element_size
        self.chunk_size = num_elements * element_size

        self.num_chunks = self.validate_files(
            files=self.files, file_indices=self.files_indices, chunk_size=self.chunk_size)
        self.mmaps = None

    # Validate that the files are of the same length and are a multiple of chunk_size.
    # Return the number of chunks.
    @staticmethod
    def validate_files(files: list[str], file_indices: list[int], chunk_size: int) -> int:

        print("chunk size:", chunk_size)

        file_sizes = [os.path.getsize(file_path) for file_path in files]

        # Check if all files are the same length
        if len(set(file_sizes)) != 1:
            raise ValueError("Files are not the same length.")

        # Check if file_indices are unique
        if len(set(file_indices)) != len(file_indices):
            raise ValueError("File indices are not unique.")

        # Check if the file length is a multiple of chunk_size
        file_size = file_sizes[0]  # All sizes are the same, pick the first
        if file_size % chunk_size != 0:
            raise ValueError("File length is not a multiple of chunk_size.")

        return file_size // chunk_size

    # Read data chunks at index i from each of the specified files.
    # Return a list of ndarrays, each of shape (num_elements, element_size) bytes.
    # The files are expected to be a multiple of chunk_size.
    def get_chunks(self, i: int) -> [NDArray]:
        if i >= self.num_chunks:
            raise IndexError("chunk index is out of bounds.")

        if self.mmaps is None:
            self.mmaps = [np.memmap(f, dtype='uint8', mode='r') for f in self.files]

        start_idx = i * self.chunk_size
        end_idx = (i + 1) * self.chunk_size

        # The files have been previously validated to be a multiple of chunk_size.
        file_chunks = [mmap[start_idx:end_idx] for mmap in self.mmaps]

        # Reshape the chunk to have the correct number of elements.
        return [chunk.reshape((self.num_elements, self.element_size)) for chunk in file_chunks]

    # Read data chunks at index i from each of the (k) files.
    # Return a list of ndarrays, each containing num_elements (possibly very large) ints.
    def get_chunks_ints(self, i: int) -> [NDArray]:
        file_chunks = self.get_chunks(i)
        return [np.array([int.from_bytes(bytes=element, byteorder='big') for element in chunk])
                for chunk in file_chunks]

    def update_pbar(self, ci: int, num_files: int, pbar: tqdm, start: float):
        rate = ci * self.chunk_size * num_files / (time.time() - start)
        pbar.set_postfix({"Rate": f"{rate / (1024 * 1024):.4f}MB/s"}, refresh=True)
        pbar.update(1)


def open_output_file(output_path: str, overwrite: bool) -> Optional[io.BufferedWriter]:
    if not overwrite and os.path.exists(output_path):
        print(f"Output file already exists: {output_path}.")
        return None

    # Make intervening directories if needeed
    directory = os.path.dirname(output_path)
    if directory:
        os.makedirs(directory, exist_ok=True)

    return io.BufferedWriter(open(output_path, 'wb'))

import hashlib
import os
from typing import List

import ckzg
from pathlib import Path
from encoding.chunks import ChunkReader
from server.server_model import Proof
from storage.storage_model import BlobCommitments
from storage.util import get_or_create_random_test_file

# The field scalars are read at the rounded down byte size (to guarantee that they remain less than p).
EIP_4844_FIELD_SAFE_SCALAR_SIZE_BYTES: int = 31

# The stored size of the element is the rounded up byte size.
EIP_4844_FIELD_ELEMENT_SIZE_BYTES: int = 32

# The number of field elements that fit in a blob.
EIP_4844_FIELD_ELEMENTS_PER_BLOB = 4096


# Get the KZG trusted setup.
def get_kzg_setup() -> object:
    cwd = Path(__file__).resolve()
    path = os.path.join(cwd.parent, "kzg_trusted_setup.txt")
    return ckzg.load_trusted_setup(path)


# Encapsulate commitment operations on a file.
class FileCommitments(ChunkReader):
    def __init__(self, file_path: str):
        # Limit the blob field size to the safe scalar size, 31 bytes per element.
        super().__init__(path=file_path,
                         num_elements=EIP_4844_FIELD_ELEMENTS_PER_BLOB,
                         element_size=EIP_4844_FIELD_SAFE_SCALAR_SIZE_BYTES)
        self.setup = get_kzg_setup()
        ...

    @property
    def blob_count(self) -> int:
        return self.num_chunks

    # Get commitments for each, EIP-4844 sized chunk of the file.
    # The final commitment represents a chunk that may be padded with zeros to the full blob size.
    # ~8.26 blobs per MB * 48 bytes per commitment = ~396 bytes per MB or ~406K bytes per GB
    def get_commitments(self, indices: list[int] = None) -> [bytes]:
        commitments = []
        for ci in indices or range(self.num_chunks):
            chunk = self.get_chunk(ci)
            blob = self._pad_field_sizes(chunk)
            commitments.append(ckzg.blob_to_kzg_commitment(blob, self.setup))

        return commitments

    # Get the commitment for the blob at index i
    def get_commitment(self, i: int) -> list[object]:
        return self.get_commitments([i])[0]

    # Get proofs for the specified blob indices, generating the corresponding commitments as needed.
    # e.g. used by the server to generate proofs for the blobs requested by the client.
    def get_proofs(self, z_eval: bytes, indices: list[int]) -> list[Proof]:
        proofs = []
        for ci in indices or range(self.num_chunks):
            chunk = self.get_chunk(ci)
            blob = self._pad_field_sizes(chunk)
            # z_eval is the challenge
            proof: bytes
            y_out: bytes
            proof, y_eval = ckzg.compute_kzg_proof(blob, z_eval, self.setup)
            proofs.append(Proof(proof=proof.hex(), y_eval=y_eval.hex()))

        return proofs

    # Get the proof for the blob at index i
    def get_proof(self, i: int) -> object:
        return self.get_proofs([i])[0]

    # Generate and store commitments to the commitments.json file
    def save(self, path: str):
        filename = os.path.basename(self.path)
        commitments = self.get_commitments()
        commitments_hex = [commitment.hex() for commitment in commitments]
        BlobCommitments(file_name=filename, commitments=commitments_hex).save(path)

    # Verify a list of proofs against the corresponding commitments.
    # e.g. may be used by the client to verify the proofs received from the server against
    # stored commitments (notably, without even having the blobs).
    @staticmethod
    def verify_proofs(z_eval: bytes, commitments: List[bytes], proofs: List[Proof], setup: object) -> bool:
        for commitment, proof_obj in zip(commitments, proofs):
            proof = proof_obj.proof_bytes()
            y_eval = proof_obj.y_eval_bytes()
            if not ckzg.verify_kzg_proof(commitment, z_eval, y_eval, proof, setup):
                return False
        return True

    # Each element is padded to the full field size.
    @staticmethod
    def _pad_field_sizes(chunk):
        # Pad each element to the full field size.
        blob = b''
        for element in chunk:
            blob += b'\x00' + element.tobytes()
        return blob

    ...

    # 32 bytes with values capped at 31 bytes (less than the order of the curve).
    # bls12381_n = 0x73EDA753299D7D483339D80809A1D80553BDA402FFFE5BFEFFFFFFFF00000001
    @staticmethod
    def random_field_element() -> bytes:
        return b'\x00' + os.urandom(31)

    @classmethod
    def get_random_challenge(cls) -> bytes:
        return cls.random_field_element()

    @staticmethod
    # Get indices_count random indices from the range (0, blob_count).
    def challenge_to_indices(challenge: bytes, blob_count: int, indices_count: int) -> List[int]:
        # use sha256 to get a random index
        indices = []
        for i in range(indices_count):
            indices.append(int.from_bytes(hashlib.sha256(challenge + bytes([i])).digest(), 'big') % blob_count)
        return indices


# main
if __name__ == "__main__":
    # Random test file
    filename = 'file_1MB.dat'
    file_path = get_or_create_random_test_file(filename, 1 * 1024 * 1024)

    file_commitments = FileCommitments(file_path)
    commitments = file_commitments.get_commitments()
    for i, commitment in enumerate(commitments):
        print(f"Commitment {i}: {commitment.hex()}, {len(commitment)}")
    ...

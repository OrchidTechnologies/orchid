import filecmp
import os
import re
import time
import uuid
from collections import OrderedDict
import galois
import numpy as np
from tqdm import tqdm

from encoding.chunks import ChunksReader, open_output_file
from encoding.twin_coding import rs_generator_matrix
from storage.storage_model import NodeType, NodeType1
from storage.repository import Repository


# Consume recovery files from k nodes to recover a lost shard's data.
# The recovered shard type will be the opposite of the recovery source node type.
# See `node_recovery_source.py` for generating the recovery files.
#
# Note: We will parallelize this in a future update.
#
class NodeRecoveryClient(ChunksReader):
    def __init__(self,
                 recovery_source_node_type: NodeType,
                 file_map: dict[str, int] = None,
                 output_path: str = None,
                 overwrite: bool = False):

        recovery_source_node_type.assert_reed_solomon()
        self.recovery_source_node_type = recovery_source_node_type
        self.k = recovery_source_node_type.k

        if file_map is None or len(file_map) != self.k:
            raise ValueError(f"file_map must be a dict of exactly {self.k} files.")

        self.output_path = output_path or f"decoded_{uuid.uuid4()}.dat"
        self.overwrite = overwrite

        # chunk size is 1 symbol (byte) from each file
        super().__init__(file_map=file_map, chunk_size=1)

    # Map recovery files in a directory. Exactly k recovery files should be present.
    @staticmethod
    def map_files(files_dir: str,
                  recover_node_type: int,
                  recover_node_index: int,
                  k: int) -> dict[str, int]:
        files = {}
        prefix = f"recover_type{recover_node_type}_node{recover_node_index}"
        for filename in os.listdir(files_dir):
            if filename.startswith(prefix) and filename.endswith(".dat"):
                match = re.search(r"from(\d+)", filename)
                index = int(match.group(1)) if match else None
                if index is None:
                    continue
                files[os.path.join(files_dir, filename)] = index

        assert len(files) == k, "Exactly k recovery files must be present."
        return OrderedDict(sorted(files.items(), key=lambda x: x[1])[:k])

    def recover_node(self):
        print(f"Recovering node to: {self.output_path}")
        GF = galois.GF(2 ** 8)
        G = rs_generator_matrix(GF, self.recovery_source_node_type.k, self.recovery_source_node_type.n)
        with open_output_file(output_path=self.output_path, overwrite=self.overwrite) as out:
            start = time.time()
            with tqdm(total=self.num_chunks, desc='Recovery', unit='chunk') as pbar:
                for ci in range(self.num_chunks):
                    chunks: [np.ndarray] = self.get_chunks(ci)
                    # turn chunks into a single column vector
                    col = GF(np.concatenate(chunks))

                    # Now treat the responses as a vector and perform erasure decoding using the
                    # recovery source node type's encoding matrix.
                    g = G[:, self.files_indices]
                    ginv = np.linalg.inv(g)
                    recovered = (col @ ginv).tobytes()

                    # Write the data to the output file
                    out.write(recovered)

                    # Progress bar
                    self.update_pbar(ci=ci, num_files=self.k, pbar=pbar, start=start)
        ...


if __name__ == '__main__':
    file = 'file_1KB.dat'
    repo = Repository.default()

    # Use recovery files generated for type 1 node index 0 to recover the lost data shard.
    recovery_files_dir = repo.file_dir_path(file)
    recover_node_type = 1
    recover_node_index = 0
    recovered_shard = repo.tmp_file_path(
        f'recovered_{file}_type{recover_node_type}_node{recover_node_index}.dat')

    NodeRecoveryClient(
        recovery_source_node_type=NodeType1(k=3, n=5, encoding='reed_solomon'),
        file_map=NodeRecoveryClient.map_files(
            files_dir=recovery_files_dir,
            recover_node_type=recover_node_type,
            recover_node_index=recover_node_index,
            k=3),
        output_path=recovered_shard,
        overwrite=True
    ).recover_node()

    original_shard = repo.shard_path(file, node_type=1, node_index=0)
    print("Passed" if filecmp.cmp(original_shard, recovered_shard) else "Failed")
    ...

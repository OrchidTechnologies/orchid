import filecmp
import os
import time
import uuid
from collections import OrderedDict
import galois
import numpy as np
from tqdm import tqdm
from chunks import ChunksReader
from config import NodeType
from twin_coding import rs_generator_matrix
from util import assert_rs, open_output_file


# Consume recovery files from k nodes of the opposite type to recover a lost node's data.
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

        assert_rs(recovery_source_node_type)
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
    def map_files(files_dir: str, k: int) -> dict[str, int]:
        files = {}

        for filename in os.listdir(files_dir):
            if filename.startswith("recover_") and filename.endswith(".dat"):
                index = int(filename.split("_")[1].split(".")[0])
                files[os.path.join(files_dir, filename)] = index

        assert len(files) == k, "Exactly k recovery files must be present."
        return OrderedDict(sorted(files.items(), key=lambda x: x[1])[:k])

    def recover_node(self):
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
    # Use recovery files generated for type 1 node index 0 to recover the lost data shard.
    recovery_files_dir = 'recover_type1_node0'
    recovered = 'recovered_type1_node0.dat'
    NodeRecoveryClient(
        recovery_source_node_type=NodeType(k=3, n=5, encoding='reed_solomon'),
        file_map=NodeRecoveryClient.map_files(files_dir=recovery_files_dir, k=3),
        output_path=recovered,
        overwrite=True
    ).recover_node()

    compare_file = 'file_1KB.dat.encoded/type1_node0.dat'
    print("Passed" if filecmp.cmp(compare_file, recovered) else "Failed")
    ...

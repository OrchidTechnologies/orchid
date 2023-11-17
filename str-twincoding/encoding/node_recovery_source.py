import time
import galois
from tqdm import tqdm

from storage.config import NodeType, NodeType1
from storage.repository import Repository
from encoding.chunks import ChunkReader, open_output_file
from encoding.twin_coding import rs_generator_matrix


# Generate a node recovery file for a specified node of the opposite type.
# This file will be one of 'k' node recovery files that can be combined to directly recover
# the lost node's data slice without requiring a full file reconstruction and re-encoding of the original.
#
# Note: We will parallelize this in a future update.
#
# TODO: We don't currently have a way to assert that the source and client nodes are of opposite types.
#
class NodeRecoverySource(ChunkReader):
    def __init__(self,
                 # Node information for the recover node (client node).
                 recover_node_type: NodeType,
                 recover_node_index: int,
                 # Node information for this node (source node)
                 data_path: str,
                 # Output
                 output_path: str = None,
                 overwrite: bool = False):
        super().__init__(path=data_path, chunk_size=recover_node_type.k)
        assert recover_node_type.encoding == 'reed_solomon', "Only reed solomon encoding is currently supported."
        self.recover_node_type = recover_node_type
        assert recover_node_index < recover_node_type.k, "Recover node index must be less than k."
        self.recover_node_index = recover_node_index
        self.output_path = output_path or f"recover_{recover_node_index}.dat"
        self.overwrite = overwrite

    # Generate the node recovery file for the client node
    def generate(self):
        GF = galois.GF(2 ** 8)
        # The encoding vector of the failed node is the i'th column of the generator matrix of its type.
        G = rs_generator_matrix(GF, self.recover_node_type.k, self.recover_node_type.n)
        encoding_vector = G[:, self.recover_node_index]
        with (open_output_file(output_path=self.output_path, overwrite=self.overwrite) as out):
            start = time.time()
            with tqdm(total=self.num_chunks, desc='Gen Recovery', unit='chunk') as pbar:
                for ci in range(self.num_chunks):
                    chunk = GF(self.get_chunk(ci))
                    symbol = encoding_vector @ chunk
                    out.write(symbol)
                    self.update_pbar(ci=ci, pbar=pbar, start=start)
        ...


if __name__ == '__main__':
    file = 'file_1KB.dat'
    repo = Repository('./repository')

    # The recovering node
    recover_node_encoding = NodeType1(k=3, n=5, encoding='reed_solomon')
    recover_node_index = 0

    # Use three helper nodes of type 0 to generate recovery files for a node of type 1.
    helper_node_type = 0
    for helper_node_index in range(3):
        # The input path of the helper node's shard
        helper_shard_path = repo.shard_path(
            file, node_type=helper_node_type, node_index=helper_node_index)
        # The output path of the recovery file
        recovery_file_path = repo.recovery_file_path(
            file,
            recover_node_type=recover_node_encoding.type,
            recover_node_index=recover_node_index,
            helper_node_index=helper_node_index,
            expected=False)

        NodeRecoverySource(
            recover_node_type=recover_node_encoding,
            recover_node_index=recover_node_index,
            data_path=helper_shard_path,
            output_path=recovery_file_path,
            overwrite=True
        ).generate()
    ...

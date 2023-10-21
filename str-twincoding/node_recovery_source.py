import time
import galois
from tqdm import tqdm

from chunks import ChunkReader
from config import NodeType, NodeType1
from twin_coding import rs_generator_matrix
from util import open_output_file


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
    # Use a type 0 node source to generate recovery files for recovering node type 1 index 0.
    for i in range(3):
        NodeRecoverySource(
            recover_node_type=NodeType1(k=3, n=5, encoding='reed_solomon'),
            recover_node_index=0,
            data_path=f'file_1KB.dat.encoded/type0_node{i}.dat',
            output_path=f'recover_type1_node0/recover_{i}.dat',
            overwrite=True
        ).generate()
    ...

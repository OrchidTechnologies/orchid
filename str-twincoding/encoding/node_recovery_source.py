import time
import galois
from icecream import ic
from tqdm import tqdm

from storage.renderable import Renderable
from storage.storage_model import NodeType
from storage.repository import Repository
from encoding.chunks import ChunkReader, open_output_file
from encoding.twin_coding import rs_generator_matrix


# Generate a node recovery file for a specified node of the opposite type.
# This file will be one of 'k' node recovery files that can be combined to directly recover
# the lost node's data slice without requiring a full file reconstruction and re-encoding of the original.
#
# Note: We will parallelize this in a future update.
#
class NodeRecoverySource(ChunkReader, Renderable):

    # This file level init.
    # @see `NodeRecoverySource.for_nodes()` which works with at the repository level.
    def __init__(
            self,
            # Node information for the recover node (client node).
            recover_node_type: NodeType,
            recover_node_index: int,

            # Node information for the source "helper" node.
            data_path: str,

            # Output
            output_path: str = None,
            overwrite: bool = False
    ):
        super().__init__(path=data_path, chunk_size=recover_node_type.k)
        recover_node_type.assert_reed_solomon()
        self.recover_node_type = recover_node_type
        assert recover_node_index < recover_node_type.n, "Recover node index must be less than n."
        self.recover_node_index = recover_node_index
        self.output_path = output_path or f"recover_{recover_node_index}.dat"
        self.overwrite = overwrite

    # Implement hash
    def __hash__(self):
        return hash(self.output_path)

    @classmethod
    # Init a NodeSourceRecovery instance using the specified repository file conventions.
    def for_repo(
            cls,
            repo: Repository,
            filename: str,

            # Node information for the recovering node (client node).
            recover_node_type: NodeType,
            recover_node_index: int,

            # Node information for the source "helper" node.
            source_node_type: NodeType,
            source_node_index: int,

            overwrite: bool = False
    ):
        # The source and recover nodes must be of opposing types (0, 1).
        assert recover_node_type.type != source_node_type.type, "Node types must be different."

        # The input path of the helper node's shard
        helper_shard_path = repo.shard_path(
            filename, node_type=source_node_type.type, node_index=source_node_index, expected=True)

        # The output path of the recovery file
        recovery_file_path = repo.recovery_file_path(
            filename,
            recover_node_type=recover_node_type.type,
            recover_node_index=recover_node_index,
            helper_node_index=source_node_index,
            expected=False)

        return cls(
            recover_node_type=recover_node_type,
            recover_node_index=recover_node_index,
            data_path=helper_shard_path,
            output_path=recovery_file_path,
            overwrite=overwrite
        )

    # Generate the node recovery file for the client node
    def render(self):
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

    # Test requesting a single recovery file from a provider
    # ./storage.sh request_recovery_file --provider http://localhost:8080 --overwrite --recover_node_type 0
    # --recover_node_index 0 --source_node_index 0 file_1KB.dat

    def main():
        filename = 'file_1KB.dat'
        repo = Repository.default()

        # The node and shard to recover
        recover_node_type = 1
        recover_node_encoding = NodeType(type=recover_node_type, k=3, n=5, encoding='reed_solomon')
        recover_node_index = 0

        # Use k (3) helper nodes of the opposite type (0) to generate k (3) recovery files for
        # the recovering nodes't type (1).
        helper_node_type = 0 if recover_node_type == 1 else 1
        for helper_node_index in range(3):
            helper_node_encoding = NodeType(
                type=helper_node_type,
                encoding=recover_node_encoding.encoding,
                k=recover_node_encoding.k,
                n=recover_node_encoding.n
            )

            NodeRecoverySource.for_repo(
                repo=repo,
                filename=filename,
                recover_node_type=recover_node_encoding,
                recover_node_index=recover_node_index,
                source_node_type=helper_node_encoding,
                source_node_index=helper_node_index,
                overwrite=True
            ).render()


    main()
    ...

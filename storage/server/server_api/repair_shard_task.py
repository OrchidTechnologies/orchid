import asyncio
import os
from asyncio import Task

from encoding.node_recovery_client import NodeRecoveryClient
from server.cluster_file import ClusterFileStatus
from server.server_model import Server
from storage.file_download import FileDownload
from storage.renderable import Renderable
from storage.repository import Repository
from storage.storage_model import NodeType, EncodedFile


# Download the required number of Twin Coded recovery symbols (recover files) from providers in the cluster
# and reconstruct the specified shard.
class RepairShardTask(Renderable):

    def __init__(
            self,
            repo: Repository,
            providers: list[Server],
            file: EncodedFile,
            repair_node_type: int,
            repair_node_index: int,
            dryrun: bool = False,
            overwrite: bool = False,
            cleanup: bool = True,
    ):
        self.repo = repo
        self.providers = providers
        self.file = file
        self.filename = file.name
        self.repair_node_type: NodeType = file.type0 if repair_node_type == 0 else file.type1
        self.repair_node_index: int = repair_node_index
        self.dryrun = dryrun
        self.overwrite = overwrite
        self.cleanup = cleanup

    def render(self):
        print(
            f"Rendering: {self.filename} {self.repair_node_type} {self.repair_node_index} {self.dryrun} "
            f"{self.overwrite}")
        self.repair_node_type.assert_reed_solomon()

        # Is this task already complete?
        if self.repo.shard_exists(self.filename, self.repair_node_type.type, self.repair_node_index):
            print(f"Shard already exists: {self.filename} {self.repair_node_type} {self.repair_node_index}")
            if not self.overwrite:
                return

        # What recovery files do we already have?
        existing_recover_files, sufficient = self.check_existing_recovery_files()
        if sufficient:
            print(f"Quorum of recovery files exist: {self.filename} {self.repair_node_type} {self.repair_node_index}")
            return self.complete_repair(existing_recover_files)

        # We need more distinct recovery files.
        need_count = self.repair_node_type.k - len(existing_recover_files)
        print(f"Need {need_count} additional distinct recovery files.")

        # What shards are available in the cluster for the file?
        cluster_file: ClusterFileStatus = asyncio.run(
            ClusterFileStatus(self.providers, self.file).fetch())

        # Recovery shards are of the opposite node type to the one we are repairing.
        source_shard_type: int = self.repair_node_type.alt_type
        shards0_available: dict[int, list[Server]]
        shards1_available: dict[int, list[Server]]
        shards0_available, shards1_available = cluster_file.shard_availability_map()

        # If the complete shard exists in the cluster just fetch it rather the reconstruct it.
        # (Look for the exact shard we would otherwise be repairing)
        repair_type_shards_available = shards0_available if self.repair_node_type.type == 0 else shards1_available
        if self.repair_node_index in repair_type_shards_available:
            print(f"Complete shard exists in cluster: {self.filename} {self.repair_node_type} {self.repair_node_index}")
            print(f"Fetch shard directly instead of repairing.")
            # TODO
            return

        # We need to repair.  Are there enough new shards of the correct type available?
        source_shards_available: set[int] = set(shards0_available if source_shard_type == 0 else shards1_available)
        new_source_shards_available: set[int] = source_shards_available - set(existing_recover_files.keys())
        if len(new_source_shards_available) < need_count:
            print(f"Only {len(new_source_shards_available)} aditional shards available.")
            print(f"Fewer than required: {need_count} additional distinct recovery files.")
            return

        # Select the source shards to use
        selected_shards: list[int] = list(new_source_shards_available)[:need_count]

        # Find servers with those shards
        shard_map0, shard_map1 = cluster_file.shard_availability_map()
        shard_map: dict[int, list[Server]] = shard_map0 if self.repair_node_type.type == 0 else shard_map1

        # Map the selected shards to the first available server
        selected_shard_map: dict[int, Server] = {index: shard_map[index][0] for index in selected_shards}

        # Create a new asyncio event loop for the current thread
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        # Start a recovery file request task for each selected shard
        task_map: dict[Server, Task] = {}
        print(f"Downloading shards: {len(selected_shards)}")
        for index, server in selected_shard_map.items():
            task: Task = loop.create_task(
                FileDownload(self.repo).request_recovery_file(
                    filename=self.filename,
                    provider=server,
                    recover_node_type=self.repair_node_type.type,
                    recover_node_index=self.repair_node_index,
                    source_node_index=index,
                    overwrite=self.overwrite,
                    progress_callback=None
                )
            )
            task_map[server] = task

        # Wait for the tasks to complete
        # Run the tasks and wait for them to complete
        tasks = list(task_map.values())
        loop.run_until_complete(asyncio.gather(*tasks))
        loop.close()

        # Check again to see if we are complete.
        existing_recover_files, sufficient = self.check_existing_recovery_files()
        if not sufficient:
            raise Exception(f"Download Error: still insufficient recovery files: {self.filename}")
        else:
            print(f"Download of recovery files complete.")
            self.complete_repair(existing_recover_files)

        # The recovery file tasks return the bytes downloaded
        results = [task.result() for task in tasks]
        total_bytes = sum(results)
        print(f"Total bytes downloaded: {total_bytes}.")

        return f"Shard repair complete. Total bytes transferred: {total_bytes}."

    # Check if we currently have enough recovery files to reconstruct the desired
    # shard type and index.
    # Return the recovery files map and a boolean indicating if they are sufficient.
    def check_existing_recovery_files(self) -> tuple[dict[int, str], bool]:
        # What recovery files do we already have?
        existing_recover_files: dict[int, str] = self.repo.list_recovery_files(
            self.filename, self.repair_node_type.type, self.repair_node_index)

        # Sanity check that no individual recovery file index exceeds n
        for index in existing_recover_files.keys():
            assert index < self.repair_node_type.n

        # Are they sufficient to reconstruct the shard?
        sufficient: bool = len(existing_recover_files) >= self.repair_node_type.k
        return existing_recover_files, sufficient

    # When a quorum of recovery files exist for a shard then we can reconstruct the shard.
    def complete_repair(self, existing_recover_files: dict[int, str]):
        print(f"Finalize repair: {self.filename} {self.repair_node_type} {self.repair_node_index}")

        # sanity check that the recovery files are all distinct
        assert len(existing_recover_files) == len(set(existing_recover_files.values()))
        # invert the recovery files map
        recover_files_map = {v: k for k, v in existing_recover_files.items()}

        output_path = self.repo.shard_path(
            filename=self.filename,
            node_type=self.repair_node_type.type,
            node_index=self.repair_node_index,
            expected=False
        )
        NodeRecoveryClient(
            recovery_source_node_type=self.repair_node_type,
            file_map=recover_files_map,
            output_path=output_path,
            overwrite=self.overwrite,
        ).recover_node()

        # get the size of the file
        file_size = os.path.getsize(output_path)
        print(f"Repair complete: {self.filename} {self.repair_node_type} {self.repair_node_index}")
        print(f"Recovered shard size: {file_size} bytes.")

        # remove the recovery files
        if self.cleanup:
            for path in existing_recover_files.values():
                os.remove(path)
        ...

    def __hash__(self):
        return hash((self.filename, self.repair_node_type, self.repair_node_index))

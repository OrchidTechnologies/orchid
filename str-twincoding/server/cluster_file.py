from collections import defaultdict
from typing import Optional
from icecream import ic

from server.server_file import ServerFilesStatus
from server.server_model import Server
import asyncio
from aiohttp import ClientSession

from storage.repository import Repository
from storage.storage_model import EncodedFileStatus, EncodedFile
from storage.util import file_availability_ratio


# Fetch the status of a file or all visible files from a cluster of provider servers.
#
class ClusterFileStatus:
    def __init__(self,
                 servers: list[Server],
                 file: Optional[EncodedFile] = None,
                 timeout: int = 30,
                 simulate_latency: int = 0,
                 debug: bool = False
                 ):
        self.servers = servers
        self.file = file
        self.timeout = timeout
        self.simulate_latency = simulate_latency
        self.debug = debug

        # Map of server status
        self.server_status_map: dict[Server, ServerFilesStatus] = {}
        ...

    @property
    # Map of server to list of file status
    def server_files_status_map(self) -> dict[Server, list[EncodedFileStatus]]:
        return {server: self.server_status_map[server].files_status for server in self.server_status_map}

    @property
    # A map of file to server file status. (An inverted version of server_file_status_map)
    def file_server_file_status_map(self) -> dict[EncodedFile, dict[Server, EncodedFileStatus | None]]:
        return self.invert_server_files_status_map(self.server_files_status_map)

    # Map of server to an individual file status. (This method narrows the
    # server_files_status_map to the specified file.)
    def server_file_status_map(self, file: EncodedFile) -> dict[Server, EncodedFileStatus | None]:
        map: dict[Server, EncodedFileStatus | None] = {}
        for server in self.server_files_status_map:
            for status in self.server_files_status_map[server] or []:
                if status.file == file:
                    map[server] = status
        return map

    async def fetch(self):
        async with ClientSession() as session:
            tasks = [ServerFilesStatus(server, self.file, timeout=self.timeout)
                     .fetch(session) for server in self.servers]
            # Run all the tasks concurrently and wait for their results
            statuses: Optional[list[ServerFilesStatus]] = await asyncio.gather(*tasks)
            self.server_status_map = {status.server: status for status in statuses}
            # self.server_files_status_map = {status.server: status.files_status for status in statuses}
            return self

    # Find the file status for the specified server and file.
    def server_file_status_for(self, server: Server, file: Optional[EncodedFile] = None) \
            -> EncodedFileStatus:
        if file and self.file and file != self.file:
            raise Exception("File mismatch.")
        file = file or self.file
        if not file:
            raise Exception("File must be specified.")
        files: list[EncodedFileStatus] | None = self.server_files_status_map.get(server)
        return [status for status in files if status.file == file][0]

    # Determine the availability of the specified file across the cluster of servers
    # If file is not specified, use the file specified in the constructor.
    # Returns a tuple of (availability ratio, list of distinct shards0, list of distinct shards1)
    # TODO: Change this return sets
    def cluster_availability(self, file: Optional[EncodedFile] = None) \
            -> (float, list[int], list[int]):
        if file and self.file and file != self.file:
            raise Exception("File mismatch.")
        file = file or self.file
        if not file:
            raise Exception("File must be specified.")

        # Get the inverted server file status map and locate all available shards for the file.
        server_map: dict[Server, EncodedFileStatus | None] = self.file_server_file_status_map.get(file) or dict()
        return self.cluster_availability_for(file, server_map)

    # Determine the availability of a file across a cluster of servers
    # `server_map` is a map of server to file status for the specified file.
    # Returns a tuple of (availability ratio, list of distinct shards0, list of distinct shards1)
    # TODO: Change this return sets
    @staticmethod
    def cluster_availability_for(
            file: EncodedFile, server_map: dict[Server, EncodedFileStatus | None]
    ) -> (float, list[int], list[int]):

        # union of shards (set then list)
        distinct_shards0 = list({shard
                                 for server, status in server_map.items() if status.file == file
                                 for shard in status.shards0
                                 })
        distinct_shards1 = list({shard
                                 for server, status in server_map.items() if status.file == file
                                 for shard in status.shards1
                                 })
        return (file_availability_ratio(file.k0, file.k1, len(distinct_shards0), len(distinct_shards1)),
                distinct_shards0, distinct_shards1)

    # Get a map of shards to list of servers that have the shard for the specified file.
    # If file is not specified, use the file specified in the constructor.
    # Returns a tuple of (shard0 availability map, shard1 availability map)
    def shard_availability_map(
            self, file: Optional[EncodedFile] = None
    ) -> (dict[int, list[Server]], dict[int, list[Server]]):
        if file and self.file and file != self.file:
            raise Exception("File mismatch.")
        file = file or self.file
        if not file:
            raise Exception("File must be specified.")

        # Get the inverted server file status map and locate all available shards for the file.
        server_map: dict[Server, EncodedFileStatus | None] = self.file_server_file_status_map.get(file) or dict()
        return self.shard_availability_map_for(file, server_map)

    # Get a map of shards to list of servers that have the shard for the specified file.
    # Returns a tuple of (shard0 availability map, shard1 availability map)
    @staticmethod
    def shard_availability_map_for(
            file: EncodedFile, server_map: dict[Server, EncodedFileStatus | None]
    ) -> (dict[int, list[Server]], dict[int, list[Server]]):

        # defaultdicts for shard index to list of servers
        shard_server_map0 = defaultdict(list)
        shard_server_map1 = defaultdict(list)

        for server, status in server_map.items():
            if status and status.file == file:
                for shard in status.shards0:
                    shard_server_map0[shard].append(server)
                for shard in status.shards1:
                    shard_server_map1[shard].append(server)

        return shard_server_map0, shard_server_map1

    # Determine which shards are missing from the cluster based on the specified local file status.
    def missing_shards(self, local_file_status: EncodedFileStatus) -> (set[int], set[int]):
        _, distinct_shards0, distinct_shards1 = self.cluster_availability(local_file_status.file)
        shards0_to_upload = set(local_file_status.shards0) - set(distinct_shards0)
        shards1_to_upload = set(local_file_status.shards1) - set(distinct_shards1)
        return shards0_to_upload, shards1_to_upload

    # Transform the map of server to file status into a map of the file's server availability
    # (in the form of a map of server to file status).
    @staticmethod
    def invert_server_files_status_map(
            server_file_status_map: dict[Server, list[EncodedFileStatus]]
    ) -> dict[EncodedFile, dict[Server, EncodedFileStatus | None]]:

        # Set of distinct files across all servers results
        distinct_files: set[EncodedFile] = {
            file_status.file
            for server in server_file_status_map
            for file_status in server_file_status_map[server] or []}

        def find_servers_with_file(file: EncodedFile) -> list[Server]:
            return [server for server in server_file_status_map if
                    file in [status.file for status in server_file_status_map[server] or []]]

        def find_file_status_in_server_list(file: EncodedFile, server: Server) -> Optional[EncodedFileStatus]:
            try:
                return [status for status in server_file_status_map[server] if status.file == file][0]
            except IndexError:
                return None

        # Invert the server data to a per-file map: {file: {server: file_status}}
        file_status_map: dict[EncodedFile, dict[Server, EncodedFileStatus | None]] = {file: {
            server: find_file_status_in_server_list(file, server)
            for server in find_servers_with_file(file)
        }
            for file in distinct_files
        }
        return file_status_map


# main
if __name__ == '__main__':

    async def main2():
        # filename: str = 'file_1KB.dat'
        filename: str = 'foo_file.dat'
        file: EncodedFile = Repository.default().file(filename)

        servers = [Server(url='http://localhost:8080')]
        cluster_status: ClusterFileStatus = await ClusterFileStatus(servers, file, debug=True).fetch()
        for server, files_list in cluster_status.server_files_status_map.items():
            ic(server, files_list)
        ic(cluster_status.cluster_availability())


    asyncio.run(main2())
    ...

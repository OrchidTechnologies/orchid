import asyncio
from typing import List, Optional

import aiohttp
from aiohttp import FormData, ClientResponse

from commitments.kzg_commitment import FileCommitments, get_kzg_setup
from server.cluster_file import ClusterFileStatus
from server.providers import Providers
from server.server_model import Server, VerifyShardRequest, VerifyShardResponse, Proof
from storage.repository import Repository
from storage.storage_model import EncodedFileStatus, EncodedFile


class FileVerify:
    def __init__(self, repo: Repository, providers: Providers):
        self.repo = repo
        self.providers = providers
        self.setup = get_kzg_setup()

    # Find all available shards for the specified file on the set of providers and issue KZG challenges to them.
    # Update the providers file status with the results of the challenges.
    async def verify(
            self,
            filename: str,
            num_challenges: int = 1,
            providers_list: Optional[List[Server]] = None,
    ):
        # Determine the universe of providers available for this file
        if providers_list is None:
            providers_list = self.providers.servers
        print(f"Providers: {providers_list}")

        # Fetch the config for the local file (required for identity)
        local_file: EncodedFile = self.repo.file(filename)

        # Determine the current availability of shards of the file on the set of providers
        cluster_file: ClusterFileStatus = await ClusterFileStatus(providers_list, local_file).fetch()

        # Get shard availability for each server
        server_file_status_map: dict[Server, EncodedFileStatus | None] = cluster_file.server_file_status_map(local_file)
        # print("server file status map:", server_file_status_map)

        # for each server, verify each shard
        for server in providers_list:
            try:
                print(f"Verifying server {server.url} for file {filename}")
                valid = True
                if server_file_status_map[server]:
                    server_file_status: EncodedFileStatus = server_file_status_map[server]
                    for node_type in [0, 1]:
                        for node_index in server_file_status.shards(node_type):
                            valid &= await self.verify_shard(server, local_file, node_type, node_index, num_challenges)
                else:
                    valid = False

                if valid:
                    print(f"Server {server.url} has valid shards for {filename}")
                    # Update the providers file status with the results of the challenges
                    # TODO
                else:
                    print(f"Server {server.url} has invalid shards for {filename}")
            except Exception as e:
                print(f"Error verifying shards on {server.url}: {e}")
                # traceback.print_exc()

    # Verify the server shard and return True if the shard is valid
    async def verify_shard(self, server: Server, file: EncodedFile,
                           node_type: int, node_index: int, num_challenges: int) -> bool:
        print(f"Verifying shard {file.name}, type: {node_type}, index: {node_index} on {server.url}")

        # Get a random challenge (field element from BLS12-381)
        challenge: bytes = FileCommitments.get_random_challenge()

        # Send the request and wait for the verification response containing the proofs
        verify_shard_response: VerifyShardResponse
        async with aiohttp.ClientSession() as session:
            data = FormData()
            request = VerifyShardRequest(
                file=file,
                node_type=node_type,
                node_index=node_index,
                challenge=challenge.hex(),
                challenge_count=num_challenges
            )
            data.add_field('request', request.model_dump_json(), content_type='application/json')

            auth = server.auth_token
            headers = {'Authorization': auth} if auth else {}
            url = f'{server.url}/verify_shard'

            timeout: int = 60 * 60
            response: ClientResponse
            async with session.post(url, data=data, headers=headers, timeout=timeout) as response:
                if response.status != 200:
                    print(f"Error requesting verify: {response.status}")
                    return False
                verify_shard_response = VerifyShardResponse.from_json(await response.json())
                # print(f"Received response: {verify_shard_response}")
            ...

        # Validate the returned proofs against the commitments
        challenge_proofs: list[Proof] = verify_shard_response.proofs
        assert len(challenge_proofs) == num_challenges

        # Load the stored commitments for the file (one per blob)
        blob_commitments = self.repo.shard_commits(file.name, node_type, node_index)
        blob_count = blob_commitments.count

        # Determine the indices of the blobs for the challenge (deterministic based on the challenge and desired count)
        challenge_indices: list[int] = FileCommitments.challenge_to_indices(challenge, blob_count, num_challenges)
        challenge_commitments: list[bytes] = blob_commitments.for_indices(challenge_indices)

        valid = FileCommitments.verify_proofs(challenge, challenge_commitments, challenge_proofs, self.setup)
        return valid


if __name__ == '__main__':
    async def main():
        repo = Repository.default()
        filename = repo.list()[0]
        servers = [
            Server(url='http://localhost:5001'),
            # Server(url='http://localhost:5002'),
            # Server(url='http://localhost:5001'),
        ]
        num_challenges = 1
        await FileVerify(repo, Providers(servers)).verify(filename, num_challenges, servers)


    asyncio.run(main())

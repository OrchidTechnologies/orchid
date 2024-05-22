import asyncio

import aiohttp
from aiohttp import FormData, ClientResponse

from server.providers import Providers
from server.server_model import Server, RepairShardRequest
from storage.repository import Repository


class FileRequest:
    repo: Repository | None

    def __init__(self, repo: Repository):
        self.repo = repo

    async def request_delete(
            self,
            filename: str,
            provider: Server,
            node_type: int,
            node_index: int,
    ):
        config_file_path: str = self.repo.file_config_path(filename, expected=True)

        async with aiohttp.ClientSession() as session:
            data = FormData()
            data.add_field('config', open(config_file_path, 'rb'), filename='config', content_type='application/json')
            data.add_field('node_type', str(node_type))
            data.add_field('node_index', str(node_index))
            auth = provider.auth_token
            headers = {'Authorization': auth} if auth else {}
            url = f'{provider.url}/delete_shard'

            timeout: int = 60 * 60
            response: ClientResponse
            async with session.post(url, data=data, headers=headers, timeout=timeout) as response:
                if response.status != 200:
                    print(f"Error deleting shard: {response.status}")
                    return
        ...

    async def request_repair(
            self,
            filename: str,
            to_provider: Server,
            from_providers: list[Server],
            node_type: int,
            node_index: int,
            dryrun: bool = False,
            overwrite: bool = False
    ):
        ...
        file = self.repo.file(filename)
        async with aiohttp.ClientSession() as session:
            data = FormData()
            request = RepairShardRequest(
                file=file,
                repair_node_type=node_type,
                repair_node_index=node_index,
                providers=from_providers,
                dryrun=dryrun,
                overwrite=overwrite
            )
            data.add_field('request', request.model_dump_json(), content_type='application/json')

            auth = to_provider.auth_token
            headers = {'Authorization': auth} if auth else {}
            url = f'{to_provider.url}/repair'

            timeout: int = 60 * 60
            response: ClientResponse
            async with session.post(url, data=data, headers=headers, timeout=timeout) as response:
                if response.status != 200:
                    print(f"Error requesting repair: {response.status}")
                    return
                message = await response.json()
                return message
        ...


# main
if __name__ == '__main__':
    async def main():
        repo = Repository.default()
        file0 = repo.list()[0]

        url = 'http://localhost:8080'
        provider = Providers.default().resolve_provider(url)

        await FileRequest(repo).request_delete(file0, provider, 0, 0)
        ...


    asyncio.run(main())
...

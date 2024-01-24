import asyncio
import os
import random
from typing import Callable

import aiohttp
from aiohttp import FormData, ClientResponse, ServerDisconnectedError
from icecream import ic

from server.providers import Providers
from server.server_model import Server
from storage.repository import Repository
from storage.storage_model import EncodedFile


class FileDownload:
    def __init__(self, repo: Repository):
        self.repo = repo

    async def request_recovery_file(
            self,
            filename: str,
            provider: Server,
            recover_node_type: int,
            recover_node_index: int,
            source_node_index: int,
            overwrite: bool = False,
            progress_callback: Callable[[int, int], None] = None,
    ):
        file_config: EncodedFile = self.repo.file(filename)
        if not file_config:
            print(f"File not found in repository: {filename}")
            return
        print(f"Request recovery file for: {file_config} from provider {provider}")

        config_file_path: str = self.repo.file_config_path(filename)

        async with aiohttp.ClientSession() as session:
            data = FormData()
            data.add_field('config', open(config_file_path, 'rb'), filename='config', content_type='application/json')

            data.add_field('recover_node_type', str(recover_node_type))
            data.add_field('recover_node_index', str(recover_node_index))
            data.add_field('source_node_index', str(source_node_index))

            auth = provider.auth_token
            headers = {'Authorization': auth} if auth else {}
            url = f'{provider.url}/recovery_source'

            output_file_path: str = self.repo.recovery_file_path(
                filename, recover_node_type, recover_node_index, source_node_index,
                expected=False)
            if not overwrite and os.path.exists(output_file_path):
                print(f"Recovery file already exists: {output_file_path}")
                return

            # TODO: demo
            demo = False  # slow down the progress to show the UI
            demo_chunk_size = 16
            demo_sleep_random = 0.5

            try:
                timeout: int = 60 * 60 * 24 * 7
                response: ClientResponse
                async with session.post(url, data=data, headers=headers, timeout=timeout) as response:
                    if response.status != 200:
                        print(f"Error requesting recovery file: {response.status}")
                        return

                    # content length
                    content_length = None
                    if 'Content-Length' in response.headers:
                        content_length = int(response.headers['Content-Length'])

                    with open(output_file_path, 'wb') as fd:
                        chunk_size = demo_chunk_size if demo else 1024 * 1024
                        async for chunk in response.content.iter_chunked(chunk_size):
                            fd.write(chunk)
                            if progress_callback:
                                progress_callback(len(chunk), content_length)
                            if demo:
                                sleep = random.random() * demo_sleep_random
                                await asyncio.sleep(sleep)

                    return content_length

            except ServerDisconnectedError:
                print(
                    f"Server disconnected requesting recovery file: {filename} {recover_node_type} "
                    f"{recover_node_index}")
                return
            except asyncio.TimeoutError:
                print(f"Timeout requesting recovery file: {filename} {recover_node_type} {recover_node_index}")
                return
        ...


# main
if __name__ == '__main__':
    async def test_request_recovery_file():
        repo = Repository.default()
        file0 = repo.list()[0]

        url = 'http://localhost:8080'
        provider = Providers.default().resolve_provider(url)

        await FileDownload(repo).request_recovery_file(
            filename=file0,
            provider=provider,
            recover_node_type=0,
            recover_node_index=0,
            source_node_index=3,
            overwrite=True,
            progress_callback=lambda progress, total: ic(progress, total)
        )
        ...


    asyncio.run(test_request_recovery_file())
...

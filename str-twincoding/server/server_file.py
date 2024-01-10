import asyncio
import json
from json import JSONDecodeError
from typing import List, Optional

from aiohttp import ClientSession, ClientConnectorError
from icecream import ic

from server.server_model import Server, ServerStatus
from storage.repository import Repository
from storage.storage_model import EncodedFileStatus, EncodedFile


# Fetch the status of a file or all visible files from a provider server endpoint.
class ServerFilesStatus:
    server_status: ServerStatus = ServerStatus.UNKNOWN
    file_status: Optional[EncodedFileStatus] = None  # available when a single file is specified
    files_status: Optional[List[EncodedFileStatus]] = None  # available when no file is specified
    authorization: str = None

    def __init__(self,
                 server: Server,
                 file: Optional[EncodedFile] = None,
                 timeout: int = 30,
                 simulate_latency: int = 0,
                 debug: bool = False
                 ):
        self.server = server
        self.file = file
        self.timeout = timeout
        self.simulate_latency = simulate_latency
        self.debug = debug
        ...

    async def fetch(self, session: Optional[ClientSession] = None, after_seconds: int = 0):
        if session:
            await self._fetch(self.server, session, after_seconds)
        else:
            async with ClientSession(conn_timeout=self.timeout) as session:
                await self._fetch(self.server, session, after_seconds)
        return self

    async def _fetch(self, server: Server, session: ClientSession, after_seconds: int = 0):
        # The url with optional filename query.
        url = f'{server.url}/list'
        if self.file:
            url += f'?file={self.file.name}'
        self.log(f"\nFetching {(server.name or '') + ' ' + server.url}")

        if after_seconds > 0:
            await asyncio.sleep(after_seconds)

        if self.simulate_latency > 0:
            import random
            await asyncio.sleep(random.random() * self.simulate_latency)

        try:
            async with session.post(url, data={'auth_key': server.auth_token}) as response:
                # server status
                if response.status != 200:
                    self.server_status = ServerStatus.UNKNOWN
                    self.log("error: ", response.status, response.reason)
                    return
                else:
                    self.server_status = ServerStatus.OK

                # file status
                text = await response.text()
                # self.log("text: ", text)
                from_json = json.loads(text)
                status_list: list[EncodedFileStatus] = [EncodedFileStatus(**file) for file in from_json]
                self.files_status = status_list
                # Find the status for the requested file, if any.
                status = next((status for status in status_list if status.file == self.file), None)
                # self.log("status: ", status)
                self.file_status = status
        except JSONDecodeError as e:
            self.log(f"JSONDecodeError: {e}")
            self.server_status = ServerStatus.UNKNOWN
        except ClientConnectorError as e:
            self.log(f"ClientConnectorError: {e}")
            self.server_status = ServerStatus.UNREACHABLE
        except ConnectionError as e:
            self.log(f"ConnectionError: {e}")
            self.server_status = ServerStatus.UNREACHABLE
        except asyncio.TimeoutError:
            self.log("Timeout.")
            self.server_status = ServerStatus.UNREACHABLE
        except Exception as e:
            self.log(f"Exception: {e}, {type(e)}")
            self.server_status = ServerStatus.UNKNOWN

    def update(self):
        ...

    def log(self, *args):
        if self.debug:
            print(*args)


# main
if __name__ == '__main__':
    # filename: str = 'file_1KB.dat'
    filename: str = 'foo_file.dat'
    file: EncodedFile = Repository.default().file(filename)


    async def main1():
        server = Server(url='http://localhost:8080')
        # status = await ServerFilesStatus(server, file, debug=True).fetch()
        # ic(status.file_status)
        status = await ServerFilesStatus(server, debug=True).fetch()
        ic(status.server_status)
        ic(status.files_status)


    asyncio.run(main1())
    ...

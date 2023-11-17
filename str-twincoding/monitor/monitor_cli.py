import asyncio
import json
import os
import random
from asyncio import Task
from datetime import datetime
from typing import Dict, Optional

from aiohttp import ClientSession, ClientTimeout
from icecream import ic
from rich.box import *
from rich.console import Console
from rich.layout import Layout
from rich.live import Live
from rich.table import Table

from monitor.file_table import FileStatusView, FileTable
from monitor.monitor_config import ServerStatus, MonitorConfig
from server.server_config import Server, ServerFileStatus, ServerFile
from server_table import ServerStatusView, ServerTable
from storage.util import summarize_ranges


class Monitor:
    def __init__(self,
                 providers_config: Optional[str] = None,
                 providers: Optional[List[Server]] = None,
                 polling_period: int = 0,
                 timeout: int = 30,
                 simulate_latency: int = 0,
                 debug: bool = False
                 ):

        # config or servers
        assert providers_config or providers
        assert not (providers_config and providers)
        self.providers_config_last_update: Optional[datetime] = None
        self.providers_config = providers_config
        self.servers = providers

        self.polling_period = polling_period
        self.timeout = timeout
        self.server_status: Dict[Server, ServerStatus] = {}
        self.file_status: Dict[Server, List[ServerFileStatus]] = {}
        self.simulate_latency = simulate_latency
        self.task_map: Dict[Server, Task] = {}
        self.debug = debug

    async def fetch(self, session: ClientSession, server: Server, after_seconds: int = 0):
        url = f'{server.url}/list'
        self.log(f"\nFetching {(server.name or '') + server.url}")

        if after_seconds > 0:
            await asyncio.sleep(after_seconds)

        if self.simulate_latency > 0:
            await asyncio.sleep(random.random() * self.simulate_latency)

        def clear_status():
            self.server_status[server] = ServerStatus.UNKNOWN
            self.file_status.pop(server, None)

        try:
            async with session.post(url, data={'auth_key': server.auth_token}) as response:
                # server status
                if response.status != 200:
                    clear_status()
                    self.log("error: ", response.status, response.reason)
                    return
                self.server_status[server] = ServerStatus.OK
                self.log("response OK")

                # file status
                text = await response.text()
                # self.log("text: ", text)
                from_json = json.loads(text)
                status = [ServerFileStatus(**file) for file in from_json]
                self.log("status: ", status)
                self.file_status[server] = status
        except Exception as e:
            self.log(f"Exception: {e}")
            clear_status()

    # Update the list of servers from the server config if required
    def update_server_config(self):
        if not self.providers_config:
            return self.servers
        config_current_mod = datetime.fromtimestamp(os.path.getmtime(self.providers_config))
        if not self.servers or self.providers_config_last_update is None or config_current_mod > self.providers_config_last_update:
            config = MonitorConfig.load(self.providers_config)
            self.servers = config.providers
            self.providers_config_last_update = config_current_mod

    # ensure that all servers are being polled
    def update_task_map(self, session: ClientSession):
        for server in self.servers:
            # TODO: We don't currently clear tasks for servers that are removed from the config
            if server not in self.task_map:
                task: Task = asyncio.create_task(self.fetch(session, server))
                self.task_map[server] = task

    # Reschedule completed tasks
    def schedule_tasks(self, session: ClientSession, delay: int = 0):
        for server, task in self.task_map.items():
            if task.done():
                self.task_map[server] = asyncio.create_task(
                    self.fetch(session, server, after_seconds=delay))

    async def poll_servers_loop(self):
        async with ClientSession(timeout=ClientTimeout(total=self.timeout)) as session:
            if self.polling_period > 0:
                while True:
                    self.update_server_config()
                    self.update_task_map(session)
                    period = self.polling_period if self.server_status else 0
                    self.schedule_tasks(session, period)
                    await asyncio.sleep(1)
            else:
                self.update_server_config()
                self.update_task_map(session)
                self.schedule_tasks(session)
                await asyncio.gather(*self.task_map.values())

    # Generate the table of known providers
    def get_provider_table(self) -> Table:
        servers = [
            ServerStatusView(name=server.url, status=self.server_status[server])
            for server in self.servers if server in self.server_status
        ]
        return ServerTable(servers=servers, hide_cols={'shards', 'last_validated'}).get()

    # Generate a table for each file that we found
    def get_file_tables(self) -> Table:
        self.log("server status:", self.server_status)
        self.log("file status:", self.file_status)

        # Map of distinct files across all servers results
        distinct_files = {file_status.file: file_status
                          for server in self.file_status for file_status in self.file_status[server]}

        def find_servers_with_file(file: ServerFile) -> List[Server]:
            return [server for server in self.file_status if
                    file in [status.file for status in self.file_status[server]]]

        def find_file_status_in_server_list(file: ServerFile, server: Server) -> Optional[ServerFileStatus]:
            try:
                return [status for status in self.file_status[server] if status.file == file][0]
            except IndexError:
                return None

        # Invert the server data to a per-file map: {file: {server: file_status}}
        file_status_map = {file:
            {
                server: find_file_status_in_server_list(file, server)
                for server in find_servers_with_file(file)
            }
            for file in distinct_files
        }
        self.log("file status map:", file_status_map)

        file_tables = [self.create_file_table(file, file_status_map[file]) for file in distinct_files]

        # Combine the file tables into a single table
        combined_file_table = Table(expand=True, show_header=False, show_lines=False, show_edge=False, pad_edge=False)
        combined_file_table.add_column("main", justify="left")
        for file_table in file_tables:
            combined_file_table.add_row(file_table)
        return combined_file_table

    # Create a file table for a single file
    def create_file_table(self, file: ServerFile, server_map: Dict[Server, ServerFileStatus]):

        # calculate availability
        distinct_shards0 = list({shard for server in server_map for shard in server_map[server].shards0})
        distinct_shards1 = list({shard for server in server_map for shard in server_map[server].shards1})
        count0 = len(distinct_shards0)
        availability0 = count0 / file.k0 if count0 >= file.k0 else 0
        count1 = len(distinct_shards1)
        availability1 = count1 / file.k1 if count1 >= file.k1 else 0
        availability = availability0 + availability1

        server_views = []
        for server in server_map:
            status: ServerFileStatus = server_map[server]
            shards0 = f"type0: {summarize_ranges(status.shards0)}"
            shards1 = f"type1: {summarize_ranges(status.shards1)}"
            if status.shards0 and status.shards1:
                shards = f"{shards0} | {shards1}"
            else:
                shards = shards0 if status.shards0 else shards1

            view = ServerStatusView(
                name=server.url,
                status=self.server_status[server],
                shards=shards,
            )
            server_views.append(view)

        file_view = FileStatusView(name=file.name,
                                   availability=availability,
                                   encoding=file.encoding_str(),
                                   auth=0.0, payments=0.0)
        return FileTable(file=file_view, servers=server_views).get()

    async def draw_screen_loop(self):
        if self.debug:
            return

        console = Console(record=True, force_terminal=True)

        def create_layout():
            _layout = Layout()
            height = 3 + len(self.servers) * 2  # header + server rows with lines
            _layout.split(
                Layout(name="servers", size=height),
                Layout(name="files")
            )
            return _layout

        def update():
            layout['servers'].update(self.get_provider_table())
            layout['files'].update(self.get_file_tables())

        if self.live:
            layout = create_layout()
            layout_server_len = len(self.servers)
            update()
            with Live(layout, console=console) as live:
                while True:
                    if len(self.servers) != layout_server_len:
                        layout = create_layout()
                        live.update(layout)
                        layout_server_len = len(self.servers)
                    update()
                    await asyncio.sleep(1 if self.server_status else 0.1)
        else:
            console.print(self.get_provider_table())
            console.print(self.get_file_tables())

    async def main(self):
        if self.live:
            await asyncio.gather(
                asyncio.create_task(self.poll_servers_loop()),
                asyncio.create_task(self.draw_screen_loop())
            )
        else:
            await self.poll_servers_loop()
            await self.draw_screen_loop()

    def run(self):
        asyncio.run(self.main())

    @property
    def live(self):
        return self.polling_period > 0

    def log(self, *args):
        if self.debug:
            print(*args)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Process command line arguments.')
    parser.add_argument('--providers', type=str, help='Providers file path')
    parser.add_argument('--debug', action='store_true', help='Show debug')
    parser.add_argument('--update', type=int, help='Update view with polling period seconds')
    args = parser.parse_args()

    providers = args.providers
    if not args.providers:
        STRHOME = os.environ.get('STRHOME') or '.'
        providers = os.path.join(STRHOME, 'providers.jsonc')
        print(f"Using default providers file: {providers}")

    monitor = Monitor(
        providers_config=providers,
        polling_period=args.update or 0,
        debug=args.debug or False,
        simulate_latency=0, timeout=3,
        # servers=[
        #     Server(name="1", url='http://localhost:8080'),
        #     Server(name="2", url='http://localhost:8080'),
        #     Server(name="3", url='http://localhost:8080'),
        # ]
    )
    monitor.run()

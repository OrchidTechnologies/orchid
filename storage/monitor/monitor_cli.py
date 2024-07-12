import os
import asyncio
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
from server.cluster_file import ClusterFileStatus
from server.server_file import ServerFilesStatus
from server.providers import Providers
from server.server_model import Server, ServerStatus
from server_table import ServerStatusView, ServerTable
from storage.storage_model import EncodedFile, EncodedFileStatus
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

        # providers
        assert not (providers_config and providers)
        if providers_config:
            assert os.path.exists(providers_config)
        if not providers_config and not providers:
            providers_config = Providers.default_providers_config
            print(f"Using default providers file: {providers_config}")
        self.providers_config_last_update: Optional[datetime] = None
        self.providers_config = providers_config
        self.provider_servers: Optional[List[Server]] = providers

        self.polling_period = polling_period
        self.timeout = timeout
        self.server_status: Dict[Server, ServerStatus] = {}
        self.server_files_status_map: Dict[Server, List[EncodedFileStatus]] = {}
        self.simulate_latency = simulate_latency
        self.task_map: Dict[Server, Task] = {}
        self.debug = debug

    async def fetch(self, session: ClientSession, server: Server, after_seconds: int = 0):
        def clear_status():
            self.server_status[server] = ServerStatus.UNKNOWN
            self.server_files_status_map.pop(server, None)

        try:
            server_file_status = await (ServerFilesStatus(
                server=server, timeout=self.timeout, simulate_latency=self.simulate_latency, debug=self.debug)
                                        .fetch(session, after_seconds=after_seconds))
            if server_file_status.server_status != ServerStatus.OK:
                clear_status()
                self.log("error: ", server_file_status)
                return

            self.server_status[server] = server_file_status.server_status
            self.server_files_status_map[server] = server_file_status.files_status
        except Exception as e:
            self.log(f"Exception: {e}")
            clear_status()

    # Update the list of providers from the provider config if required
    def update_providers_list(self):
        if not self.providers_config:
            return self.provider_servers
        config_current_mod = datetime.fromtimestamp(os.path.getmtime(self.providers_config))
        if (not self.provider_servers or self.providers_config_last_update is None or config_current_mod >
                self.providers_config_last_update):
            self.provider_servers = Providers.get(self.providers_config).servers
            self.providers_config_last_update = config_current_mod

    # Update the fetch tasks the providers. Tasks are initiallly started here and
    # placed into a map by server. Later they are rescheduled after completion by the
    # reschedul_fetch_tasks method.
    def update_fetch_tasks(self, session: ClientSession):
        for server in self.provider_servers:
            # TODO: We don't currently clear tasks for servers that are removed from the config
            if server not in self.task_map:
                task: Task = asyncio.create_task(self.fetch(session, server))
                self.task_map[server] = task

    # Reschedule completed tasks by recreating them
    def reschedule_fetch_tasks(self, session: ClientSession, delay: int = 0):
        for server, task in self.task_map.items():
            if task.done():
                self.task_map[server] = asyncio.create_task(
                    self.fetch(session, server, after_seconds=delay))

    # asyncio task to poll servers
    async def poll_servers_loop(self):
        async with ClientSession(timeout=ClientTimeout(total=self.timeout)) as session:
            if self.polling_period > 0:
                while True:
                    self.update_providers_list()
                    self.update_fetch_tasks(session)
                    period = self.polling_period if self.server_status else 0
                    self.reschedule_fetch_tasks(session, period)
                    await asyncio.sleep(1)
            else:
                self.update_providers_list()
                self.update_fetch_tasks(session)
                self.reschedule_fetch_tasks(session)
                await asyncio.gather(*self.task_map.values())

    # Generate the table of known providers
    def get_provider_table(self) -> Table:
        servers = [
            ServerStatusView(name=server.url, status=self.server_status[server])
            for server in self.provider_servers if server in self.server_status
        ]
        return ServerTable(servers=servers, hide_cols={'shards', 'last_validated'}).get()

    # Generate a table for each file that we found
    def get_file_tables(self) -> Table:
        self.log("server status:", self.server_status)
        self.log("file status:", self.server_files_status_map)

        file_status_map: dict[EncodedFile, dict[Server, EncodedFileStatus | None]] = (
            ClusterFileStatus.invert_server_files_status_map(self.server_files_status_map))
        distinct_files = list(file_status_map.keys())
        self.log("file status map:", file_status_map)

        file_tables = [self.create_file_table(file, file_status_map[file]) for file in distinct_files]

        # Combine the file tables into a single table
        combined_file_table = Table(expand=True, show_header=False, show_lines=False, show_edge=False, pad_edge=False)
        combined_file_table.add_column("main", justify="left")
        for file_table in file_tables:
            combined_file_table.add_row(file_table)
        return combined_file_table

    # Create a file table for a single file
    def create_file_table(self, file: EncodedFile, server_map: Dict[Server, EncodedFileStatus | None]):
        availability, _, _ = ClusterFileStatus.cluster_availability_for(file, server_map)
        server_views = []
        for server in server_map:
            status: EncodedFileStatus = server_map[server]
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
            height = 3 + len(self.provider_servers) * 2  # header + server rows with lines
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
            layout_server_len = len(self.provider_servers)
            update()
            with Live(layout, console=console) as live:
                while True:
                    if len(self.provider_servers) != layout_server_len:
                        layout = create_layout()
                        live.update(layout)
                        layout_server_len = len(self.provider_servers)
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
    parser.add_argument('--providers', type=str, help='Providers config file path')
    parser.add_argument('--debug', action='store_true', help='Show debug')
    parser.add_argument('--update', type=int, help='Update view with polling period seconds')
    args = parser.parse_args()

    providers_config = args.providers
    monitor = Monitor(
        providers_config=providers_config,
        polling_period=args.update or 0,
        debug=args.debug or False,
        simulate_latency=0, timeout=3,
        # providers=[
        #     Server(name="1", url='http://localhost:8080'),
        #     Server(name="2", url='http://localhost:8080'),
        #     Server(name="3", url='http://localhost:8080'),
        # ]
    )
    monitor.run()

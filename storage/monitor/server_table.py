from datetime import datetime
from typing import List, Set

from pydantic import BaseModel
from rich.box import ROUNDED
from rich.console import Console
from rich.table import Table

from server.server_model import ServerStatus


class ServerStatusView(BaseModel):
    name: str
    status: ServerStatus = ServerStatus.UNKNOWN
    stake: float = 0
    auth: float = 0
    payments: float = 0
    shards: str = None
    validated: datetime = None


class ServerTable:
    def __init__(self,
                 servers: List[ServerStatusView] = None,
                 show_edge: bool = True,
                 hide_cols: Set[str] = None
                 ):
        self.servers = servers or []
        self.show_edge = show_edge
        self.hide_cols = hide_cols or {}
        ...

    def get(self):
        # table = Table(expand=True, show_lines=False, title="Known Providers", title_justify="left")
        table = Table(
            expand=True,
            # title="Known Providers" if self.standalone else None,
            show_edge=self.show_edge,
            show_lines=True,
            box=ROUNDED,
        )

        table.add_column("Provider", style="magenta")
        if "status" not in self.hide_cols:
            table.add_column("Status", style="green")
        if "stake" not in self.hide_cols:
            table.add_column("Stake", style="red")
        if "shards" not in self.hide_cols:
            table.add_column("Shards", style="blue")
        if "auth" not in self.hide_cols:
            table.add_column("Auth", style="cyan")
        if "payments" not in self.hide_cols:
            table.add_column("Payments", style="cyan")
        if "last_validated" not in self.hide_cols:
            table.add_column("Last Validated", style="blue")

        # Add rows
        for server in self.servers:
            # progress_meter = Status.create_progress_meter(cpu_usage)
            # table.add_row(
            #     server.name,
            #     server.status.name,
            #     f'{server.stake:.2f}',
            #     f'{server.shards if server.shards else "-"}',
            #     f'{server.auth:.2f}',
            #     f'{server.payments:.2f}',
            #     f'{server.validated.strftime("%Y-%m-%d %H:%M:%S") if server.validated else "-"}'
            # )

            row_data = [server.name]
            if "status" not in self.hide_cols:
                row_data.append(server.status.name)
            if "stake" not in self.hide_cols:
                row_data.append(f'{server.stake:.2f}')
            if "shards" not in self.hide_cols:
                row_data.append(f'{server.shards if server.shards else "-"}')
            if "auth" not in self.hide_cols:
                row_data.append(f'{server.auth:.2f}')
            if "payments" not in self.hide_cols:
                row_data.append(f'{server.payments:.2f}')
            if "last_validated" not in self.hide_cols:
                row_data.append(f'{server.validated.strftime("%Y-%m-%d %H:%M:%S") if server.validated else "-"}')

            table.add_row(*row_data)

        return table

    def output(self):
        Console(record=True, force_terminal=True).print(self.get())


example_servers = [
    ServerStatusView(
        name="server1.example.com",
        status=ServerStatus.OK,
        stake=0.0, auth=0.0, payments=0.0, hosting=0,
        validated=datetime.now()
    ),
    ServerStatusView(
        name="server2.example.com",
        status=ServerStatus.OK,
        stake=0.0, auth=0.0, payments=0.0, hosting=0,
        validated=datetime.now()
    ),
    ServerStatusView(
        name="server3.example.com",
        status=ServerStatus.OK,
        stake=0.0, auth=0.0, payments=0.0, hosting=0,
        validated=datetime.now()
    ),
]

if __name__ == '__main__':
    ServerTable(example_servers).output()

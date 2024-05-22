import time
from pydantic import BaseModel
from rich.box import *
from rich.console import Console
from rich.layout import Layout
from rich.live import Live
from rich.table import Table

from server_table import ServerTable, ServerStatusView, example_servers


class FileStatusView(BaseModel):
    name: str
    availability: float = 0
    encoding: str
    auth: float = 0
    payments: float = 0


class FileTable:
    def __init__(self,
                 file: FileStatusView,
                 servers: List[ServerStatusView] = None,
                 ):
        self.file = file
        self.servers = servers or []
        ...

    @staticmethod
    def header_table():
        # table = Table(expand=True, show_lines=False, show_edge=False, box=SIMPLE_HEAVY)
        table = Table(expand=True, show_lines=False, show_edge=False, box=MINIMAL_HEAVY_HEAD)

        table.add_column("File", style="magenta")
        table.add_column("Availability", style="green")
        table.add_column("Encoding", style="blue")
        table.add_column("Auth", style="cyan")
        table.add_column("Payments", style="cyan")

        return table

    def file_row(self, file: FileStatusView):
        table = self.header_table()
        # table.show_header = False

        # progress_meter = Status.create_progress_meter(cpu_usage)
        table.add_row(
            file.name,
            f'{file.availability:.2f}',
            file.encoding,
            f'{file.auth:.2f}',
            f'{file.payments:.2f}',
        )

        return table

    def get(self):
        # Create the main table with a single column
        main_table = Table(expand=True, show_header=False, box=ROUNDED, show_lines=False)
        main_table.add_column("Main Column", justify="left")

        # file row
        file_row = self.file_row(self.file)
        main_table.add_row(file_row)

        # server row
        main_table.add_row()
        server_row = ServerTable(self.servers, show_edge=False,
                                 hide_cols={'status', 'stake', 'payments'}).get()
        main_table.add_row(server_row)

        return main_table

    def output(self):
        Console(record=True, force_terminal=True).print(self.get())

    def run(self):
        console = Console(record=True, force_terminal=True)
        layout = Layout()
        layout.split(Layout(name="main"))

        def update(): layout['main'].update(self.get())

        update()
        with Live(layout, console=console, refresh_per_second=1) as live:
            # while True:
            for _ in range(3):
                update()
                # await asyncio.sleep(1)
                time.sleep(1)


example_file = FileStatusView(
    name="file1.log",
    availability=0.0,
    encoding="UTF-8",
    auth=0.0,
    payments=0.0,
)

if __name__ == '__main__':
    FileTable(example_file, example_servers).output()
    # FileTable(example_files, example_servers).run()

from rich.box import *
from rich.console import Console
from rich.table import Table

from storage.storage_model import EncodedFileStatus
from storage.util import summarize_ranges


# A table showing local file status
class FileListTable:
    def __init__(self, files: List[EncodedFileStatus]):
        self.files = files
        ...

    def get(self):
        table = Table(expand=True, show_edge=True, show_lines=True, box=ROUNDED)
        table.add_column("File", style="magenta")
        table.add_column("Encoding", style="cyan")
        table.add_column("Availability", style="green")
        table.add_column("Type 0 shards", style="blue")
        table.add_column("Type 1 shards", style="blue")
        for file in self.files:
            table.add_row(
                file.file.name,
                file.file.encoding_str(),
                str(file.local_availability()),
                summarize_ranges(file.shards0),
                summarize_ranges(file.shards1),
            )
        return table

    def output(self):
        Console(record=True, force_terminal=True).print(self.get())


if __name__ == '__main__':
    ...

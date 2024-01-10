from typing import List

from rich.box import ROUNDED
from rich.table import Table
from rich.console import Console


def print_table(
        column_names: List[str],
        row_data: List[tuple],
        colors: List[str] = None,
        title: str = None
):
    colors = colors or ["yellow", "green", "cyan", "blue", "red"] * 2
    # table = Table(expand=True, show_edge=True, show_lines=True, box=ROUNDED)
    table = Table(title=title, show_header=True, box=ROUNDED)
    for column in column_names:
        table.add_column(column, style=colors.pop(0))
    for row in row_data:
        table.add_row(*[str(item) for item in row])
    console = Console()
    console.print(table)


# main
if __name__ == '__main__':
    # Example usage
    column_names = ["Column 1", "Column 2", "Column 3"]
    rows = [
        (1, "Row 1, Column 2", "Row 1, Column 3"),
        (2, "Row 2, Column 2", "Row 2, Column 3"),
        (3, "Row 3, Column 2", "Row 3, Column 3"),
    ]

    print_table(column_names, rows)

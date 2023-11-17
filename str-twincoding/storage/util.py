import argparse
from typing import List
from storage.config import NodeType


def assert_rs(node_type: NodeType):
    assert node_type.encoding == 'reed_solomon', "Only reed solomon encoding is currently supported."


def assert_node_type(node_type: int):
    assert node_type in [0, 1], "node_type must be 0 or 1."


def summarize_ranges(numbers: List[int]) -> str:
    """Summarize a list of integers into a compact range string."""
    if not numbers:
        return ""

    # Start with the first number, and initialize current range
    ranges = []
    start = numbers[0]
    end = numbers[0]

    for n in numbers[1:]:
        if n == end + 1:
            # Continue the range
            end = n
        else:
            # Finish the current range and start a new one
            if start == end:
                ranges.append(str(start))
            else:
                ranges.append(f"{start}-{end}")
            start = end = n

    # Add the last range
    if start == end:
        ranges.append(str(start))
    else:
        ranges.append(f"{start}-{end}")

    return ", ".join(ranges)


# Dump all help for docs for the argparse subparsers as markdown
def dump_docs_md(_, subparsers: argparse._SubParsersAction):
    for name, subparser in subparsers._name_parser_map.items():
        if name == 'docs':
            continue
        print(f"###`{name}`")
        print('```')
        print(subparser.print_help())
        print('```')

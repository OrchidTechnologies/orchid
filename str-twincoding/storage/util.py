import argparse
import os
from typing import List


# Get the storage project home directory or a path relative to it
def get_strhome(path: str = None) -> str:
    STRHOME = os.environ.get('STRHOME') or '.'
    if path:
        return os.path.join(STRHOME, path)
    else:
        return STRHOME


# Calculate a total availability number for a file based on the number of shards available
# Note that This availability can be greater than 1 indicating that more than the required
# number of shards are available. In particular, with Twin Coding a fully available file
# will have an availability of 2 and more generally will have an availability of n0/k0 + n1/k1.
def file_availability_ratio(
        k0: int, k1: int,
        # Count of distinct shards of type 0
        count0: int,
        # Count of distinct shards of type 1
        count1: int,
) -> float:
    availability0 = count0 / k0 if count0 >= k0 else 0
    availability1 = count1 / k1 if count1 >= k1 else 0
    return availability0 + availability1


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


# Return the path to a temp file of random data of the specified size.
# If the file exists it will not be overwritten.
def get_or_create_random_test_file(filename: str, size: int) -> str:
    from storage.repository import Repository
    repo = Repository.default()
    path = repo.tmp_file_path(filename)

    # If the file doesn't exist create it
    if not os.path.exists(path):
        with open(path, "wb") as f:
            f.write(os.urandom(size))

    return path


# main
if __name__ == '__main__':
    ...

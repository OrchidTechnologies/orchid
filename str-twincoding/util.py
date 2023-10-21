import io
import os
from typing import Optional
from config import NodeType


def open_output_file(output_path: str, overwrite: bool) -> Optional[io.BufferedWriter]:
    if not overwrite and os.path.exists(output_path):
        print(f"Output file already exists: {output_path}.")
        return None

    # Make intervening directories if needeed
    directory = os.path.dirname(output_path)
    if directory:
        os.makedirs(directory, exist_ok=True)

    return io.BufferedWriter(open(output_path, 'wb'))


def assert_rs(node_type: NodeType):
    assert node_type.encoding == 'reed_solomon', "Only reed solomon encoding is currently supported."

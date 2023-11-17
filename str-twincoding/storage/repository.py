import os
import re
from collections import OrderedDict
from typing import Any

from storage.config import EncodedFileConfig
from storage.util import *


class Repository:
    @staticmethod
    def default() -> 'Repository':
        STRHOME = os.environ.get('STRHOME') or '.'
        path = os.path.join(STRHOME, 'repository')
        print(f"Using default repository path: {path}")
        return Repository(path=path)

    def __init__(self, path: str, init: bool = True):
        self._path = path
        if init and not os.path.exists(path):
            os.makedirs(os.path.join(self._path, 'tmp'))
        ...

    # Get the path to an encoded file.
    # 'file' must be a simple filename (not a path)
    def file_path(self, file: str, expected: bool = True) -> str:
        assert os.path.basename(file) == file, "file must be a filename only with no path."
        path = os.path.join(self._path, f'{file}.encoded')
        if expected:
            assert os.path.exists(path), f"Encoded file not found: {path}"
        return path

    def file_config(self, file: str) -> EncodedFileConfig:
        path = self.file_path(file)
        return EncodedFileConfig.load(os.path.join(path, 'config.json'))

    # Get the path to a shard of the encoded file by node type and index
    def shard_path(self, file: str, node_type: int, node_index: int, expected: bool = True) -> str:
        assert_node_type(node_type)
        path = f'{self.file_path(file)}/type{node_type}_node{node_index}.dat'
        if expected:
            assert os.path.exists(path), f"Shard not found: {path}"
        return path

    def recovery_file_path(self, file: str,
                           recover_node_type: int, recover_node_index: int,
                           helper_node_index: int, expected: bool = True) -> str:
        assert_node_type(recover_node_type)
        path = (f'{self.file_path(file)}/recover'
                f'_type{recover_node_type}'
                f'_node{recover_node_index}'
                f'_from{helper_node_index}.dat')
        if expected:
            assert os.path.exists(path), f"Recovery file not found: {path}"
        return path

    def tmp_file_path(self, file: str):
        return os.path.join(self._path, 'tmp', f'{file}')

    # Map the files in an encoded file directory.
    # This returns two ordered dicts, one for type 0 files and one for type 1 files, filename -> node index
    def map(self, file: str) -> (dict[str, int], dict[str, int]):
        return Repository.map_files(self.file_path(file))

    # Produce s compact string summarizing the availability of a file.
    def status_str(self, file: str) -> str:
        type0_files, type1_files = self.map(file)
        # config = load_file_config(f'{self.path(file)}/config.json')
        return (f"{file}: Availability: Type 0 shards: {summarize_ranges(list(type0_files.values()))}, "
                f"Type 1 shards: {summarize_ranges(list(type1_files.values()))}")

    # Generate a list of the files in the repository.
    def list(self) -> List[str]:
        encoded = [f for f in os.listdir(self._path) if f.endswith('.encoded')]
        return [f[:-8] for f in encoded]

    @staticmethod
    # Return maps of type 0 and type 1 files, file path -> node index
    def map_files(files_dir: str) -> (dict[str, int], dict[str, int]):
        type0_files: dict[Any, Any]
        type0_files, type1_files = {}, {}
        for filename in os.listdir(files_dir):
            match = re.match(r'type([01])_node(\d+).dat', filename)
            if not match:
                continue
            type_no, index_no = int(match.group(1)), int(match.group(2))
            files = type0_files if type_no == 0 else type1_files
            files[os.path.join(files_dir, filename)] = index_no

        return (OrderedDict(sorted(type0_files.items(), key=lambda x: x[1])),
                OrderedDict(sorted(type1_files.items(), key=lambda x: x[1])))


if __name__ == '__main__':
    repo = Repository('./repository')

    files = repo.list()
    print("Files in repository:")
    for file in files:
        print('  ', repo.status_str(file))

    # print()
    # file = 'file_1KB.dat'
    # print(repo.file_path(file))
    # print(repo.shard_path(file, node_type=0, node_index=0))

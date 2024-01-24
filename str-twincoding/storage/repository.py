import re
from collections import OrderedDict
from typing import Any, Dict
from storage.storage_model import EncodedFile, EncodedFileStatus, assert_node_type
from storage.util import *
from icecream import ic


class Repository:
    @staticmethod
    def default() -> 'Repository':
        path = get_strhome('repository')
        print(f"Using default repository path: {path}")
        return Repository(path=path)

    def __init__(self, path: str, init: bool = True):
        self._path = path
        if init:
            self.ensure_init()
        ...

    def ensure_init(self):
        if not os.path.exists(self.tmp_dir()):
            os.makedirs(self.tmp_dir(), exist_ok=True)

    # Get a repository root for incoming files within this repository.
    def incoming(self) -> 'Repository':
        return Repository(self.repo_path('incoming'), init=False)

    # return a path under the repository root
    def repo_path(self, path: str):
        return os.path.join(self._path, path)

    # Get the path to an encoded file dir by name.
    # `file` must be a simple filename (not a path)
    def file_dir_path(self, filename: str, expected: bool = True) -> str:
        assert os.path.basename(filename) == filename, "file must be a filename only with no path."
        dirname = f'{filename}.encoded'
        path = self.repo_path(dirname)
        if expected:
            assert os.path.exists(path), f"Encoded file not found: {path}"
        return path

    # Get the path to an encoded file config by name.
    def file_config_path(self, filename: str, expected: bool = True) -> str:
        path = self.file_dir_path(filename, expected)
        return os.path.join(path, 'config.json')

    # Save the file config, creating a new repo file dir.
    # If the config already exists, an exception is raised.
    def save_file_config(self, config: EncodedFile):
        # Save the config, creating a new repo file dir.
        file_config_path = self.file_config_path(config.name, expected=False)
        # if it exists
        if os.path.exists(file_config_path):
            raise Exception(f"File config already exists: {file_config_path}")
        config.save_atomic(file_config_path, mkdirs=True)

    # Get the path to a shard of the encoded file by file name, node type and index
    def shard_path(self, filename: str, node_type: int, node_index: int, expected: bool = True) -> str:
        assert_node_type(node_type)
        path = f'{self.file_dir_path(filename)}/type{node_type}_node{node_index}.dat'
        if expected:
            assert os.path.exists(path), f"Shard not found: {path}"
        return path

    def shard_exists(self, filename: str, node_type: int, node_index: int) -> bool:
        return os.path.exists(self.shard_path(filename, node_type, node_index, expected=False))

    # Get encoded file configuration by name.
    def file(self, filename: str, expected: bool = True) -> EncodedFile | None:
        path = self.file_config_path(filename, expected=expected)
        try:
            return EncodedFile.load(path)
        except Exception as e:
            if expected:
                raise Exception(f"Error loading file config: {path}") from e
            return None

    # Get the path to a recovery file by file name, node type and index
    def recovery_file_path(self, file: str,
                           recover_node_type: int, recover_node_index: int,
                           helper_node_index: int, expected: bool = True) -> str:
        assert_node_type(recover_node_type)
        path = (f'{self.file_dir_path(file)}/recover'
                f'_type{recover_node_type}'
                f'_node{recover_node_index}'
                f'_from{helper_node_index}.dat')
        if expected:
            assert os.path.exists(path), f"Recovery file not found: {path}"
        return path

    # Enumerate the recovery files shard of the named file, recovery node type,
    # and recovery node index.
    # Note that the source node type is necessarily the opposite of the recovery node type.
    # Returns a list of tuples (source node_index, path)
    def list_recovery_files(
            self, file: str, recover_node_type: int, recover_node_index: int
    ) -> dict[int, str]:
        assert_node_type(recover_node_type)
        path = self.file_dir_path(file)
        files: dict[int, str] = {}
        for filename in os.listdir(path):
            match = re.match(
                r'recover_type(\d+)_node(\d+)_from(\d+).dat', filename)
            if not match:
                continue
            recover_type, recover_index, source_node_index = int(match.group(1)), int(
                match.group(2)), int(match.group(3))
            if recover_type == recover_node_type and recover_index == recover_node_index:
                files[source_node_index] = os.path.join(path, filename)

        return files

    # Get the path to a temporary repository file by file name
    def tmp_file_path(self, file: str):
        return os.path.join(self.tmp_dir(), f'{file}')

    def tmp_dir(self):
        return self.repo_path('tmp')

    # Map the available shards of an encoded repository file.
    # This returns two ordered dicts, one for type 0 files and one for type 1 files,
    # containing filename -> node index
    def map_shards(self, file: str) -> (dict[str, int], dict[str, int]):
        return self.map_files(self.file_dir_path(file))

    def file_exists(self, filename):
        return os.path.exists(self.file_dir_path(filename, expected=False))

    # Get the encoded file status which includes the file config and available shards for the filename.
    def file_status(self, filename: str) -> EncodedFileStatus:
        type0_files, type1_files = self.map_shards(filename)
        t0 = list(type0_files.values())
        t1 = list(type1_files.values())
        file: EncodedFile = self.file(filename)
        return EncodedFileStatus(
            file=file,
            shards0=t0,
            shards1=t1,
        )

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
    def main():
        repo = Repository.default()
        files: list[str] = repo.list()
        print("Files in repository:")
        for file in files:
            print('  ', repo.file(file))

        ic(repo.file_config_path(files[0]))
        # print()
        # file = 'file_1KB.dat'
        # print(repo.file_path(file))
        # print(repo.shard_path(file, node_type=0, node_index=0))

        print("Recovery files:")
        recovery_files = repo.list_recovery_files(files[0], recover_node_type=0, recover_node_index=0)
        for node_index, path in recovery_files:
            print(node_index, path)


    main()
    ...

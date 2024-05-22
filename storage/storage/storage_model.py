import os
import uuid
from typing import Optional

import commentjson as json
from icecream import ic
from pydantic import BaseModel

from storage.util import summarize_ranges, file_availability_ratio


class ModelBase(BaseModel):
    # All models are immuitable and hashable
    class Config:
        frozen = True

    # load from json file
    @classmethod
    def load(cls, file_path):
        with open(file_path, 'r') as f:
            return cls(**json.load(f))

    # load from json string
    @classmethod
    def from_json(cls, json_str):
        return cls(**json.loads(json_str))

    def to_json(self):
        return self.model_dump_json()

    # Save to json file
    def save(self, file_path, mkdirs: bool = False):
        if mkdirs:
            os.makedirs(os.path.dirname(file_path), exist_ok=True)
        with open(file_path, 'w') as f:
            f.write(self.model_dump_json(indent=2, exclude_defaults=True))

    def save_atomic(self, file_path, mkdirs: bool = False):
        tmpid = str(uuid.uuid4())
        tmp_path = file_path + f'.{tmpid}'
        self.save(tmp_path, mkdirs)
        os.rename(tmp_path, file_path)


#
#  Encoded File config
#

class NodeType(ModelBase):
    type: int
    encoding: str
    k: int
    n: int

    @property
    def alt_type(self):
        return 1 if self.type == 0 else 0

    @property
    def transpose(self):
        return self.type == 1

    def assert_reed_solomon(self):
        assert self.encoding == 'reed_solomon', "Only reed solomon encoding is currently supported."


class NodeType0(NodeType):
    # transpose: bool = False
    type: int = 0


class NodeType1(NodeType):
    # transpose: bool = True
    type: int = 1


class FileEncryption(ModelBase):
    type: str
    encrypted_symmetric_key: str
    initialization_vector: str

    @property
    def key(self) -> bytes:
        return bytes.fromhex(self.encrypted_symmetric_key)

    @property
    def iv(self) -> bytes:
        return bytes.fromhex(self.initialization_vector)


# The file 'config' metadata for an encoded file. This is always stored alongside the encoded file
# in the local repository and accompanies individual shards when they are distributed.
class EncodedFile(ModelBase):
    name: str
    file_hash: str
    file_length: int
    file_encryption: Optional[FileEncryption] = None

    type0: NodeType0
    # type0_hashes: Optional[tuple[str, ...]] = None
    type1: NodeType1

    # type1_hashes: Optional[tuple[str, ...]] = None

    @property
    def k0(self):
        return self.type0.k

    @property
    def k1(self):
        return self.type1.k

    @property
    def n0(self):
        return self.type0.n

    @property
    def n1(self):
        return self.type1.n

    def encoding_str(self):
        encoding0 = f'{self.type0.encoding}:{self.type0.k}/{self.type0.n}'
        encoding1 = f'{self.type1.encoding}:{self.type1.k}/{self.type1.n}'
        return encoding0 if encoding0 == encoding1 else f"{encoding0}|{encoding1}"


class EncodedFileStatus(ModelBase):
    file: EncodedFile
    # TODO: change to tuple[int, ...], these are mutable and not hashable
    shards0: list[int]
    shards1: list[int]

    # Get shards info for the specified type
    def shards(self, node_type: int):
        return self.shards0 if node_type == 0 else self.shards1

    def local_availability(self) -> float:
        return file_availability_ratio(
            self.file.k0, self.file.k1, len(self.shards0), len(self.shards1))

    # Produce a compact string summarizing the shards available for this file.
    def status_str(self) -> str:
        return (f"File: {self.file.name}, "
                f"Encoding: {self.file.encoding_str()}, "
                f"Availability: {self.local_availability()}, "
                f"Type0_shards: [{summarize_ranges(self.shards0)}], "
                f"Type1_shards: [{summarize_ranges(self.shards1)}]")

    # to string
    def __str__(self):
        return self.status_str()


class BlobCommitments(ModelBase):
    file_name: str
    commitments: list[str]

    def commitments_bytes(self) -> list[bytes]:
        return [bytes.fromhex(commitment) for commitment in self.commitments]

    @property
    def count(self):
        return len(self.commitments)

    def for_indices(self, indices: list[int])-> list[bytes]:
        return [bytes.fromhex(self.commitments[i]) for i in indices]

    ...


def assert_node_type(node_type: int):
    assert node_type in [0, 1], "node_type must be 0 or 1."


if __name__ == '__main__':
    # config = load_config('config.jsonc')
    # print(config)
    # print(f"config version: {config.config_version}")

    node = NodeType0(encoding='reed_solomon', k=3, n=5)
    assert node.transpose is False
    node = NodeType(type=0, encoding='reed_solomon', k=3, n=5)
    assert node.transpose is False
    node = NodeType1(encoding='reed_solomon', k=3, n=5)
    assert node.transpose is True
    node = NodeType(type=1, encoding='reed_solomon', k=3, n=5)
    assert node.transpose is True

    file1 = EncodedFile(name='test',
                        file_length=100,
                        file_hash='0',
                        type0=NodeType0(encoding='reed_solomon', k=3, n=5),
                        type0_hashes=('0', '1', '2', '3', '4'),
                        type1=NodeType1(encoding='reed_solomon', k=3, n=5),
                        type1_hashes=('0', '1', '2', '3', '4'))
    file2 = EncodedFile(name='test',
                        file_length=100,
                        file_hash='0',
                        type0=NodeType0(encoding='reed_solomon', k=3, n=5),
                        type0_hashes=('0', '1', '2', '3', '4'),
                        type1=NodeType1(encoding='reed_solomon', k=3, n=5),
                        type1_hashes=('0', '1', '2', '3', '4'))
    assert hash(file1) == hash(file2)

    ic(file2)
    file3 = file2.model_copy(update={'name': 'fooname'})
    ic(file3)

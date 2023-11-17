from typing import Optional, List
from storage.config import ModelBase


class Server(ModelBase):
    name: str = None  # for testing
    url: str
    # An auth token for the server-client pair allows listing files.
    # We could also support stateless discovery by hash.
    auth_token: Optional[str] = None

    class Config:
        frozen = True  # hashable
        ...


class Cluster(ModelBase):
    name: str
    servers: List[Server]


class ServerConfig(ModelBase):
    config_version: Optional[str] = None
    interface: Optional[str] = None
    port: Optional[int] = 8080
    auth_key: Optional[str] = None
    repository_dir: Optional[str] = None
    cluster: Optional[Cluster] = None


class ServerFile(ModelBase):
    name: str
    encoding0: str
    k0: int
    n0: int
    encoding1: str
    k1: int
    n1: int

    def encoding_str(self):
        encoding0 = f'{self.encoding0}:{self.k0}/{self.n0}'
        encoding1 = f'{self.encoding1}:{self.k1}/{self.n1}'
        return encoding0 if encoding0 == encoding1 else f"{encoding0}|{encoding1}"

    class Config:
        frozen = True  # hashable


class ServerFileStatus(ModelBase):
    file: ServerFile
    shards0: List[int]
    shards1: List[int]

    class Config:
        frozen = True  # hashable


if __name__ == '__main__':
    # config = Cluster.load('cluster.jsonc')
    # print(config)
    # print(f"config version: {config.config_version}")

    file = ServerFile(name='test', encoding0='erasure', k0=2, n0=3, encoding1='erasure', k1=2, n1=3)
    file2 = ServerFile(name='test', encoding0='erasure', k0=2, n0=3, encoding1='erasure', k1=2, n1=3)
    print(hash(file) == hash(file2))

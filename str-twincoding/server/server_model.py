from enum import Enum
from typing import Optional, List
from storage.storage_model import ModelBase


class Server(ModelBase):
    name: str = None  # for testing
    url: str
    # An auth token for the server-client pair allows listing files.
    # We could also support stateless discovery by hash.
    auth_token: Optional[str] = None

    # pydantic config to make this class hashable
    class Config:
        frozen = True
        ...


class ServerStatus(Enum):
    OK = "OK"
    UNKNOWN = "UNKNOWN"
    UNREACHABLE = "UNREACHABLE"
    NA = "-"


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


class ProvidersConfig(ModelBase):
    providers: List[Server]


if __name__ == '__main__':
    ...
    # config = Cluster.load('cluster.jsonc')
    # print(config)
    # print(f"config version: {config.config_version}")

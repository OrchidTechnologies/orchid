from enum import Enum
from typing import Optional, List
from storage.storage_model import ModelBase, EncodedFile


class Server(ModelBase):
    name: Optional[str] = None  # for testing
    url: str
    # An auth token for the server-client pair allows listing files.
    # We could also support stateless discovery by hash.
    auth_token: Optional[str] = None


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


# Request that a provider rebuild a shard using the specified providers
# The target provider must have the file config and resolve the provider list of either urls or names.
class RepairShardRequest(ModelBase):
    file: EncodedFile
    repair_node_type: int
    repair_node_index: int
    providers: List[Server]
    dryrun: bool = False
    overwrite: bool = False


if __name__ == '__main__':
    ...
    # config = Cluster.load('cluster.jsonc')
    # print(config)
    # print(f"config version: {config.config_version}")

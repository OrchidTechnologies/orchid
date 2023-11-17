from enum import Enum
from typing import List

from server.server_config import Server
from storage.config import ModelBase


class ServerStatus(Enum):
    OK = "OK"
    UNKNOWN = "UNKNOWN"
    NA = "-"


class MonitorConfig(ModelBase):
    providers: List[Server]

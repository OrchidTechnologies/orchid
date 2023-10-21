import commentjson as json
from pydantic import BaseModel

config_str = """
{
  "config_version": "1.0",
  
  # Console
  "console": {
    "public_url": "http://localhost:8080/",
    "port": 8080,
  },
  
  "encoder": {
    # num_cores: 4,
  },
  
  # Cluster
  "cluster": {
      "name": "testnet",
      "type0": {
        "encoding": "reed_solomon",
        "k": 3,
        "n": 5
      },
      "type1": {
        "encoding": "reed_solomon",
        "k": 3,
        "n": 5
      },
  },
}
"""


class NodeType(BaseModel):
    encoding: str
    k: int
    n: int
    transpose: bool = None


class NodeType0(NodeType):
    transpose: bool = False


class NodeType1(NodeType):
    transpose: bool = True


class Console(BaseModel):
    public_url: str
    port: int


class Cluster(BaseModel):
    name: str
    type0: NodeType0
    type1: NodeType1


class Config(BaseModel):
    config_version: str
    console: Console
    cluster: Cluster


class EncodedFileConfig(BaseModel):
    name: str
    type0: NodeType0
    type1: NodeType1
    file_length: int
    # file_hash: str


def load_config(file_path):
    # with open(file_path, 'r') as f:
    #     config_dict = json.load(f)
    print("Loading internal config")
    config_dict = json.loads(config_str)
    return Config(**config_dict)


def load_file_config(path) -> EncodedFileConfig:
    with open(path, 'rb') as f:
        config_dict = json.load(f)
        return EncodedFileConfig(**config_dict)


if __name__ == '__main__':
    config = load_config('config.json')
    print(f"config version: {config.config_version}")

import commentjson as json
from pydantic import BaseModel


class ModelBase(BaseModel):
    @classmethod
    def load(cls, file_path):
        with open(file_path, 'r') as f:
            return cls(**json.load(f))


#
#  File config
#

class NodeType(ModelBase):
    type: int
    encoding: str
    k: int
    n: int

    @property
    def transpose(self):
        return self.type == 1


class NodeType0(NodeType):
    # transpose: bool = False
    type: int = 0


class NodeType1(NodeType):
    # transpose: bool = True
    type: int = 1


class EncodedFileConfig(ModelBase):
    name: str
    type0: NodeType0
    type1: NodeType1
    file_length: int
    # file_hash: str


if __name__ == '__main__':
    # config = load_config('config.jsonc')
    # print(config)
    # print(f"config version: {config.config_version}")

    node = NodeType0(encoding='reed_solomon', k=3, n=5)
    print(node, node.transpose)
    node = NodeType(type=0, encoding='reed_solomon', k=3, n=5)
    print(node, node.transpose)
    node = NodeType1(encoding='reed_solomon', k=3, n=5)
    print(node, node.transpose)
    node = NodeType(type=1, encoding='reed_solomon', k=3, n=5)
    print(node, node.transpose)

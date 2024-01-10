import os
from typing import List, Optional

from server.server_model import ProvidersConfig, Server
from storage.util import get_strhome


class Providers:
    servers: List[Server] = None
    default_providers_config: str = get_strhome('providers.jsonc')

    def __init__(self, servers: List[Server]):
        self.servers = servers

    @classmethod
    def from_config(cls, config: ProvidersConfig) -> 'Providers':
        return Providers(config.providers)

    @classmethod
    def default(cls) -> 'Providers':
        path = cls.default_providers_config
        print(f"Using default providers path: {path}")
        return cls.get(path)

    @staticmethod
    def get(path: str) -> Optional['Providers']:
        if not os.path.exists(path):
            return None
        return Providers.from_config(ProvidersConfig.load(path))

    @staticmethod
    def get_or_default(path: str) -> 'Providers':
        if path:
            return Providers.get(path)
        else:
            return Providers.default()

    # Resolve names or urls to Server models.
    def resolve_provider_names(self, providers: List[str]) -> List[Server]:
        return [self._resolve_provider_name(name) for name in providers]

    # Resolve names or urls to Server models.
    # Names can be specified in the providers.jsconc config file.
    def _resolve_provider_name(self, provider: str) -> Server:
        # Does the provider string look like a url?
        if provider.startswith('http'):
            return Server(url=provider)
        else:
            # look up the provider name in the providers config file
            for server in self.servers:
                if server.name == provider:
                    return server
            raise Exception(f"Provider name not found in providers config file: {provider}")


if __name__ == '__main__':
    ...

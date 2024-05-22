import argparse
from typing import Set

from icecream import ic

from server.providers import Providers
from server.server_model import Server, ProvidersConfig
from storage.table_util import print_table


# List the providers in the providers config file
def list_providers(args: argparse.Namespace):
    providers: Providers = Providers.get_or_default(args.file)
    if providers and providers.servers:
        print_table(["Name", "URL"], [(server.name, server.url) for server in providers.servers])
    else:
        print("No providers configured.")


# Manually "discover" providers, adding them to the providers config file
def add_providers(args: argparse.Namespace):
    ic(args.providers)
    arg_providers: Set[Server] = set()
    for arg in args.providers:
        # if all digits, assume it's a port number
        if arg.isdigit():
            arg_providers.add(Server(name=arg, url=f"http://localhost:{arg}"))
        # if it looks like a url, assume it's a url
        elif arg.startswith('http'):
            arg_providers.add(Server(url=arg))
        else:
            raise Exception(f"Unknown provider format: {arg}")

    # load the providers config file
    providers_path: str = args.file or Providers.default_providers_config
    providers: Providers = Providers.get(providers_path)

    # If the providers config file doesn't exist, create it
    if not providers:
        providers = Providers(servers=[])

    # Add to the existing
    servers = list(set(providers.servers).union(arg_providers))
    # sort the list
    servers.sort(key=lambda server: server.name or server.url)
    config = ProvidersConfig(providers=servers)

    # Save the updated
    config.save(providers_path)
    ...


# Clear the providers in the providers config file
def clear_providers(args: argparse.Namespace):
    providers_path: str = args.file or Providers.default_providers_config
    ProvidersConfig(providers=[]).save(providers_path)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Process command line arguments.')
    parser.add_argument('--file', type=str, help='Providers config file path')

    # add a 'list' subcommand
    subparsers = parser.add_subparsers(metavar='COMMAND', help="Sub-commands available.")
    list_parser = subparsers.add_parser('list', help='List providers')
    list_parser.set_defaults(func=list_providers)

    # add an 'add' subcommand that accepts a list of providers
    add_parser = subparsers.add_parser('add', help='Add providers')
    add_parser.add_argument('providers', type=str, nargs='+', help='Providers to add')
    add_parser.set_defaults(func=add_providers)

    # add a 'clear' subcommand
    add_parser = subparsers.add_parser('clear', help='Clear the providers file')
    add_parser.set_defaults(func=clear_providers)

    args = parser.parse_args()
    if hasattr(args, 'func'):
        args.func(args)
    else:
        parser.print_help()

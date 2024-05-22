from server.server_app import ServerApp
from server.server_context import set_shared
# from server.server_app import shared as server_app_shared
from server.server_model import ServerConfig
import argparse

from storage.repository import Repository

if __name__ == '__main__':
    # Define the command line argument parser
    parser = argparse.ArgumentParser(description="Flask server with argument parsing")
    parser.add_argument("--config", type=str, help="server config file")
    parser.add_argument("--interface", type=str, help="Interface the server listens on")
    parser.add_argument("--port", type=int, help="Port the server listens on")
    parser.add_argument("--repository_dir", type=str, help="Directory to store repository files")
    parser.add_argument("--auth_key", type=str, help="Authentication key to validate requests")
    parser.add_argument("--debug", action='store_true', help="Debug server")

    args = parser.parse_args()

    # Config file
    config = ServerConfig.load(args.config) if args.config else ServerConfig()
    print(f"config version: {config.config_version}")

    # Merge params
    interface = args.interface or config.interface
    port = args.port or config.port or 8080

    # Shared resources
    repository = Repository(args.repository_dir) if args.repository_dir else Repository.default()

    auth_key = args.auth_key or config.auth_key
    debug = args.debug or True

    # Create the server app
    app = ServerApp(
        repository=repository,
        config=config,
        interface=interface,
        port=port,
        auth_key=auth_key,
        debug=debug,
    )
    set_shared(app)
    app.run()

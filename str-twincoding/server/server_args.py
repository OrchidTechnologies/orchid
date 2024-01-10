from server.server_model import ServerConfig
import argparse
from storage.repository import Repository


class App:
    def __init__(self):
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
        self.interface = args.interface or config.interface
        self.port = args.port or config.port or 8080

        # Repository
        self.repository = Repository(args.repository_dir) if args.repository_dir else Repository.default()

        self.auth_key = args.auth_key or config.auth_key
        if not self.auth_key:
            print("WARNING: No client auth key db provided. Requests will not be validated.")
        self.debug = args.debug or False


app: App = App()

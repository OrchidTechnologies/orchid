from flask import Flask
from server.render_queue import RenderQueue
from server.server_model import ServerConfig
from storage.repository import Repository
from server.server_api.server_api import server_api
from server.server_api.server_api_list import server_api_list
from server.server_api.server_api_repair import server_api_repair
from server.server_api.server_api_upload import server_api_upload
from server.server_api.server_api_delete import server_api_delete
from server.server_api.server_api_verify import server_api_verify


class ServerApp:

    def __init__(
            self,
            repository: Repository,
            config: ServerConfig = None,
            interface: str = None,
            port: int = None,
            auth_key: str = None,
            debug: bool = False,
    ):
        self.config = config
        self.interface = interface
        self.port = port
        self.debug = debug

        if not auth_key:
            print("WARNING: No client auth key db provided. Requests will not be validated.")
        self.auth_key = auth_key

        self.repository = repository
        self.render_queue = RenderQueue()

    def run(self):
        flask = Flask(__name__)
        flask.config['UPLOAD_FOLDER'] = self.repository.tmp_dir()
        flask.config['MAX_CONTENT_PATH'] = 1024 * 1024 * 1024

        # Register the blueprints
        flask.register_blueprint(server_api)
        flask.register_blueprint(server_api_list)
        flask.register_blueprint(server_api_repair)
        flask.register_blueprint(server_api_upload)
        flask.register_blueprint(server_api_delete)
        flask.register_blueprint(server_api_verify)

        flask.run(host=self.interface, port=self.port, debug=self.debug)


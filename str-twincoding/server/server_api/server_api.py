from flask import jsonify, request, Request, Blueprint
from werkzeug.datastructures import FileStorage
from werkzeug.utils import secure_filename

from server.server_context import app
from storage.storage_model import EncodedFile

server_api = Blueprint('api', __name__, url_prefix='/')


# Default page.
@server_api.route('/')
def root():
    return 'Orchid Storage Server'


# Health check endpoint.
@server_api.route('/health', methods=['POST', 'GET'])
def health_check():
    if not is_authorized(request):
        return jsonify({"error": "Unauthorized"}), 401
    return jsonify({"status": "OK"})


# Placeholder for authorization logic and payment system.
def is_authorized(request):
    return request.headers.get('Authorization') == app().auth_key or (not app().auth_key)


# Get a EncodedFile config from the request, sanitizing the filename before any path
# logic is exposed to it.
def file_config_from(request: Request) -> EncodedFile | None:
    try:
        config_stor: FileStorage = request.files['config']
        config_str = config_stor.read().decode('utf-8')
        uploaded_config: EncodedFile = EncodedFile.from_json(config_str)
        return uploaded_config.model_copy(
            update={'name': secure_filename(uploaded_config.name)}
        )
    except Exception as e:
        print("Error loading file config:", e)
        return None


def node_type_from(request: Request) -> int | None:
    return int(request.form['node_type']) if 'node_type' in request.form else None


def shard_index_from(request: Request) -> int | None:
    return int_from('shard_index', request)


def int_from(name: str, request: Request) -> int | None:
    return int(request.form[name]) if name in request.form else None


def string_from(name: str, request: Request) -> str | None:
    return request.form[name] if name in request.form else None


# bytes from hex encoded string
def bytes_from(name: str, request: Request) -> bytes | None:
    return bytes.fromhex(request.form[name]) if name in request.form else None


if __name__ == '__main__':
    ...

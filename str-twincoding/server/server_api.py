# In your views.py or a similar file
import json

from flask import Blueprint, jsonify, request
from server_args import app
from server_config import ServerFileStatus, ServerFile

bp = Blueprint('my_blueprint', __name__, url_prefix='/')


# Placeholder for authorization logic and payment system.
def is_authorized(request):
    return request.headers.get('Authorization') == app.auth_key or (not app.auth_key)


@bp.route('/')
def hello_world():
    return 'Storage Server'


@bp.route('/health', methods=['POST', 'GET'])
def health_check():
    if not is_authorized(request):
        return jsonify({"error": "Unauthorized"}), 401
    return jsonify({"status": "OK"})


@bp.route('/list', methods=['POST', 'GET'])
def list_files():
    if not is_authorized(request):
        return jsonify({"error": "Unauthorized"}), 401
    try:
        print([map_file(file).model_dump() for file in app.repository.list()])
        return jsonify([map_file(file).model_dump() for file in app.repository.list()])
    except Exception as e:
        return jsonify({"error": str(e)}), 500


def map_file(filename):
    type0_files, type1_files = app.repository.map(filename)
    t0 = list(type0_files.values())
    t1 = list(type1_files.values())
    config = app.repository.file_config(filename)
    return ServerFileStatus(
        file=ServerFile(name=filename,
                        encoding0=config.type0.encoding,
                        k0=config.type0.k,
                        n0=config.type0.n,
                        encoding1=config.type1.encoding,
                        k1=config.type1.k,
                        n1=config.type1.n),
        shards0=t0,
        shards1=t1,
    )


if __name__ == '__main__':
    file = app.repository.list()[0]
    type0_files, type1_files = app.repository.map(file)
    config = app.repository.file_config(file)
    to_json = json.dumps([map_file(file).model_dump() for file in app.repository.list()])
    from_json = json.loads(to_json)
    for file in from_json:
        fs = ServerFileStatus(**file)
        print(fs.name)
    ...

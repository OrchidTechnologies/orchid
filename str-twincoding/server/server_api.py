import os
import uuid
from flask import Blueprint, jsonify, request
from icecream import ic
from werkzeug.datastructures import FileStorage
from werkzeug.utils import secure_filename

from storage.repository import Repository
from storage.storage_model import EncodedFileStatus, EncodedFile

from server_args import app
import json

bp = Blueprint('api_blueprint', __name__, url_prefix='/')


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
        return jsonify([app.repository.file_status(file).model_dump() for file in app.repository.list()])
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# flask file upload endpoint
@bp.route('/upload', methods=['POST'])
def upload_file():
    if not is_authorized(request):
        return jsonify({"error": "Unauthorized"}), 401
    try:
        app.repository.ensure_init()

        # Get the uploaded file config
        config_stor: FileStorage = request.files['config']
        config_str = config_stor.read().decode('utf-8')
        uploaded_config: EncodedFile = EncodedFile.load_json(config_str)
        filename: str = secure_filename(uploaded_config.name)
        node_type = int(request.form['node_type']) if 'node_type' in request.form else None
        shard_index = int(request.form['shard_index']) if 'shard_index' in request.form else None

        # Save the file shard to the tmp path
        shard_uuid: str = str(uuid.uuid4())
        tmp_shard_name = f"{shard_uuid}.dat"
        file_stor: FileStorage = request.files['file']
        tmp_shard_path = app.repository.tmp_file_path(tmp_shard_name)
        file_stor.save(tmp_shard_path)

        # Validate the upload
        # TODO: We need the shard hashes to validate the upload

        # Validate or create the file config
        local_file_config = app.repository.file(filename, expected=False)
        if local_file_config:
            # Compare the uploaded file config
            if uploaded_config != local_file_config:
                raise Exception(f"File config mismatch: {local_file_config}")
        else:
            # Save the config, creating a new repo file dir j
            file_config_path = app.repository.file_config_path(filename, expected=False)
            uploaded_config.save_atomic(file_config_path, mkdirs=True)

        # Save the shard to the file dir (atomically if possible)
        shard_path = app.repository.shard_path(filename, node_type, shard_index, expected=False)
        os.rename(tmp_shard_path, shard_path)

        return jsonify({"status": "OK"})

    except Exception as e:
        print("Error uploading file:", e)
        # show the stack
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500





if __name__ == '__main__':
    from storage.storage_model import EncodedFileStatus, EncodedFile

    # file = app.repository.list()[0]
    # type0_files, type1_files = app.repository.map_shards(file)
    # config = app.repository.file(file)
    to_json = json.dumps([app.repository.file_status(file).model_dump() for file in app.repository.list()])
    ic(to_json)
    from_json = json.loads(to_json)
    for file in from_json:
        fs = EncodedFileStatus(**file)
        print(fs.file.name)
    ...


def foo():
    pass

def foo():
    ...

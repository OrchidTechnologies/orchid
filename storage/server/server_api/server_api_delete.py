import os

from flask import jsonify, request, Blueprint

from server.server_api.server_api import file_config_from, int_from
from server.server_context import app
from storage.storage_model import EncodedFile

server_api_delete = Blueprint('delete', __name__, url_prefix='/')


# Delete shard
@server_api_delete.route('/delete_shard', methods=['POST'])
def delete_shard():
    uploaded_config = file_config_from(request)
    if not uploaded_config:
        return jsonify({"error: Missing required param: file config"}), 500
    filename: str = uploaded_config.name  # sanitized
    node_type = int_from('node_type', request)
    node_index = int_from('node_index', request)
    print(f"Request delete shard for: {uploaded_config}, {node_type}, {node_index}", flush=True)

    # Validate that we have the shard to delete
    file_config: EncodedFile | None = app().repository.file(filename)
    if file_config != uploaded_config:
        return jsonify({"error: File config mismatch"}), 500
    try:
        shard_path: str = app().repository.shard_path(filename, node_type, node_index, expected=True)
    except:
        return jsonify({"error: Source shard not available"}), 500

    # Delete the shard
    os.remove(shard_path)
    return jsonify({"status": "OK"})

import os
import uuid

from flask import jsonify, request, Blueprint
from werkzeug.datastructures import FileStorage

from server.server_api.server_api import is_authorized, file_config_from, node_type_from, shard_index_from, int_from
from server.server_context import app

server_api_upload = Blueprint('upload', __name__, url_prefix='/')


# Upload a file shard to this node's repository.
# The upload contains file configuration and a single large binary data shard.
# The file is uploaded to the repository's tmp dir and then moved to the file dir after validation.
#
# Payment: Note that the client should pay not only for the upload bandwidth but the temporary storage
# utilized by the shard during validation, which is outside the scope of the storage committment
# and bonded payment scheme.
@server_api_upload.route('/upload', methods=['POST'])
def upload_file():
    if not is_authorized(request):
        return jsonify({"error": "Unauthorized"}), 401
    try:
        app().repository.ensure_init()

        uploaded_config = file_config_from(request)
        filename: str = uploaded_config.name  # sanitized
        node_type = node_type_from(request)
        shard_index = shard_index_from(request)

        # Save the file shard to the tmp path
        shard_uuid: str = str(uuid.uuid4())
        tmp_shard_name = f"{shard_uuid}.dat"
        file_stor: FileStorage = request.files['file']
        tmp_shard_path = app().repository.tmp_file_path(tmp_shard_name)
        file_stor.save(tmp_shard_path)

        # Validate the upload
        # TODO: We need the shard hashes to validate the upload

        # Validate or add the file config
        local_file_config = app().repository.file(filename, expected=False)
        if local_file_config:
            # Compare the uploaded file config with our current notion of the config.
            if uploaded_config != local_file_config:
                raise Exception(f"File config mismatch: {local_file_config}")
        else:
            # Save the config, creating a new repo file dir.
            app().repository.save_file_config(uploaded_config)

        # Save the shard to the file dir (atomically if possible)
        shard_path = app().repository.shard_path(filename, node_type, shard_index, expected=False)
        os.rename(tmp_shard_path, shard_path)

        return jsonify({"status": "OK"})

    except Exception as e:
        print("Error uploading file:", e)
        # show the stack
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


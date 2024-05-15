from typing import List

from flask import jsonify, request, Blueprint
from werkzeug.utils import secure_filename

from commitments.kzg_commitment import FileCommitments
from server.server_context import app
from server.server_model import VerifyShardRequest, VerifyShardResponse, Proof
from storage.storage_model import EncodedFile

server_api_verify = Blueprint('verify', __name__, url_prefix='/')


# Verify shard by providing the requested proofs
@server_api_verify.route('/verify_shard', methods=['POST'])
def verify_shard():
    # Get the request including the challenge
    verify_request_str: str = request.form['request']
    verify_request = VerifyShardRequest.from_json(verify_request_str)

    # Validate that we have the shard to verify
    uploaded_config = verify_request.file
    if not uploaded_config:
        return jsonify({"error: Missing required param: file config"}), 500

    # The file shard to verify
    filename: str = uploaded_config.name  # sanitized by virtue of comparison above
    node_type = verify_request.node_type
    node_index = verify_request.node_index
    print(f"Request verify shard for: {uploaded_config}, {node_type}, {node_index}", flush=True)

    # The challenge value and number of blobs to verify
    challenge: bytes = bytes.fromhex(verify_request.challenge)
    challenge_count: int = verify_request.challenge_count

    # Validate that we have the shard to verify
    file_config: EncodedFile | None = app().repository.file(filename)
    if file_config != uploaded_config:
        return jsonify({"error: File config mismatch"}), 500
    try:
        shard_path: str = app().repository.shard_path(filename, node_type, node_index, expected=True)
    except:
        return jsonify({"error: Source shard not available"}), 500

    # Respond with the requested proofs
    file_commitments = FileCommitments(shard_path)
    blob_count = file_commitments.blob_count
    assert challenge_count <= blob_count, f"Invalid challenge count: {challenge_count} > {blob_count}"
    challenge_indices = FileCommitments.challenge_to_indices(challenge, blob_count, challenge_count)
    proofs: list[Proof] = file_commitments.get_proofs(challenge, challenge_indices)
    verify_reponse = VerifyShardResponse(proofs=proofs)
    return jsonify(verify_reponse.to_json())

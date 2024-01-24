from flask import jsonify, request, send_file, Blueprint
from icecream import ic

from encoding.node_recovery_source import NodeRecoverySource
from server.server_api.repair_shard_task import RepairShardTask
from server.server_api.server_api import file_config_from, int_from
from server.server_context import app
from server.server_model import RepairShardRequest
from storage.repository import Repository
from storage.storage_model import EncodedFile

server_api_repair = Blueprint('recovery', __name__, url_prefix='/')


# Request that this provider generate and return a twin-coding shard recovery file (one of
# k required by the client for shard repair) in support of reconstructing a specified shard.
# The server will sanity check the request by validating that it has the necessary data,
# e.g. that it is of the correct (alternate) node type and has its own shard or shards of the named file.
# Recovery requests are idempotent within a reasonble period of time and concurrent requests for the same
# recovery file will be consolidated.  This means that if a request times out while the server is
# rendering the file, the client may simply make the same request again, perhaps after waiting for a
# period of time for the render to complete.
#
# Payment: Note that the client should pay for the bandwidth, temporary storage, and compute utilized
# in the production of the recovery file.
@server_api_repair.route('/recovery_source', methods=['POST'])
def recovery_source():
    # The recovery request params
    uploaded_config = file_config_from(request)
    if not uploaded_config:
        return jsonify({"error: Missing required param: file config"}), 500
    print(f"Request recovery file for: {uploaded_config}")
    filename: str = uploaded_config.name  # sanitized
    recover_node_type = int_from('recover_node_type', request)
    recover_node_index = int_from('recover_node_index', request)
    source_node_type = 0 if recover_node_type == 1 else 1
    source_node_index = int_from('source_node_index', request)
    if recover_node_type is None or recover_node_index is None or source_node_index is None:
        print(f"Missing required params: {request.form}")
        return jsonify({"error: Missing required params"}), 500

    # Validate that we have one or more shards of the correct type for the file
    file_config: EncodedFile | None = app().repository.file(filename)
    if file_config != uploaded_config:
        return jsonify({"error: File config mismatch"}), 500

    # Validate that we have the source shard
    try:
        app().repository.shard_path(filename, source_node_type, source_node_index, expected=True)
    except:
        return jsonify({"error: Source shard not available"}), 500

    # Prepare to generate the recovery file
    source = NodeRecoverySource.for_repo(
        repo=app().repository,
        filename=filename,
        recover_node_type=file_config.type0 if recover_node_type == 0 else file_config.type1,
        recover_node_index=recover_node_index,
        source_node_type=file_config.type0 if source_node_type == 0 else file_config.type1,
        source_node_index=source_node_index,
        overwrite=True
    )

    # Start rendering the recovery file and wait for it to complete.
    # The render queue makes this request idempotent, so if a render for this source is already
    # in progress we will join the existing task.
    app().render_queue.start_render(source)
    app().render_queue.wait_for_completion(source)
    ...

    # Stream the recovery file to the client
    return send_file(source.output_path)


# Initiate a repair operation. This provider node will contact other (optionally specified) providers
# to request recovery files for reconstructing the specified shard.
# Note that if any accessible provider already has the desired shard then it is cheaper to simply
# request the shard rather than reconstruct it.  However, a twin-coded repair operation is cheaper
# than a full file reconstruction when only one or more shards is missing.  Specifically it reduces
# bandwidth usage costs to precisely the size of the missing shards.
#
# Payment: Note that the client should pay not only for the bandwidth utilized by the repair operation
# but also for the temporary storage utilized by the recovery files during validation.
# Note that providers may find it cheaper to cache recovery files once requested rather than producing
# them on demand.
@server_api_repair.route('/repair', methods=['POST'])
def repair():
    repair_request_str: str = request.form['request']
    repair_request = RepairShardRequest.load_json(repair_request_str)

    # Does the request file config match one that we already have?
    repo: Repository = app().repository
    file_config: EncodedFile | None = repo.file(filename=repair_request.file.name, expected=False)

    print(f"Request repair file shard of file: {repair_request.file}, "
          f"node_type: {repair_request.repair_node_type},"
          f"node_index: {repair_request.repair_node_index}", flush=True)

    if file_config and file_config != repair_request.file:
        return jsonify({"error: File config mismatch"}), 500
    if not file_config:
        # Save the new file config
        repo.save_file_config(repair_request.file)

    task = RepairShardTask(
        repo=app().repository,
        providers=repair_request.providers,
        file=repair_request.file,
        repair_node_type=repair_request.repair_node_type,
        repair_node_index=repair_request.repair_node_index,
        dryrun=repair_request.dryrun,
        overwrite=repair_request.overwrite
    )

    # Start the repair opreration and wait for it to complete.
    # The render queue makes this request idempotent, so if a render for this repair is already
    # in progress we will join the existing task.
    app().render_queue.start_render(task)
    result = app().render_queue.wait_for_completion(task)

    # Return ok
    return jsonify({"status": "ok", "message": result})

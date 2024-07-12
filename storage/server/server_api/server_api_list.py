from flask import jsonify, request, Blueprint

from server.server_api.server_api import is_authorized
from server.server_context import app

server_api_list = Blueprint('list', __name__, url_prefix='/')


# List all files in this node's repository.
# Note that it is TBD how files will be scoped to client authentication or allowed to be public.
# Currently, during development, all files are public.
@server_api_list.route('/list', methods=['POST', 'GET'])
def list_files():
    if not is_authorized(request):
        return jsonify({"error": "Unauthorized"}), 401
    try:
        return jsonify([app().repository.file_status(file).model_dump() for file in app().repository.list()])
    except Exception as e:
        return jsonify({"error": str(e)}), 500

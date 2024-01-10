from flask import Flask
from server_api import bp
from server_args import app

if __name__ == '__main__':
    flask = Flask(__name__)
    flask.config['UPLOAD_FOLDER'] = app.repository.tmp_dir()
    flask.config['MAX_CONTENT_PATH'] = 1024 * 1024 * 1024
    flask.register_blueprint(bp)
    flask.run(host=app.interface, port=app.port, debug=app.debug)

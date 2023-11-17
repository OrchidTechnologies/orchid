from flask import Flask
from server_api import bp
from server_args import app

if __name__ == '__main__':
    flask = Flask(__name__)
    flask.register_blueprint(bp)
    flask.run(host=app.interface, port=app.port, debug=app.show_console)

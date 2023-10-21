from flask import Flask
from config import load_config

app = Flask(__name__)


@app.route('/')
def hello_world():
    return 'Hello, World!'


if __name__ == '__main__':
    config = load_config('config.json')
    print(f"config version: {config.config_version}")
    app.run(port=config.console.port)


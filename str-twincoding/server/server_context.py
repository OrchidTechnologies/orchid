from typing import Optional

# Note: This exists to break the circular dependency between server_app and the
# server api implementation classes.

shared: Optional['ServerApp'] = None


def set_shared(app):
    global shared
    shared = app


def app() -> 'ServerApp':
    global shared
    return shared

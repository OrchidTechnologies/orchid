import boto3
import logging
import os


def configure_logging(level=os.environ.get('LOG_LEVEL', "DEBUG")):
    if len(logging.getLogger().handlers) > 0:
        # The Lambda environment pre-configures a handler logging to stderr.
        # If a handler is already configured, `.basicConfig` does not execute.
        # Thus we set the level directly.
        logging.getLogger().setLevel(level=level)
    else:
        logging.basicConfig(level=level)


def get_secret(key: str) -> str:
    client = boto3.client('ssm')
    resp: dict = client.get_parameter(
        Name=key,
        WithDecryption=True,
    )
    return resp['Parameter']['Value']


def is_false(value: str) -> bool:
    return value.lower() in ['false', '0', 'no']


def is_true(value: str) -> bool:
    return value.lower() in ['true', '1', 'yes']

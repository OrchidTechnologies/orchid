import json
import logging
import os

from utils import configure_logging
from utils import is_true
from w3 import verifyMessage


configure_logging()


def main(event, context):
    stage = os.environ['STAGE']

    logging.debug(f'verify stage:{stage}')
    logging.debug(f'event: {event}')

    body = json.loads(event.get('body', {}))
    logging.debug(f'body: {body}')

    if is_true(body.get('debug', '')):
        configure_logging(level="DEBUG")

    msg = body.get('msg', '')
    sig = body.get('sig', '')

    verified = verifyMessage(message_text=msg, signed_message=sig)

    resp_body = {
        'message_text': msg,
        'signed_message': sig,
        'verified': verified,
    }

    response = {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": {},
        "body": json.dumps(resp_body)
    }
    logging.debug(f'verify response: {response}')
    return response

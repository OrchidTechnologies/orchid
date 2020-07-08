import json
import logging
import os

from utils import configure_logging


configure_logging()


def main(event, context):
    stage = os.environ['STAGE']

    logging.debug(f'store status stage:{stage}')
    logging.debug(f'event: {event}')
    logging.debug(f'context: {context}')

    response = {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": {},
        "body": json.dumps({
            'status': 'Healthy',
            'disabled': False,
        })
    }
    logging.debug(f'storestatus response: {response}')
    return response

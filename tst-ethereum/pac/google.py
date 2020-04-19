import json
import logging

from utils import configure_logging


configure_logging()


def main(event, context):
    response = {
        "isBase64Encoded": False,
        "statusCode": 501,
        "headers": {},
        "body": json.dumps({
            "message": f"Google Support Not Implemented Yet!",
            "push_txn_hash": None,
            "config": None,
        })
        }
    logging.debug(f'response: {response}')
    return response

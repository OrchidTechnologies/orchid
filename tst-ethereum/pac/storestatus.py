import json
import logging
import os

from utils import configure_logging
from utils import get_product_id_mapping


configure_logging()


def is_pac_tier_viable(price: str) -> bool:
    logging.debug(f'is_pac_tier_viable(): price: {price}')
    return True


def get_tier_statuses():
    mapping = get_product_id_mapping()
    statuses = {}
    for tier in mapping:
        usd = mapping[tier]
        statuses[tier] = is_pac_tier_viable(price=usd)
    return statuses


def main(event, context):
    stage = os.environ['STAGE']

    logging.debug(f'store status stage:{stage}')
    logging.debug(f'event: {event}')

    statuses = get_tier_statuses()

    disabled = 'False'
    status = 'Healthy'

    body = {
        'status': status,
        'disabled': disabled,
    }

    body.update(statuses)

    response = {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": {},
        "body": json.dumps(body)
    }
    logging.debug(f'storestatus response: {response}')
    return response

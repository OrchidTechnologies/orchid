import boto3
import json
import logging
import os
import uuid

from boto3.dynamodb.conditions import Key
from decimal import Decimal


def decimal_default(obj):
    if isinstance(obj, Decimal):
        return str(obj)
    raise TypeError("Object! of type '%s' is not JSON serializable" % type(obj).__name__)

def response(statusCode, data):
    msg = data.get('msg','response success')
    logging.info(msg)
    response = {
        "isBase64Encoded": False,
        "statusCode": statusCode,
        "headers": {},
        "body": json.dumps(data,default=decimal_default)
    }
    return response


def configure_logging(level=os.environ.get('LOG_LEVEL', "DEBUG")):
    logging.debug(f'Setting log level: {level}')
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


def random_scan(table, price):
    # generate a random 32 byte address (1 x 32 byte ethereum address)
    rand_key = uuid.uuid4().hex + uuid.uuid4().hex
    ddb_price = json.loads(json.dumps(price), parse_float=Decimal)  # Work around DynamoDB lack of float support
    response0 = table.query(Limit=4, KeyConditionExpression=Key('price').eq(ddb_price) & Key('signer').gte(rand_key))
    response1 = table.query(Limit=4, KeyConditionExpression=Key('price').eq(ddb_price) & Key('signer').lte(rand_key))
    response0['Items'].extend(response1['Items'])
    return response0


def get_min_escrow():
    return 15.0


def get_product_id_mapping(store: str = 'apple') -> dict:
    mapping = {}
    mapping['apple'] = {
        'net.orchid.pactier1': 39.99,
        'net.orchid.pactier2': 79.99,
        'net.orchid.pactier3': 199.99,
    }
#     mapping['google'] = {
#         'net.orchid.pactier1': 4.99,
#         'net.orchid.pactier2': 9.99,
#         'net.orchid.pactier3': 19.99,
#     }
    return mapping.get(store, {})

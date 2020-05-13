import boto3
from boto3.dynamodb.conditions import Key, Attr
import json

from util import *

# DB Connection
dynamodb = boto3.resource('dynamodb', endpoint_url="http://localhost:8000/")
pac_table: Table = dynamodb.Table('PAC')

# Retrieve a pot for the client receipt
def retrieve(event, context):
    seed_fake_data_if_needed(pac_table)
    receipt_hash = str(random.random())  # Simulate distinct receipts
    try:
        pac = __find_pac(price=499, receipt_hash=receipt_hash)
        return {"statusCode": 200, "body": json.dumps(pac)}
    except Exception as e:
        print("Failed to retrieve pac: ", e)

# Find a free pac for price
def __find_pac(price: int, receipt_hash: str) -> PAC:
    # Idempotency: Find previously dispensed pot by receipt hash
    reused = __find_existing_receipt(receipt_hash)
    if reused:
        return reused

    # Find available pot by price and status
    signer = __find_available_pot(price)

    # TODO: We really should have a transaction wrapped around the following receipt
    # TODO: and PAC grab operations but boto3 doesn't support this yet?

    # De-duplication: Insure only one thread is using the receipt
    __claim_receipt(receipt_hash)

    # Claim the pot, updating status and adding the receipt
    found = __claim_pot(signer, receipt_hash, price)

    print("Returning new pot: ", found['signer'])
    return found

def __find_existing_receipt(receipt_hash: str):
    # If the PAC has already been dispensed find it using the receipt index.
    # This query is eventually consistent.
    reused = pac_table.query(
        IndexName='PACReceipt',
        KeyConditionExpression=Key('receipt').eq(receipt_hash),
    )
    if reused['Count'] > 0:
        print("Returning duplicate request.", reused['signer'])
        return reused['Items'][0]

def __find_available_pot(price: int):
    # Find a random, available PAC for the specified price using the price_status index.
    # The index allows us to limit the results to exactly one row with no filtering required.
    # This query is eventually consistent.
    random_address = random_eth_address()
    key_condition = Key('price_status').eq("{}-{}".format(price, Status.Available.name))
    args = {'IndexName': "PACPriceStatus", 'Limit': 1}
    found = pac_table.query(
        **args, KeyConditionExpression=key_condition & Key('signer').gte(random_address))
    if found['Count'] == 0:
        found = pac_table.query(
            **args, KeyConditionExpression=key_condition & Key('signer').lt(random_address))
    if found['Count'] == 0:
        raise Exception("No PACs found")
    return found['Items'][0]['signer']

def __claim_receipt(receipt_hash: str):
    # Ensure that the receipt is only used once by conditionally writing a record
    # using the receipt hash as the id.  This will raise ConditionalCheckFailedException
    # if the condition fails.
    # Conditional writes are strongly consistent.
    # Note: A separate receipts table would be equivalent but this is a bit more "no-sql-y".
    pac_table.put_item(
        Item={'id': receipt_hash},
        ConditionExpression='attribute_not_exists(id)'
    )

def __claim_pot(signer: str, receipt_hash: str, price: int) -> PAC:
    # Claim the available PAC by conditionally updating its status and adding the receipt hash.
    # This will raise ConditionalCheckFailedException if the condition fails.
    # Conditional writes are strongly consistent.
    update = pac_table.update_item(
        Key={'id': signer},
        UpdateExpression="set #status = :s, price_status = :ps, receipt = :r",
        ExpressionAttributeNames={
            '#status': 'status',  # reserved name
        },
        ExpressionAttributeValues={
            ':s': Status.Dispensed.name,
            ':ps': "{}-{}".format(price, Status.Dispensed.name),
            ':r': receipt_hash,
        },
        ConditionExpression=Attr("status").eq(Status.Available.name),
        ReturnValues="ALL_NEW"
    )
    return update['Attributes']

# Hourly maintenance: Clean expired data from the table.
def hourly_maintenance(event, context):
    # Look at the updated time and remove expired funder and signer fields.
    ...



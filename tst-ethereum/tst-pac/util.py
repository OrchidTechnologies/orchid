import random
from enum import Enum
from datetime import datetime
from mypy_boto3_dynamodb.service_resource import Table

class Status(Enum):
    Pending = 1
    Available = 2
    Dispensed = 3

class PAC(object):
    ...

def random_eth_address():
    return '0x%040x' % random.randrange(16 ** 40)

# Generate some fake PAC data (and document the table structure)
def seed_fake_data_if_needed(pac_table: Table):
    if pac_table.scan()['Count'] != 0:
        return
    print("Seeding data")
    for _ in range(100):
        price = random.choice([499, 999, 1999])
        status = Status.Available
        funder = '0x1234'
        signer = random_eth_address()
        pac_table.put_item(Item={
            'id': signer,  # using signer as the unique id
            'price': str(price),
            'status': status.name,
            'price_status': "{}-{}".format(price, status.name),
            'funder': funder,
            'signer': signer,
            'updated': datetime.now().isoformat()
        })

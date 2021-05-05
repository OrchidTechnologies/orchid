import json
import logging
import os
import sys

from decimal import Decimal
from typing import Any, Dict, Optional, Tuple
from inapppy import GooglePlayVerifier, InAppPyValidationError



def verify(GOOGLE_BUNDLE_ID, GOOGLE_SERVICE_ACCOUNT_KEY_FILE, receipt):
    """
    Accepts receipt, validates in Google.
    """
    purchase_token = receipt['purchaseToken']
    product_sku = receipt['productId']
    verifier = GooglePlayVerifier(
        GOOGLE_BUNDLE_ID,
        GOOGLE_SERVICE_ACCOUNT_KEY_FILE,
    )
    response = {'valid': False, 'transactions': []}

    result = verifier.verify_with_result(
        purchase_token,
        product_sku,
        is_subscription=True
    )

    # result contains data
    raw_response = result.raw_response
    is_canceled = result.is_canceled
    is_expired = result.is_expired

    print(raw_response)

    return result


def main():
    print("googleplay_test")
    GOOGLE_SERVICE_ACCOUNT_KEY_FILE = {
        "type": "service_account",
        "project_id": "api-7153056272641709077-289311",
        "private_key_id": "b85cfc2dc2e1e97aafd2922ac228af270c8309e1",
        "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDwb0uc7MfeWPK1\nZlJwv5re7QoLN3A2YA3BMViCJY2H6jFp3zl5U2jcKqhdFTdds/ioCnlMhtAi1BHR\n23sY3dcDUJrLTRZU+KZiOLdZZFmHKZMfKj4+ljRX0WiML5OVjBZ8h9P5CYMYOrRA\n0RCvuT6b6/J4qGfU9LGPU36ES+hODUv0H1QMcM91Uv+Z33/uSWOOOCHso4YcJTa1\n1UUZKYma0t28w6USy2cWZOD/gDuy9NI/MIs+x0bN+NqSXPtTtwpfE+YitDvD+L1V\nkQUei+3VyRltfcA1gHraCeP1P0tzLmJEghhhPrsA/TcLXwAqCsJE8BKqNDP9c89N\n5JfBJgRrAgMBAAECggEAZz/sESIPfJjm9WZQ7dEiYSwa3ZE7k2YxUe7uaslUm3LD\nMItnQ4ZBqBZ7gamcQpWIKSWCTI4yMFqwolWl6ZpOfMJvDvH2Lpwu20wu1GkHF0eP\nwdjirP7U0IeBZX4C2zwy5dxwd2gRz2RaRuFg0I106QFseUscd7Ny0rFQyeBNDMLM\n2Z5Wpfm+/T1RhWjyZ0Pls/9Sq5SUUeA3oGjJWSfFg4BSC5A8zRSg/NMGyJVKI9ow\nBgLEuAeCyOf9ai7hB8HTJi4+pHPVwAczWuk00u/yOLpwCzVknN+XT7+ME6d6mvvM\nlbUalXwJ5w9ykeSGU+RNW/5L38wfN4y8s3t8VPetlQKBgQD/QckEZOe2ViFcZX4y\nx9aCgLipB71q4QW4VAArKyCdRxH6nKsxF2UtWmNRLt/4kJWaTMDlOr12ie/afSPm\ndFCZSCNvfVvhY2RTrVz+Qi8gYTb6K31cTo7DjM5JRItPvs+nBefAu+OkpbPYYcZ5\nk7aVZRsUFeN58pIs9f/BLu6ufwKBgQDxInb7f2rjzMGllMlv0rg8/B1izzFll9YK\noaEzSmkeb5STD7OXNE5XvR/zimJbEwO3T406NYBoTjvtX/pNSUpxwz7rjbHy+0eo\n43b0bQt556HY1oQyRUeJkA4aFyBO1wljz7olDBsWVBHx+RUZ7J+nUhfOuk0f3mkI\nsAs52jxMFQKBgQDo8n9h7DhudaIScWk/LJK+HHzpfW/G9z7CHp7cxooIHpDw1kOB\nFKm4PxH+R7oMXN66pysux3GamX10NtopeaMIkAYOvCe6xHsNxlvkij/5295RZpkM\nQYEWQw0LXmuIxkk5UzFR+eZhHvvHEEwSLdTl+BRDO0qSwuXV9FaIVa1rPwKBgQDV\njsqFrrFCEwOl3AITETKugDKeYhXDfhfIzqDvxgUXOYcCP7O0RFTmC8+SZ4r4UfzG\niqPvW5bfyfn1Hz2U2UYfPuYoxBNHuRgcEWg2zaSOUIDchBAMXaMfx/9VSAoLCRN9\n3GllijUrL0W9YfY4QYKcM252XjUT9mxbj15B3G/uiQKBgCNS3PBxkavNbzgKSRgo\nIiU28BQLFYCycS/c1b/ILlE6HlVesxaURJZGLacEWqeMvK/d4nSrlTx6CN4q7Hua\nY1OskZI0dcNpBamq7Qi89YUgiQkpMkZZcp/W8QfaQ6uVbTwyOSqM1ow2aBngl8zf\nsPjahsVpjppmN7/m5upwhuPh\n-----END PRIVATE KEY-----\n",
        "client_email": "pac-161@api-7153056272641709077-289311.iam.gserviceaccount.com",
        "client_id": "101794652367801825194",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/pac-161%40api-7153056272641709077-289311.iam.gserviceaccount.com"
    }
    receipt = {
        "orderId": "GPA.3386-4376-5444-11040",
        "packageName": "net.pat.myreviewsample",
        "productId": "net.pat.testproduct1",
        "purchaseTime": 1619731249001,
        "purchaseState": 0,
        "purchaseToken": "ibahgijjmdcmapcbgogolhhk.AO-J1Ozroym2HnVURDiA61pCsKdbSSe_w-pUMHPCtPaSZHTcmLbnTpQ4WY-4Ue-3bHRO6WBr0YAsEjILIzQ3m6oSt88AiRPzsxwf_I8qltuIXZoj1sBsnDA",
        "acknowledged": False
    }
    verify('net.pat.myreviewsample', GOOGLE_SERVICE_ACCOUNT_KEY_FILE, receipt)

if __name__ == "__main__":
    main()


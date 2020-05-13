
This is an example alternative schema structure for the PAC server.

Some advantages are:
- Single table
- Clearly defined pot status
- Uses indexes to find pots by status, price, and receipt.
- No race condition on grabbing pots
- Reads only one PAC during the random search 

Issues:
- There is a transaction that should wrap two writes here but the boto3 Python API doesn't support them yet.



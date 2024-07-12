import asyncio
import websockets
import functools
import json
import hashlib
import random

import web3
import ethereum

import billing
import jobs
import ticket
import lottery
import os
import traceback
import sys

uint256 = pow(2,256) - 1
uint64 = pow(2,64) - 1
wei = pow(10, 18)

prices = {
    'invoice': 0.0001,
    'payment': 0.0001,
    'connection': 0.0001,
    'error': 0.0001,
    'job': 0.01,
    'complete': 0.001,
    'started': 0.0001
}

lottery_address = '0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82'

internal_messages = ['charge']
disconnect_threshold = -25

def invoice(amt, commit, recipient):
   return json.dumps({'type': 'invoice', 'amount': int(pow(10,18) * amt), 'commit': '0x' + str(commit), 'recipient': recipient})

def process_tickets(tix, recip, reveal, commit, lotto, key):
    try:
#        print(f'Got ticket: {tix[0]}')
        tk = ticket.Ticket.deserialize_ticket(tix[0], reveal, commit, recip, lotaddr=lottery_address)
#        tk.print_ticket()
        if tk.is_winner(reveal):
            hash = lotto.claim_ticket(tk, recip, key, reveal)
            print(f"Claim tx: {hash}")
            reveal, commit = new_reveal()
        tk.print_ticket()
        return tk.value() / wei, reveal, commit
    except Exception:
        print('process_ticket() failed')
        exc_type, exc_value, exc_traceback = sys.exc_info()
        traceback.print_exception(exc_type, exc_value, exc_traceback, limit=20, file=sys.stdout)
    return 0, reveal, commit

async def send_error(ws, code):
    await ws.send(json.dumps({'type': 'error', 'code': code}))

def new_reveal():
    num = hex(random.randrange(pow(2,256)))[2:]
    reveal = '0x' + num[2:].zfill(64)
#    print(f'new_reveal: {reveal}')
    try:
        commit = ethereum.utils.sha3(bytes.fromhex(reveal[2:])).hex()
    except:
        exc_type, exc_value, exc_traceback = sys.exc_info()
        traceback.print_exception(exc_type, exc_value, exc_traceback, limit=20, file=sys.stdout)
    return reveal, commit

async def session(websocket, bills=None, job=None, recipient='0x0', key=''):
    print("New client connection")
    reserve_price = 0.00006
    lotto = lottery.Lottery()
    w3 = web3.Web3(web3.Web3.HTTPProvider('https://rpc.gnosischain.com/'))
    lotto.init_contract(w3)
    id = websocket.id
    bills.debit(id, type='invoice')
    send_queue, recv_queue = job.get_queues(id)
    reveal, commit = new_reveal()
    await websocket.send(invoice(2 * bills.min_balance(), commit, recipient))
    sources = [websocket.recv, recv_queue.get]
    tasks = [None, None]
    while True:
        if bills.balance(id) < disconnect_threshold:
            await websocket.close(reason='Balance too low')
            break
        try:
            for i in range(2):
                if tasks[i] is None:
                    tasks[i] = asyncio.create_task(sources[i]())
            done, pending = await asyncio.wait(tasks, return_when = asyncio.FIRST_COMPLETED)
            for i, task in enumerate(tasks):
                if task in done:
                    tasks[i] = None
            for task in done:
                message_ = task.result()
                message = json.loads(message_)
                if message['type'] == 'payment':
                    try:
                        amt, reveal, commit = process_tickets(message['tickets'], recipient, reveal, commit, lotto, key)
                        print(f'Got ticket worth {amt}')
                        bills.credit(id, amount=amt)
                    except:
                        print('outer failure in processing payment')
                        exc_type, exc_value, exc_traceback = sys.exc_info()
                        traceback.print_tb(exc_traceback, limit=1, file=sys.stdout)
                        bills.debit(id, type='error')
                        await send_error(websocket, -6001)
                if bills.balance(id) < bills.min_balance():
                    bills.debit(id, type='invoice')
                    await websocket.send(invoice(2 * bills.min_balance() - bills.balance(id), commit, recipient))
                if message['type'] not in internal_messages:
                    bills.debit(id, type=message['type'])
                if message['type'] == 'job':
                    jid = hashlib.sha256(bytes(message['prompt'], 'utf-8')).hexdigest()
                    if reserve_price != 0 and float(message['bid']) < reserve_price:
                       await websocket.send(json.dumps({'type': 'bid_low'}))
                       continue
                    await job.add_job(id, message['bid'], 
                                      {'id': jid, 'prompt': message['prompt']})
                if message['type'] == 'charge':
                    try:
                        bills.debit(id, amount=message['amount'])
                        await send_queue.put(True)
                    except:
                        print('exception in charge handler')
                if message['type'] == 'complete':
                    await websocket.send(json.dumps({'type': 'job_complete', "output": message['response'],
                                                     'model': message['model'], 'reason': message['reason'],
                                                     'usage': message['usage']}))
                if message['type'] == 'started':
                    await websocket.send(json.dumps({'type': 'job_started'}))
        except (websockets.exceptions.ConnectionClosedOK, websockets.exceptions.ConnectionClosedError):
            print('connection closed')
            break
        

async def main(model, url, bind_addr, bind_port, recipient_key, llmkey, llmparams, api):
    recipient_addr = web3.Account.from_key(recipient_key).address
    bills = billing.Billing(prices)
    job = jobs.jobs(model, url, llmkey, llmparams, api)
    print("\n*****")
    print(f"* Server starting up at {bind_addr} {bind_port}")
    print(f"* Connecting to back end at {url}")
    print(f"* With model {model}")
    print(f"* Using wallet at {recipient_addr}")
    print("******\n\n")
    async with websockets.serve(functools.partial(session, bills=bills, job=job, 
                                                  recipient=recipient_addr, key=recipient_key),
                                bind_addr, bind_port):
        await asyncio.wait([asyncio.create_task(job.process_jobs())])

if __name__ == "__main__":
    bind_addr = os.environ['ORCHID_GENAI_ADDR']
    bind_port = os.environ['ORCHID_GENAI_PORT']
    recipient_key = os.environ['ORCHID_GENAI_RECIPIENT_KEY']
    url = os.environ['ORCHID_GENAI_LLM_URL']
    model = os.environ['ORCHID_GENAI_LLM_MODEL']
    api = 'openai' if 'ORCHID_GENAI_API_TYPE' not in os.environ else os.environ['ORCHID_GENAI_API_TYPE']
    llmkey = None if 'ORCHID_GENAI_LLM_AUTH_KEY' not in os.environ else os.environ['ORCHID_GENAI_LLM_AUTH_KEY']
    llmparams = {}
    if 'ORCHID_GENAI_LLM_PARAMS' in os.environ:
       llmparams = json.loads(os.environ['ORCHID_GENAI_LLM_PARAMS'])
    asyncio.run(main(model, url, bind_addr, bind_port, recipient_key, llmkey, llmparams, api))    

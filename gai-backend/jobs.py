import asyncio
import random
import datetime
import json
import requests

import websockets

class jobs:
    def __init__(self, model, url, llmkey, llmparams):
        self.queue = asyncio.PriorityQueue()
        self.sessions = {}
        self.model = model
        self.url = url
        self.llmkey = llmkey
        self.llmparams = llmparams

    def get_queues(self, id):
        squeue = asyncio.Queue(maxsize=10)
        rqueue = asyncio.Queue(maxsize=10)
        self.sessions[id] = {'send': squeue, 'recv': rqueue}
        return [rqueue, squeue]

    async def add_job(self, id, bid, job):
        print(f'add_job({id}, {bid}, {job})')
        priority = 0.1
        await self.queue.put((priority, [id, bid, job]))
        
    async def process_jobs(self):
        while True:
            priority, job_params = await self.queue.get()
            id, bid, job = job_params
            await self.sessions[id]['send'].put(json.dumps({'type': 'started'}))
            result = ""
            data = {'model': self.model, 'messages': [{'role': 'user', 'content': job['prompt']}]}
            data = {**data, **self.llmparams}
            headers =  {"Content-Type": "application/json"}
            if not self.llmkey is None:
              headers["Authorization"] = f"Bearer {self.llmkey}"            
            r = requests.post(self.url, data=json.dumps(data), headers=headers)
            result = r.json()
            if result['object'] != 'chat.completion':
              print('*** process_jobs: Error from llm')
              print(f"from job: {job_params}")
              print(result)
              continue
            response = result['choices'][0]['message']['content']
            model = result['model']
            reason = result['choices'][0]['finish_reason']
            usage = result['usage']
            await self.sessions[id]['send'].put(json.dumps({'type': 'complete', 'response': response,
                                                            'model': model, 'reason': reason,
                                                            'usage': usage}))
                

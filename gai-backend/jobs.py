import asyncio
import random
import datetime
import json
import requests

import websockets


class jobs:
    def __init__(self, model, url, llmkey, llmparams, api='openai'):
        self.queue = asyncio.PriorityQueue()
        self.sessions = {}
        self.model = model
        self.url = url
        self.llmkey = llmkey
        self.llmparams = llmparams
        self.api = api

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
        print(f"Starting process_jobs() with api: {self.api}")
        while True:
            priority, job_params = await self.queue.get()
            id, bid, job = job_params
            await self.sessions[id]['send'].put(json.dumps({'type': 'started'}))
            response, reason, usage = apis[self.api](job['prompt'], self.llmparams, self.model, self.url, self.llmkey)
            if response == None:
                continue
            await self.sessions[id]['send'].put(json.dumps({'type': 'complete', 'response': response,
                                                            'model': self.model, 'reason': reason,
                                                            'usage': usage}))


def query_openai(prompt, params, model, url, llmkey):
    result = ""
    data = {'model': model, 'messages': [{'role': 'user', 'content': prompt}]}
    data = {**data, **params}
    headers =  {"Content-Type": "application/json"}
    if not llmkey is None:
      headers["Authorization"] = f"Bearer {llmkey}"            
    r = requests.post(url, data=json.dumps(data), headers=headers)
    result = r.json()
    if result['object'] != 'chat.completion':
      print('*** process_jobs: Error from llm')
      print(f"from job: {job_params}")
      print(result)
      return None, None, None
    response = result['choices'][0]['message']['content']
    model = result['model']
    reason = result['choices'][0]['finish_reason']
    usage = result['usage']
    return response, reason, usage

def query_gemini(prompt, params, model, url, llmkey):
    data = {'contents': [{'parts': [{'text': prompt}]}]}
    data = {**data, **params}
    print(f"query_gemini(): data: {data}")
    headers =  {"Content-Type": "application/json"}
    url_ = url + f"?key={llmkey}"
    r = requests.post(url_, data=json.dumps(data), headers=headers)
    print(r.json())
    result = r.json()['candidates'][0]
    response = result['content']['parts'][0]['text']
    reason = result['finishReason']
    usage = 0
    return response, reason, usage

def query_anthropic(prompt, params, model, url, llmkey):
    data = {'model': model, 'messages': [{'role': 'user', 'content': prompt}]}
    data = {**data, **params}
    headers =  {"Content-Type": "application/json",
                "anthropic-version": "2023-06-01"}
    if not llmkey is None:
      headers["x-api-key"] = llmkey
    r = requests.post(url, data=json.dumps(data), headers=headers)
    result = r.json()
    if 'content' not in result:
      print('*** process_jobs: Error from llm')
      print(f"from job: {job_params}")
      print(result)
      return None, None, None
    response = result['content'][0]['text']
    model = result['model']
    reason = result['stop_reason']
    usage = result['usage']
    return response, reason, usage


apis = {'openai': query_openai, 'gemini': query_gemini, 'anthropic': query_anthropic}

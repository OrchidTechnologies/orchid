FROM python:3.8.5

ENV TINI_VERSION="v0.19.0"

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN pip install -U \
    pip \
    setuptools \
    wheel

WORKDIR /project

COPY requirements.txt ./
COPY run.sh /
RUN chmod +x /run.sh
COPY *.py ./

RUN pip install -r requirements.txt

COPY . .

RUN useradd -m -r gai && chown gai /project

USER gai

ENV ORCHID_GENAI_ADDR=127.0.0.1
ENV ORCHID_GENAI_PORT=8001
ENV ORCHID_GENAI_RECIPIENT_KEY=""
ENV ORCHID_GENAI_LLM_PARAMS="{\"temperature\": 0.7, \"top_p\": 1, \"max_tokens\": 3000, \"stream\": false, \"safe_prompt\": false, \"random_seed\": null}"
ENV ORCHID_GENAI_LLM_MODEL="Mistral-7B-Instruct-v0.2/"
ENV ORCHID_GENAI_LLM_URL="http://localhost:8000/v1/chat/completions/"

ENTRYPOINT ["/tini", "--", "/run.sh"]
EXPOSE 8001 8001

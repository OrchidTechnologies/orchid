FROM python:3.8.5

ENV TINI_VERSION="v0.19.0"
WORKDIR /gai-backend

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini ./tini
RUN chmod +x ./tini

RUN pip install -U \
    pip \
    setuptools \
    wheel


COPY requirements.txt ./
COPY run.sh ./
RUN chmod +x ./run.sh
COPY *.py ./

RUN pip install -r requirements.txt

#COPY . .

RUN useradd -m -r gai && chown -R gai /gai-backend
USER gai

ENV ORCHID_GENAI_ADDR=0.0.0.0
ENV ORCHID_GENAI_PORT=8000
ENV ORCHID_GENAI_LLM_MODEL="open-mixtral-8x22b"
#ENV ORCHID_GENAI_RECIPIENT_KEY=""
#ENV ORCHID_GENAI_LLM_AUTH_KEY=""
ENV ORCHID_GENAI_LLM_URL="https://api.mistral.ai/v1/chat/completions"
#ENV ORCHID_GENAI_LLM_PARAMS="{}"

ENTRYPOINT ["./tini", "--", "./run.sh"]
EXPOSE 8000 8000

HEALTHCHECK CMD bash -c "exec 6<> /dev/tcp/localhost/8000" 

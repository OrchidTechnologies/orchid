FROM python:3.11-bookworm

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
COPY lottery0.abi ./
COPY lottery1.abi ./
COPY config.json ./

RUN chmod +x ./run.sh
COPY *.py ./
copy Youtube-MCP-Local-main ./Youtube-MCP

RUN pip install -r requirements.txt
RUN pip install mcp 
RUN pip install colorlog

RUN NODE_VERSION="$(curl -fsSL https://nodejs.org/dist/latest/SHASUMS256.txt | head -n1 | awk '{ print $2}' | awk -F - '{ print $2}')" \
  ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    arm64) ARCH='arm64';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && for key in $(curl -sL https://raw.githubusercontent.com/nodejs/docker-node/HEAD/keys/node.keys); do \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
  && /usr/local/bin/npm install -g npm@11.2.0 \
  && /usr/local/bin/npm install exa-mcp-server && pip install uv

RUN useradd -m -r gai && chown -R gai /gai-backend
USER gai

WORKDIR /gai-backend/Youtube-MCP
RUN /usr/local/bin/uv sync

WORKDIR /gai-backend

ENTRYPOINT ["./tini", "--", "./run.sh"]
EXPOSE 8010 8010
EXPOSE 8000 8000

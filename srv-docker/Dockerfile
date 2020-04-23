FROM ubuntu:bionic
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install git-core

WORKDIR /usr/src
RUN git clone https://github.com/OrchidTechnologies/orchid.git && cd orchid && git checkout githubci && git submodule update --init --recursive --jobs 3

WORKDIR orchid
RUN env/setup-dkr.sh make -j3 -C srv-shared install debug=crossndk usr=/usr && rm -rf /usr/src/orchid /usr/local/lib/android


FROM ubuntu:bionic
COPY --from=0 /usr/sbin/orchidd /usr/sbin/

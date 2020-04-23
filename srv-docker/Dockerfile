FROM ubuntu:bionic

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get -y install git-core

WORKDIR /usr/src
RUN git clone https://github.com/OrchidTechnologies/orchid.git
WORKDIR orchid
RUN git checkout githubci

RUN git submodule update --init --recursive --jobs 3

RUN env/setup-dkr.sh make -j3 -C srv-shared install debug=crossndk usr=/usr

WORKDIR ..
RUN rm -rf orchid
RUN cp -a srv-shared/out-lnx/x86_64/orchidd /mnt/

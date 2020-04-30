FROM ubuntu:eoan
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install git-core

ARG GIT_REPOSITORY=https://github.com/OrchidTechnologies/orchid.git
ARG GIT_COMMIT=master

WORKDIR /usr/src
RUN git clone $GIT_REPOSITORY && cd * && git checkout $GIT_COMMIT && env/submodule.sh --jobs 3

WORKDIR orchid
RUN env/setup-dkr.sh make -j3 -C srv-shared install debug=crossndk usr=/usr && rm -rf /usr/src/orchid /usr/local/lib/android


FROM ubuntu:bionic
COPY --from=0 /usr/sbin/orchidd /usr/sbin/

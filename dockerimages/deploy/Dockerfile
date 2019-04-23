# Minimal docker container to build project
# Image: rabits/qt:5.9-desktop

FROM ubuntu:16.04
MAINTAINER Patwie <mail@patwie.com>

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update && apt-get -qq dist-upgrade && apt-get install -qq -y --no-install-recommends \
    git \
    curl \
    ssh \
    rsync \
    && apt-get -qq clean


RUN mkdir /root/.ssh
COPY id_rsa /root/.ssh/id_rsa
COPY config /root/.ssh/config
RUN touch /root/.ssh/known_hosts
# COPY known_hosts /root/.ssh/known_hosts
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

COPY publish.sh /opt/publish.sh
RUN chmod +x /opt/publish.sh

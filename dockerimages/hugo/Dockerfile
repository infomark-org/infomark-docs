FROM ubuntu:16.04 as hugo-base
ENV VERSION 0.55.2
RUN apt-get update

RUN apt-get install curl -yy
RUN curl -L https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_extended_${VERSION}_Linux-64bit.tar.gz | tar -xz  \
    && cp hugo /usr/bin/hugo \
    && hugo version
WORKDIR /drone/src
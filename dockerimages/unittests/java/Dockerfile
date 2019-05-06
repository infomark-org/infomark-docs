FROM ubuntu:18.04

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  sudo \
  build-essential \
  unzip \
  openjdk-11-jdk \
  ant \
  python3 \
  ant-optional \
  && rm -rf /var/lib/apt/lists/*


ADD setup/ /app/setup/
ADD run.sh /app/run.sh
RUN chmod -R 700 /app

RUN /app/setup/init.sh

ENTRYPOINT ["/app/run.sh"]


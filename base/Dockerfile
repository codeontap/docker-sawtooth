FROM ubuntu:xenial

RUN apt-get update && apt-get install -y gnupg software-properties-common && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 44FC67F19B2466EA && \
    add-apt-repository 'deb [arch=amd64] http://repo.sawtooth.me/ubuntu/nightly xenial universe' && \
    apt-get update && apt-get install -y sawtooth python3-sawtooth-poet-sgx

ADD ./src_global/telegraf.conf /etc/telegraf/telegraf.conf

RUN mkdir -p /opt/sawtooth

CMD [ "/bin/bash" ]

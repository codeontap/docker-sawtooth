FROM codeontap/sawtooth-base:latest

RUN mkdir -p /opt/sawtooth/key && \
    apt-get update && \
    apt-get install -y apt-transport-https curl && \
    curl -sL https://repos.influxdata.com/influxdb.key | apt-key add - && \
    apt-add-repository "deb https://repos.influxdata.com/ubuntu xenial stable" && \
    apt-get update && \
    apt-get install -o Dpkg::Options::="--force-confold" -y telegraf

ADD ./start.sh /opt/sawtooth/start.sh
ADD ./poet-settings.sh /opt/sawtooth/poet-settings.sh
ADD ./validator.toml /etc/sawtooth/validator.toml
ADD ./client.cnf /opt/sawtooth/key/client.cnf
ADD ./pubkey.pem /opt/sawtooth/key/pubkey.pem

RUN chmod 755 /opt/sawtooth/start.sh && chmod 755 /opt/sawtooth/poet-settings.sh

CMD [ "/opt/sawtooth/start.sh" ]

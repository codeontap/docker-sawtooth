FROM aaronnicoli/sawtooth-base:latest


RUN apt-get update && \
    apt-get install -y apt-transport-https curl && \
    curl -sL https://repos.influxdata.com/influxdb.key | apt-key add - && \
    apt-add-repository "deb https://repos.influxdata.com/ubuntu xenial stable" && \
    apt-get update && \
    apt-get install -y telegraf

ADD rest-api/start.sh /opt/sawtooth/start.sh
ADD rest-api/rest_api.toml /etc/sawtooth/rest_api.toml
ADD src_global/telegraf.conf /etc/telegraf/telegraf.conf

RUN chmod 755 /opt/sawtooth/start.sh

CMD [ "/opt/sawtooth/start.sh" ]

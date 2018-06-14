#!/bin/bash

OPENTSDB_SETTINGS=""
if [ "${OPENTSDB_URL}" != "" -a "${OPENTSDB_DB}" != "" -a "${OPENTSDB_USERNAME}" != "" -a "${OPENTSDB_PASSWORD}" != "" ] ; then
  OPENTSDB_SETTINGS="--opentsdb-url ${OPENTSDB_URL} --opentsdb-db ${OPENTSDB_DB}"
  sed -i "s/# opentsdb_username = \"\"/opentsdb_username = \"${OPENTSDB_USERNAME}\"/g" /etc/sawtooth/rest_api.toml
  sed -i "s/# opentsdb_password = \"\"/opentsdb_password = \"${OPENTSDB_PASSWORD}\"/g" /etc/sawtooth/rest_api.toml
  # Run the telegraf service
  OPENTSDB_URL_NO_PREFIX="${OPENTSDB_URL##http://}"
  sed -i "s/# urls = \[\"influxdb-url\"\]/urls = \[\"http\:\/\/${OPENTSDB_URL_NO_PREFIX}\"\]/g" /etc/telegraf/telegraf.conf
  sed -i "s/# database = \"telegraf\"/database = \"${OPENTSDB_DB}\"/g" /etc/telegraf/telegraf.conf
  sed -i "s/# username = \"telegraf\"/username = \"${OPENTSDB_USERNAME}\"/g" /etc/telegraf/telegraf.conf
  sed -i "s/# password = \"metricsmetricsmetricsmetrics\"/password = \"${OPENTSDB_PASSWORD}\"/g" /etc/telegraf/telegraf.conf
  telegraf --config /etc/telegraf/telegraf.conf &
fi

sawtooth-rest-api -C tcp://${VALIDATOR_ADDRESS_W_PORT} --bind 0.0.0.0:8008 ${OPENTSDB_SETTINGS}

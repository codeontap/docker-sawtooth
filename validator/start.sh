#!/bin/bash

SAWTOOTHBASE="/etc/sawtooth"
KEYSDIR="${SAWTOOTHBASE}/keys"
BATCHDIR="${SAWTOOTHBASE}/batch"
KEYNAME="validator"

CMD_KEYGEN="sawtooth keygen --key-dir ${KEYSDIR}"

if [ ! -d "${KEYSDIR}" ] ; then
    mkdir -p ${KEYSDIR}
fi
if [ ! -f "${KEYSDIR}/${KEYNAME}.priv" ] ; then
    $CMD_KEYGEN && \
    mv ${KEYSDIR}/root.priv ${KEYSDIR}/${KEYNAME}.priv && \
    mv ${KEYSDIR}/root.pub ${KEYSDIR}/${KEYNAME}.pub
fi

if [ ! -f "${KEYSDIR}/client.pfx" ] ; then
    openssl genrsa -out ${KEYSDIR}/client.key 2048
    openssl req -key ${KEYSDIR}/client.key -new -out ${KEYSDIR}/client.req -subj "/C=AU/ST=ACT/L=Canberra/O=GoSource/OU=SawtoothValidator/CN=*"
    openssl x509 -req -days 730 -in ${KEYSDIR}/client.req -signkey ${KEYSDIR}/client.key -out ${KEYSDIR}/client.crt -extfile /opt/sawtooth/key/client.cnf -extensions ssl_client
    openssl pkcs12 -export -out ${KEYSDIR}/client.pfx -inkey ${KEYSDIR}/client.key -in ${KEYSDIR}/client.crt -passout pass:
fi

rm -f /opt/sawtooth/key/validator.pub
rm -f /opt/sawtooth/key/client.pem
cp ${KEYSDIR}/${KEYNAME}.pub /opt/sawtooth/key/validator.pub
#cp ${KEYSDIR}/client.crt /opt/sawtooth/key/client.pem - Temp fix for borken cert AN 20180515
cp /opt/sawtooth/key/pubkey.pem /opt/sawtooth/key/client.pem

OPENTSDB_SETTINGS=""
if [ "${OPENTSDB_URL}" != "" -a "${OPENTSDB_DB}" != "" -a "${OPENTSDB_USERNAME}" != "" -a "${OPENTSDB_PASSWORD}" != "" ] ; then
  OPENTSDB_SETTINGS="--opentsdb-url ${OPENTSDB_URL} --opentsdb-db ${OPENTSDB_DB}"
  sed -i "s/# opentsdb_username = \"\"/opentsdb_username = \"${OPENTSDB_USERNAME}\"/g" /etc/sawtooth/validator.toml
  sed -i "s/# opentsdb_password = \"\"/opentsdb_password = \"${OPENTSDB_PASSWORD}\"/g" /etc/sawtooth/validator.toml
  # Run the telegraf service
  OPENTSDB_URL_NO_PREFIX="${OPENTSDB_URL##http://}"
  sed -i "s/# urls = \[\"influxdb-url\"\]/urls = \[\"http\:\/\/${OPENTSDB_URL_NO_PREFIX}\"\]/g" /etc/telegraf/telegraf.conf
  sed -i "s/# database = \"telegraf\"/database = \"${OPENTSDB_DB}\"/g" /etc/telegraf/telegraf.conf
  sed -i "s/# username = \"telegraf\"/username = \"${OPENTSDB_USERNAME}\"/g" /etc/telegraf/telegraf.conf
  sed -i "s/# password = \"metricsmetricsmetricsmetrics\"/password = \"${OPENTSDB_PASSWORD}\"/g" /etc/telegraf/telegraf.conf
  telegraf --config /etc/telegraf/telegraf.conf &
fi


# IF DOES NOT ALREADY HAVE A GENESIS BLOCK
if [ "${SEED_ADDRESS_W_PORT}" != "" ] ; then
	mkdir -p ${BATCHDIR}

    sawset proposal create -k ${KEYSDIR}/${KEYNAME}.priv \
        sawtooth.consensus.algorithm=poet \
        sawtooth.poet.report_public_key_pem="$(cat /opt/sawtooth/key/client.pem)" \
        sawtooth.poet.valid_enclave_measurements=$(poet enclave measurement) \
        sawtooth.poet.valid_enclave_basenames=$(poet enclave basename) \
        sawtooth.identity.allowed_keys="$(cat /opt/sawtooth/key/validator.pub)" \
        -o ${BATCHDIR}/config.batch

    poet registration create -k ${KEYSDIR}/${KEYNAME}.priv -o ${BATCHDIR}/poet.batch

    sawset proposal create -k ${KEYSDIR}/${KEYNAME}.priv \
        $(/opt/sawtooth/poet-settings.sh) \
        -o ${BATCHDIR}/poet-settings.batch

   sawtooth-validator -v \
        --bind network:tcp://0.0.0.0:8800 \
        --bind component:tcp://0.0.0.0:4004 \
        --peering dynamic \
        --endpoint tcp://${ENDPOINT_ADDRESS_W_PORT} \
        --seeds tcp://${SEED_ADDRESS_W_PORT} \
        --scheduler serial \
        --network-auth trust ${OPENTSDB_SETTINGS}
elif [ -d "${BATCHDIR}" ] ; then
    sawtooth-validator -v \
        --bind network:tcp://0.0.0.0:8800 \
        --bind component:tcp://0.0.0.0:4004 \
        --peering dynamic \
        --endpoint tcp://${ENDPOINT_ADDRESS_W_PORT} \
        --scheduler serial \
        --network-auth trust ${OPENTSDB_SETTINGS}
else
    mkdir -p ${BATCHDIR}
    sawset genesis --key ${KEYSDIR}/${KEYNAME}.priv --output ${BATCHDIR}/config-genesis.batch

    sawset proposal create -k ${KEYSDIR}/${KEYNAME}.priv \
        sawtooth.consensus.algorithm=poet \
        sawtooth.poet.report_public_key_pem="$(cat /opt/sawtooth/key/client.pem)" \
        sawtooth.poet.valid_enclave_measurements=$(poet enclave measurement) \
        sawtooth.poet.valid_enclave_basenames=$(poet enclave basename) \
        sawtooth.identity.allowed_keys="$(cat /opt/sawtooth/key/validator.pub)" \
        -o ${BATCHDIR}/config.batch

    poet registration create -k ${KEYSDIR}/${KEYNAME}.priv -o ${BATCHDIR}/poet.batch

    sawset proposal create -k ${KEYSDIR}/${KEYNAME}.priv \
        $(/opt/sawtooth/poet-settings.sh) \
        -o ${BATCHDIR}/poet-settings.batch

    sawadm genesis \
        ${BATCHDIR}/config-genesis.batch \
        ${BATCHDIR}/config.batch \
        ${BATCHDIR}/poet.batch \
        ${BATCHDIR}/poet-settings.batch

    sawtooth-validator -v \
        --bind network:tcp://0.0.0.0:8800 \
        --bind component:tcp://0.0.0.0:4004 \
        --peering dynamic \
        --endpoint tcp://${ENDPOINT_ADDRESS_W_PORT} \
        --scheduler serial \
        --network-auth trust ${OPENTSDB_SETTINGS}
fi

FROM codeontap/sawtooth-base:latest

RUN apt-get update && apt-get install -y python3-sawtooth-identity && apt-get clean

CMD [ "sh", "-c", "identity-tp -v -C tcp://${VALIDATOR_ADDRESS_W_PORT}" ]

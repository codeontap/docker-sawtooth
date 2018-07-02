#!/bin/bash


IMAGE_REGISTRY="codeontap/"


IMAGES=( "base" "validator" "settings-tp" "poet-validator-registry" "rest-api" "identity-tp" )

CURDIR=`dirname "$0"`


for i in "${IMAGES[@]}"
do
  docker build --rm -t ${IMAGE_REGISTRY}sawtooth-${i}:latest -f ${CURDIR}/${i}/Dockerfile ${CURDIR}/${i}
done

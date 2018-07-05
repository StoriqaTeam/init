#!/bin/bash

set -ux

kc_host=${1-$KC_HOST}
kc_port=${5-$KC_PORT}

sr_host=${4-$SR_HOST}
sr_port=${8-$SR_PORT}

# Checking availability:
/app/wait_for_it.sh ${kc_host}:${kc_port} || sleep 30
/app/wait_for_it.sh ${sr_host}:${sr_port} || sleep 30

# We do not want Schema Registry to maintain any compatibility
curl -si -XPUT -H "Content-Type: application/json" ${sr_host}:${sr_port}/config -d '{"compatibility": "NONE"}'

echo "Initializing connectors"

for connector in stores-pg-source stores-es-sink
do
    connector_json=`envsubst < ${connector}.json`
    curl -sf ${kc_host}:${kc_port}/connectors/${connector} \
      || curl -si \
        -X POST \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        ${kc_host}:${kc_port}/connectors \
        --data-binary "$connector_json"
done

exit 0

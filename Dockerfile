FROM alpine

RUN apk update
RUN apk add bash
RUN apk add curl

COPY . /app

ENV DB_HOST=stores-pg-postgresql
ENV ES_HOST=elasticsearch
ENV KC_HOST=kafka-connect

ENV DB_PORT=5432
ENV ES_PORT=9200
ENV KC_PORT=8083

ENV DB_USER=stores
ENV DB_PASS=stores
ENV DB=stores

ENTRYPOINT /app/init_connectors.sh


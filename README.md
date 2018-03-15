# init
Performs pre-release tasks

Small image to populate kafka-connect with connectors and ES with indices.
This image needs to connect PostgreSQL, ElasticSearch and Kafka Connect. Connection
parameters can be difined with environment variables:

```
DB_HOST=stores-pg-postgresql
ES_HOST=elasticsearch
KC_HOST=kakfa-connect

DB_PORT=5432
ES_PORT=9200
KC_PORT=8083

DB_USER=stores
DB_PASS=stores
DB=stores
```

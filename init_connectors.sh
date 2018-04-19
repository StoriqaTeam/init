#!/bin/bash

set -u

kc_host=${1-$KC_HOST}
pg_host=${2-$DB_HOST}
es_host=${3-$ES_HOST}
sr_host=${4-$SR_HOST}

kc_port=${5-$KC_PORT}
pg_port=${6-$DB_PORT}
es_port=${7-$ES_PORT}
sr_port=${8-$SR_PORT}

pg_user="${7-$DB_USER}"
pg_pass="${8-$DB_PASS}"
pg_db="${9-$DB}"

debezium_json='{
  "name": "stores-pg-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.user": '\"$pg_user\"',
    "database.dbname": '\"$pg_db\"',
    "database.hostname": '\"$pg_host\"',
    "database.password": '\"$pg_pass\"',
    "name": "stores-pg-connector",
    "database.server.name": '\"$pg_host\"',
    "database.port": '\"$pg_port\"'
  }
}'

stores_json='{
  "name": "stores-connector",
  "config": {
    "connector.class": "com.skynyrd.kafka.ElasticSinkConnector",
    "topics": "stores-pg",
    "tasks.max": "1",
    "type.name": "_doc",
    "elastic.url": '\"$es_host\"',
    "elastic.port": '\"$es_port\"'
  }
}'

es_stores_json='
{
      "mappings": {
         "_doc": {
            "properties": {
               "name": {
                  "type": "nested",
                  "properties": {
                     "lang": {
                        "type": "text"
                     },
                     "text": {
                        "type": "text"
                     }
                  }
               },
               "user_id": {
                  "type": "integer"
               },
               "rating": {
                  "type": "double"
               },
               "country": {
                  "type": "text"
               },
               "id": {
                  "type": "integer"
               },
               "product_categories": {
                  "type": "nested",
                  "properties": {
                     "category_id": {
                        "type": "integer"
                     },
                     "count": {
                        "type": "integer"
                     }
                  }
               },
               "suggest" : {
                   "type" : "completion"
               }
            }
         }
      }
}
'

es_products_json='
{
      "mappings": {
         "_doc": {
            "properties": {
               "name": {
                  "type": "nested",
                  "properties": {
                     "lang": {
                        "type": "text"
                     },
                     "text": {
                        "type": "text"
                     }
                  }
               },
               "short_description": {
                  "type": "nested",
                  "properties": {
                     "lang": {
                        "type": "text"
                     },
                     "text": {
                        "type": "text"
                     }
                  }
               },
               "long_description": {
                  "type": "nested",
                  "properties": {
                     "lang": {
                        "type": "text"
                     },
                     "text": {
                        "type": "text"
                     }
                  }
               },
               "id": {
                  "type": "integer"
               },
               "category_id": {
                  "type": "integer"
               },
               "views": {
                  "type": "integer"
               },
               "rating": {
                  "type": "double"
               },
               "variants": {
                  "type": "nested",
                  "properties": {
                     "prod_id": {
                        "type": "integer"
                     },
                     "discount": {
                        "type": "double"
                     },
                     "price": {
                        "type": "double"
                     },
                     "attrs": {
                        "type": "nested",
                        "properties": {
                          "attr_id": {
                              "type": "integer"
                          },
                          "float_val": {
                              "type": "double"
                          },
                          "str_val": {
                              "type": "text"
                          }
                        }
                     }
                  }
               },
               "suggest" : {
                   "type" : "completion"
               }
            }
         }
      }
}
'

# Checking availability:
/app/wait_for_it.sh ${pg_host}:${pg_port} || sleep 30
/app/wait_for_it.sh ${es_host}:${es_port} || sleep 30
/app/wait_for_it.sh ${kc_host}:${kc_port} || sleep 30
/app/wait_for_it.sh ${sr_host}:${sr_port} || sleep 30

# We do not want Schema Registry to maintain any compatibility
curl -si -XPUT -H "Content-Type: application/json" ${sr_host}:${sr_port}/config -d '{"compatibility": "NONE"}'

echo "Initializing connectors"

for connector in "$debezium_json" "$stores_json"
do
    curl -si \
      -X POST \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      ${kc_host}:${kc_port}/connectors \
      -d "$connector"
done

echo
echo "Initializing Elastic indices"

curl -si -XPUT ${es_host}:${es_port}/stores\?pretty -H 'Content-Type: application/json' -d "$es_stores_json"
curl -si -XPUT ${es_host}:${es_port}/products\?pretty -H 'Content-Type: application/json' -d "$es_products_json"

exit 0

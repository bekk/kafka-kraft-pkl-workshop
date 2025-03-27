# Oppgave 7: Kafka Connect og Ekstern Integrasjon

## Mål
- Forstå Kafka Connect og dens rolle
- Implementere source og sink connectors
- Integrere med eksterne systemer
- Lære om transformasjoner og konverteringer

## Teori

### Kafka Connect
- **Source Connectors**: Henter data fra eksterne systemer
- **Sink Connectors**: Skriver data til eksterne systemer
- **Transformations**: Endrer data under overføring
- **Converters**: Konverterer mellom datatyper

### Vanlige Brukstilfeller
- Database-integrasjon
- Fil-system-integrasjon
- Message queue-integrasjon
- Cloud service-integrasjon

## Steg

### 1. Oppdater PKL-konfigurasjon
Bygg docker imaget med følgende kommando:

```bash
docker build -t my-kafka-connect-jdbc:7.5.0 .
```

Opprett filen `pkl/kafka/connect.pkl`:
```pkl
amends "../modules/DockerCompose.pkl"

import "../modules/service/Service.pkl"
import "../modules/util/ServiceUtilSSLMetrics.pkl" as ServiceUtil

local controller_ids: List<Int> = List(1,2,3)
local broker_ids: List<Int> = List(1,2,3)

services {
    for (controller_id in controller_ids) {
        ["controller-\(controller_id)"] = ServiceUtil.generateControllerService(controller_id, controller_ids)
    }
    for (broker_id in broker_ids) {
        ["broker-\(broker_id)"] = ServiceUtil.generateBrokerService(broker_id, controller_ids, broker_ids)
    }

    ["prometheus"] = (Service) {
        image = "prom/prometheus:latest"
        container_name = "prometheus"
        volumes = new Listing {
            "./prometheus:/etc/prometheus"
        }
        ports = new Listing {
            "9090:9090"
        }
    }

    ["grafana"] = (Service) {
        image = "grafana/grafana:latest"
        container_name = "grafana"
        ports = new Listing {
            "3000:3000"
        }
        environment {
            ["GF_SECURITY_ADMIN_PASSWORD"] = "admin"
        }
    }

    ["connect"] = (Service) {
        image = "my-kafka-connect-jdbc:7.5.0"
        container_name = "connect"
        depends_on = broker_ids.map((i) -> "broker-\(i)").toListing()
        ports = new Listing {
            "8083:8083"
        }
        
        volumes = new Listing {
            "./certs:/etc/kafka/secrets"
            "./lib:/usr/local/share/kafka/plugins"
            "./connect/connect-distributed.properties:/etc/kafka/connect-distributed.properties"
        }
        environment {
            ["CONNECT_BOOTSTRAP_SERVERS"] = broker_ids.map((i) -> "broker-\(i):9092").join(",")
            ["CONNECT_SECURITY_PROTOCOL"] = "SSL"
            ["CONNECT_REST_PORT"] = "8083"
            ["CONNECT_GROUP_ID"] = "connect-cluster"
            ["CONNECT_CONFIG_STORAGE_TOPIC"] = "connect-configs"
            ["CONNECT_OFFSET_STORAGE_TOPIC"] = "connect-offsets"
            ["CONNECT_STATUS_STORAGE_TOPIC"] = "connect-status"
            ["CONNECT_KEY_CONVERTER"] = "org.apache.kafka.connect.json.JsonConverter"
            ["CONNECT_VALUE_CONVERTER"] = "org.apache.kafka.connect.json.JsonConverter"
            ["CONNECT_KEY_CONVERTER_SCHEMAS_ENABLE"] = "true"
            ["CONNECT_VALUE_CONVERTER_SCHEMAS_ENABLE"] = "true"
            ["CONNECT_PLUGIN_PATH"] = "/usr/local/share/kafka/plugins,/usr/share/java/kafka-connect-jdbc"
            ["CONNECT_REST_ADVERTISED_HOST_NAME"] = "localhost"
            
            ["CONNECT_SSL_TRUSTSTORE_TYPE"] = "JKS"
            ["CONNECT_SSL_TRUSTSTORE_LOCATION"] = "/etc/kafka/secrets/ca-truststore.jks"
            ["CONNECT_SSL_TRUSTSTORE_PASSWORD"] = "ca-password"
            ["CONNECT_SSL_KEYSTORE_TYPE"] = "JKS"
            ["CONNECT_SSL_KEYSTORE_LOCATION"] = "/etc/kafka/secrets/connect-keystore.jks"
            ["CONNECT_SSL_KEYSTORE_PASSWORD"] = "connect-password"
            ["CONNECT_SSL_KEY_PASSWORD"] = "connect-password"
            ["CONNECT_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM"] = "HTTPS"
            
            ["CONNECT_PRODUCER_SECURITY_PROTOCOL"] = "SSL"
            ["CONNECT_PRODUCER_SSL_TRUSTSTORE_TYPE"] = "JKS"
            ["CONNECT_PRODUCER_SSL_TRUSTSTORE_LOCATION"] = "/etc/kafka/secrets/ca-truststore.jks"
            ["CONNECT_PRODUCER_SSL_TRUSTSTORE_PASSWORD"] = "ca-password"
            ["CONNECT_PRODUCER_SSL_KEYSTORE_TYPE"] = "JKS"
            ["CONNECT_PRODUCER_SSL_KEYSTORE_LOCATION"] = "/etc/kafka/secrets/connect-keystore.jks"
            ["CONNECT_PRODUCER_SSL_KEYSTORE_PASSWORD"] = "connect-password"
            ["CONNECT_PRODUCER_SSL_KEY_PASSWORD"] = "connect-password"
            ["CONNECT_PRODUCER_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM"] = "HTTPS"
            
            ["CONNECT_CONSUMER_SECURITY_PROTOCOL"] = "SSL"
            ["CONNECT_CONSUMER_SSL_TRUSTSTORE_TYPE"] = "JKS"
            ["CONNECT_CONSUMER_SSL_TRUSTSTORE_LOCATION"] = "/etc/kafka/secrets/ca-truststore.jks"
            ["CONNECT_CONSUMER_SSL_TRUSTSTORE_PASSWORD"] = "ca-password"
            ["CONNECT_CONSUMER_SSL_KEYSTORE_TYPE"] = "JKS"
            ["CONNECT_CONSUMER_SSL_KEYSTORE_LOCATION"] = "/etc/kafka/secrets/connect-keystore.jks"
            ["CONNECT_CONSUMER_SSL_KEYSTORE_PASSWORD"] = "connect-password"
            ["CONNECT_CONSUMER_SSL_KEY_PASSWORD"] = "connect-password"
            ["CONNECT_CONSUMER_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM"] = "HTTPS"
            
            ["CLUSTER_ID"] = "MkU3OEVBNTcwNTJENDM2Qk"
        }
    }

    ["postgres"] = (Service) {
        image = "postgres:13"
        container_name = "postgres"
        environment {
            ["POSTGRES_USER"] = "kafka"
            ["POSTGRES_PASSWORD"] = "kafka"
            ["POSTGRES_DB"] = "kafka"
        }
        ports = new Listing {
            "5432:5432"
        }
    }
}
```

### 2. Legge inn nødvendig SSL-oppsett

```bash
openssl req -newkey rsa:2048 -nodes -keyout certs/connect.key -out certs/connect.csr -subj "/CN=connect"

openssl x509 -req -CA certs/ca-cert -CAkey certs/ca-key \
  -in certs/connect.csr \
  -out certs/connect-signed \
  -days 365 \
  -CAcreateserial \
  -passin pass:ca-password

openssl pkcs12 -export \
  -in certs/connect-signed \
  -inkey certs/connect.key \
  -out certs/connect-keystore.p12 \
  -name "connect" \
  -passout pass:connect-password

keytool -importkeystore \
  -deststoretype JKS \
  -destkeystore certs/connect-keystore.jks \
  -deststorepass connect-password \
  -srckeystore certs/connect-keystore.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass connect-password \
  -alias connect

printf "connect-password" > certs/connect-password
```

### 3. Start Connect og PostgreSQL
```bash
pkl eval pkl/kafka/connect.pkl --format yaml > docker-compose.yml
docker compose up -d
```

### 4. Opprett testdata i PostgreSQL
```bash
# Koble til PostgreSQL
docker compose exec postgres psql -U kafka -d kafka

# Opprett tabell
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);

# Sett inn testdata
INSERT INTO users (name, email) VALUES
    ('Ole', 'ole@example.com'),
    ('Kari', 'kari@example.com');
```

### 5. Konfigurer Source Connector
Opprett filen `connect/source-connector.json`:
```json
{
    "name": "postgres-source",
    "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "tasks.max": "1",
      "connection.url": "jdbc:postgresql://postgres:5432/kafka",
      "connection.user": "kafka",
      "connection.password": "kafka",
      "table.whitelist": "users",
      "mode": "incrementing",
      "incrementing.column.name": "id",
      "key.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "key.converter.schemas.enable": "true",
      "plugin.path": "/usr/local/share/kafka/plugins",
      "value.converter.schemas.enable": "true",
      "topic.prefix": "postgres-"
    }
}
```

### 6. Opprett Source Connector
```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @connect/source-connector.json
```

### 7. Verifiser Source Connector
```bash
# Sjekk connector-status
curl http://localhost:8083/connectors/postgres-source/status

# Sjekk topics
docker compose exec -e KAFKA_OPTS="" broker-1 kafka-topics --list \
  --bootstrap-server broker-1:9092 \
  --command-config /etc/kafka/secrets/client-ssl.properties

# Se meldinger
docker compose exec -e KAFKA_OPTS="" broker-1 kafka-console-consumer \
  --bootstrap-server broker-1:9092 \
  --topic postgres-users \
  --from-beginning \
  --consumer.config /etc/kafka/secrets/client-ssl.properties
```

### 8. Konfigurer Sink Connector
Opprett filen `connect/sink-connector.json`:
```json
{
    "name": "postgres-sink",
    "config": {
        "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
        "tasks.max": "1",
        "topics": "processed-users",
        "connection.url": "jdbc:postgresql://postgres:5432/kafka",
        "connection.user": "kafka",
        "connection.password": "kafka",
        "auto.create": "true",
        "auto.evolve": "true",
        "key.converter": "org.apache.kafka.connect.json.JsonConverter",
        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "plugin.path": "/usr/local/share/kafka/plugins",
        "key.converter.schemas.enable": "true",
        "value.converter.schemas.enable": "true"
    }
}
```

### 9. Opprett Sink Connector
```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @connect/sink-connector.json
```

### 10. Test ende-til-ende Flyt
```bash
# Send meldinger til processed-users topic
docker compose exec -e KAFKA_OPTS="" broker-1 kafka-console-producer \
  --bootstrap-server broker-1:9092 \
  --topic processed-users \
  --producer.config /etc/kafka/secrets/client-ssl.properties
> {"schema":{"type":"struct","fields":[{"field":"id","type":"int32"},{"field":"name","type":"string"},{"field":"email","type":"string"}],"optional":false,"name":"users"},"payload":{"id":3,"name":"Per","email":"per@example.com"}}

# Verifiser at data er i PostgreSQL
docker compose exec postgres psql -U kafka -d kafka -c "SELECT * FROM \"processed-users\";"
```

## Neste steg
I neste oppgave har du muligheten til å utforske litt hva du vil selv, f.eks structured streaming via Spark.
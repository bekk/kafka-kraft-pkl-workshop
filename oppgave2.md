# Oppgave 2: Grunnleggende Kafka-konfigurasjon med KRaft

## Mål
- Forstå KRaft (Kafka Raft) og hvorfor det er bedre enn Zookeeper
- Sette opp en enkel Kafka-konfigurasjon med én controller og én broker
- Lære om grunnleggende Kafka-konsepter

## Teori

### KRaft vs Zookeeper
KRaft er en nyere metode for metadata-håndtering i Kafka som erstatter Zookeeper. Fordelene inkluderer:
- Enklere arkitektur (én tjeneste i stedet for to)
- Bedre ytelse
- Forbedret sikkerhet
- Raskere failover

### Grunnleggende Kafka-konsepter
- **Controller**: Håndterer metadata og cluster-tilstand
- **Broker**: Håndterer meldinger og topic-partisjoner
- **Topic**: En logisk gruppering av meldinger
- **Partition**: En del av et topic som kan repliseres

## Steg

### 1. Opprett PKL-konfigurasjon
Opprett filen `pkl/kafka/basic.pkl`:
```pkl
amends "../modules/DockerCompose.pkl"

import "../modules/service/Service.pkl"

services {
  ["controller-1"] = (Service) {
    image = "confluentinc/cp-kafka:7.5.0"
    hostname = "controller-1"
    container_name = "controller-1"
    environment {
      ["KAFKA_PROCESS_ROLES"] = "controller"
      ["KAFKA_NODE_ID"] = 1
      ["KAFKA_LISTENERS"] = "CONTROLLER://controller-1:29092"
      ["KAFKA_CONTROLLER_QUORUM_VOTERS"] = "1@controller-1:29092"
      ["KAFKA_CONTROLLER_LISTENER_NAMES"] = "CONTROLLER"
      ["CLUSTER_ID"] = "MkU3OEVBNTcwNTJENDM2Qk"
    }
  }

  ["broker-1"] = (Service) {
    image = "confluentinc/cp-kafka:7.5.0"
    hostname = "broker-1"
    container_name = "broker-1"
    environment {
      ["KAFKA_NODE_ID"] = 4
      ["KAFKA_PROCESS_ROLES"] = "broker"
      ["KAFKA_LISTENER_SECURITY_PROTOCOL_MAP"] = "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT"
      ["KAFKA_ADVERTISED_LISTENERS"] = "PLAINTEXT://broker-1:9092"
      ["KAFKA_CONTROLLER_QUORUM_VOTERS"] = "1@controller-1:29092"
      ["KAFKA_CONTROLLER_LISTENER_NAMES"] = "CONTROLLER"
      ["KAFKA_LISTENERS"] = "PLAINTEXT://broker-1:9092"
      ["KAFKA_INTER_BROKER_LISTENER_NAME"] = "PLAINTEXT"
      ["CLUSTER_ID"] = "MkU3OEVBNTcwNTJENDM2Qk"

      ["KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR"] = "1"
      ["KAFKA_DEFAULT_REPLICATION_FACTOR"]       = "1"
      ["KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR"] = "1"
      ["KAFKA_TRANSACTION_STATE_LOG_MIN_ISR"]    = "1"
    }
  }
}
```

### 2. Generer Docker Compose
Kjør følgende kommando for å generere docker-compose.yml:
```bash
pkl eval pkl/kafka/basic.pkl --format yaml > docker-compose.yml
```

### 3. Start Kafka
Start Kafka med:
```bash
docker compose up -d
```

### 4. Verifiser at alt kjører
Sjekk at containerne kjører:
```bash
docker compose ps
```

### 5. Test Kafka
Opprett et topic og send noen testmeldinger:
```bash
# Opprett topic
docker compose exec broker-1 kafka-topics --create --bootstrap-server broker-1:9092 --topic test-topic --partitions 1 --replication-factor 1

# Send meldinger
docker compose exec broker-1 kafka-console-producer --bootstrap-server broker-1:9092 --topic test-topic
> Hei
> Verden
> Test

# Konsumer meldinger
docker compose exec broker-1 kafka-console-consumer --bootstrap-server broker-1:9092 --topic test-topic --from-beginning
```

## Neste steg
I neste oppgave skal vi utvide konfigurasjonen med flere brokers for å oppnå bedre tilgjengelighet og ytelse. 
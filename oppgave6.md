# Oppgave 6: Monitoring og Logging av Kafka

## Mål
- Implementere Prometheus og Grafana for monitoring
- Forstå viktige Kafka-metrikker

## Teori

### Monitoring i Kafka
- **Prometheus**: Samler metrikker fra Kafka
- **Grafana**: Visualiserer metrikker
- **JMX**: Java Management Extensions for Kafka-metrikker

## Steg

### 1. Oppdater PKL-konfigurasjon
Opprett filen `pkl/kafka/monitoring.pkl`:
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
}
```

### 2. Konfigurer Prometheus
Vi er litt late og oppretter filen `prometheus/prometheus.yml` manuelt:
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'kafka'
    static_configs:
      - targets: ['controller-1:9101', 'controller-2:9101', 'controller-3:9101', 
                 'broker-1:9101', 'broker-2:9101', 'broker-3:9101']
```
Dette kan gjøres via PKL istedenfor, slik at man kan ha `broker_ids` og `controller_ids` som common-variabler.

### 3. Start monitoring og logging
```bash
pkl eval pkl/kafka/monitoring.pkl --format yaml > docker-compose.yml
docker compose up -d
```

### 4. Verifiser monitoring
0. Lag litt trafikk selv først:

```bash
# Lag nytt topic eller bruk det gamle..
docker compose exec -e KAFKA_OPTS="" broker-1 kafka-topics --create \
  --bootstrap-server broker-1:9092 \
  --command-config /etc/kafka/secrets/client-ssl.properties \
  --topic secure-topic \
  --partitions 3 \
  --replication-factor 3

docker compose exec -e KAFKA_OPTS="" broker-1 kafka-console-producer \
  --bootstrap-server broker-1:9092 \
  --producer.config /etc/kafka/secrets/client-ssl.properties \
  --topic secure-topic
> Sikker melding 1
> Sikker melding 2

docker compose exec -e KAFKA_OPTS="" broker-1 kafka-console-consumer \
  --bootstrap-server broker-1:9092 \
  --consumer.config /etc/kafka/secrets/client-ssl.properties \
  --topic secure-topic \
  --from-beginning
```

1. Åpne Prometheus UI:
```bash
open http://localhost:9090
```

2. Søk etter Kafka-metrikker, f.eks:
- `kafka_server_leader_count`

### 6. Konfigurer Grafana
1. Åpne Grafana UI:
```bash
open http://localhost:3000
```

2. Logg inn med:
- Brukernavn: admin
- Passord: admin

3. Legg til Prometheus som datakilde:
- URL: http://prometheus:9090
- Test/lagre datakilden

4. Opprett dashboard for Kafka-metrikker:
- Gå til Drilldown -> Metrics i sidemenyen
- Utforsk logger der

## Neste steg
I neste oppgave skal vi implementere Kafka Connect for å integrere med eksterne systemer. 

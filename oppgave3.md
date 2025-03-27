# Oppgave 3: Skalering av Kafka-cluster

## Mål
- Forstå hvordan vi kan skalere Kafka med flere brokers
- Lære om replikering og partisjonering
- Implementere en mer robust Kafka-konfigurasjon

## Teori

### Skalering i Kafka
Kafka kan skaleres på to måter:
1. **Vertikal skalering**: Øke ressurser på eksisterende brokers
2. **Horisontal skalering**: Legge til flere brokers

### Replikering og Partisjonering
- **Replikering**: Kopierer data på tvers av brokers for å sikre tilgjengelighet
- **Partisjonering**: Deler data inn i mindre deler for å øke parallellisering
- **Replication Factor**: Antall kopier av hver partisjon

## Steg

### 1. Oppdater PKL-konfigurasjon
Vi ser også på hvordan man kan bruke funksjoner og maps for å opprette konfigurasjon. Du kan se hvordan man bruker replication factor i `pkl/modules/util/ServiceUtil.pkl`

Opprett filen `pkl/kafka/scaled.pkl`:
```pkl
amends "../modules/DockerCompose.pkl"

import "../modules/util/ServiceUtil.pkl" as ServiceUtil

local controller_ids: List<Int> = List(1)
local broker_ids: List<Int> = List(1,2,3)

services {
    for (controller_id in controller_ids) {
        ["controller-\(controller_id)"] = ServiceUtil.generateControllerService(controller_id, controller_ids)
    }
    for (broker_id in broker_ids) {
        ["broker-\(broker_id)"] = ServiceUtil.generateBrokerService(broker_id, controller_ids, broker_ids)
    }
}
```

### 2. Generer og start ny konfigurasjon
```bash
pkl eval pkl/kafka/scaled.pkl --format yaml > docker-compose.yml
docker compose up -d
```

### 3. Opprett topic med replikering
```bash
docker compose exec broker-1 kafka-topics --create \
  --bootstrap-server broker-1:9092 \
  --topic replicated-topic \
  --partitions 3 \
  --replication-factor 3
```

### 4. Test replikering
```bash
# Send meldinger
docker compose exec broker-1 kafka-console-producer \
  --bootstrap-server broker-1:9092 \
  --topic replicated-topic \
  --property "parse.key=true" \
  --property "key.separator=:"
> key1:Melding 1
> key2:Melding 2
> key3:Melding 3

# Konsumer fra alle brokers
docker compose exec broker-1 kafka-console-consumer \
  --bootstrap-server broker-1:9092 \
  --topic replicated-topic \
  --from-beginning

docker compose exec broker-2 kafka-console-consumer \
  --bootstrap-server broker-2:9092 \
  --topic replicated-topic \
  --from-beginning

docker compose exec broker-3 kafka-console-consumer \
  --bootstrap-server broker-3:9092 \
  --topic replicated-topic \
  --from-beginning
```

### 5. Test feiltoleranse
1. Stopp en broker:
```bash
docker compose stop broker-1
```

2. Verifiser at meldinger fortsatt kan sendes og mottas:
```bash
# Send nye meldinger
docker compose exec broker-2 kafka-console-producer \
  --bootstrap-server broker-2:9092 \
  --topic replicated-topic \
  --property "parse.key=true" \
  --property "key.separator=:"
> key4:Melding 4
> key5:Melding 5
```

3. Start broker-1 igjen:
```bash
docker compose start broker-1
```

4. Verifiser at broker-1 har meldingene replikert på seg:
```bash
docker compose exec broker-1 kafka-console-consumer \
  --bootstrap-server broker-1:9092 \
  --topic replicated-topic \
  --from-beginning
```

## Neste steg
I neste oppgave skal vi implementere flere controllers for å øke tilgjengeligheten ytterligere. 
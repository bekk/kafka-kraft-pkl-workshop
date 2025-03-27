# Oppgave 4: Flere Controllers for Økt Tilgjengelighet

## Mål
- Implementere flere controllers i Kafka-clusteret
- Forstå hvordan controller-konsensus fungerer
- Øke tilgjengeligheten til clusteret

## Teori

### Controller-konsensus
- Controllers bruker Raft-konsensusprotokollen
- Flere controllers gir bedre feiltoleranse
- Minst 3 controllers anbefales for produksjon
- Controller-konsensus håndterer metadata og cluster-tilstand

### Quorum
- Quorum er antall noder som må være tilgjengelige for å ta beslutninger
- Med 3 controllers trengs 2 noder for quorum
- Med 5 controllers trengs 3 noder for quorum

## Steg

### 1. Oppdater PKL-konfigurasjon
Opprett filen `pkl/kafka/multi-controller.pkl`:
```pkl
amends "../modules/DockerCompose.pkl"

import "../modules/util/ServiceUtil.pkl" as ServiceUtil

local controller_ids: List<Int> = List(1,2,3)
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
pkl eval pkl/kafka/multi-controller.pkl --format yaml > docker-compose.yml
docker compose up -d
```

### 3. Test controller-feiltoleranse
1. Stopp en controller:
```bash
docker compose stop controller-1
```

2. Verifiser at clusteret fortsatt fungerer:
```bash
# Opprett nytt topic
docker compose exec broker-1 kafka-topics --create \
  --bootstrap-server broker-1:9092 \
  --topic controller-test \
  --partitions 3 \
  --replication-factor 3

# Send meldinger
docker compose exec broker-1 kafka-console-producer \
  --bootstrap-server broker-1:9092 \
  --topic controller-test
> Test melding 1
> Test melding 2
```

### 4. Test ekstrem feiltoleranse
1. Stopp to controllers:
```bash
docker compose stop controller-1 controller-2
```

2. Verifiser at clusteret ikke lenger kan "ta beslutninger":
```bash
# Dette burde feile
docker compose exec broker-1 kafka-topics --create \
  --bootstrap-server broker-1:9092 \
  --topic should-fail \
  --partitions 3 \
  --replication-factor 3
```

3. Start controllers igjen:
```bash
docker compose start controller-1 controller-2
```

4. Verifiser at nå fungerer det å opprette topic igjen
```bash
docker compose exec broker-1 kafka-topics --create \
  --bootstrap-server broker-1:9092 \
  --topic should-work \
  --partitions 3 \
  --replication-factor 3
```

## Neste steg
I neste oppgave skal vi implementere sikkerhet i Kafka-clusteret. 
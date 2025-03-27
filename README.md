# Kafka Workshop med PKL

Dette er en workshop i å bruke PKL for å generere Kafka-konfigurasjoner og implementere en robust Kafka-infrastruktur.

## Teknologier
- Kafka (KRaft modus)
- Docker Compose
- PKL
- Docker
- PostgreSQL (for Kafka Connect)
- Prometheus & Grafana (for monitoring)

## Oppgaver

### 1. Oppsett av PKL og prosjektstruktur
- Installere PKL
- Sette opp prosjektstruktur
- Forstå grunnleggende PKL-konsepter

### 2. Grunnleggende Kafka-konfigurasjon med KRaft
- Forstå KRaft (Kafka Raft) og hvorfor det er bedre enn Zookeeper
- Sette opp en enkel Kafka-konfigurasjon med én controller og én broker
- Lære om grunnleggende Kafka-konsepter

### 3. Skalering av Kafka-cluster
- Forstå hvordan vi kan skale Kafka med flere brokers
- Lære om replikering og partisjonering
- Implementere en mer robust Kafka-konfigurasjon

### 4. Flere Controllers for Økt Tilgjengelighet
- Implementere flere controllers i Kafka-clusteret
- Forstå hvordan controller-konsensus fungerer
- Øke tilgjengeligheten til clusteret

### 5. Sikkerhet i Kafka
- Implementere TLS/SSL for sikker kommunikasjon
- Sette opp autentisering med SASL/PLAIN
- Konfigurere autorisering med ACLs

### 6. Monitoring og Logging av Kafka
- Implementere Prometheus og Grafana for monitoring
- Forstå viktige Kafka-metrikker

### 7. Kafka Connect og Ekstern Integrasjon
- Forstå Kafka Connect og dens rolle
- Implementere source og sink connectors
- Integrere med eksterne systemer

### 8. Kafka Streams og Stream Processing
- Utforske stream processing på egenhånd

## Forutsetninger
- Docker og Docker Compose installert
- PKL installert
- Java 17 eller nyere

## Kom i gang

1. Klon repositoriet:
```bash
git clone <repository-url>
cd kafka-workshop
```

2. Følg oppgavene i rekkefølge:
```bash
# Start med oppgave 1
cd oppgave1
# Følg instruksjonene i oppgave1.md
```

3. Hver oppgave bygger på forrige, så det er viktig å følge dem i rekkefølge.

# Oppgave 5: Sikkerhet i Kafka

## Mål
- Implementere TLS/SSL for sikker kommunikasjon
- Sette opp autentisering med SASL/PLAIN
- Konfigurere autorisering med ACLs
- Forstå grunnleggende sikkerhetskonsepter i Kafka

## Teori

### Sikkerhetslag i Kafka
1. **Transport Layer Security (TLS)**
   - Krypterer kommunikasjon mellom klienter og servere
   - Bruker sertifikater for autentisering

2. **Autentisering (SASL)**
   - Verifiserer identiteten til brukere
   - Støtter flere mekanismer (PLAIN, SCRAM, etc.)

3. **Autorisering (ACLs)**
   - Kontrollerer tilgang til ressurser
   - Definerer hvem som kan gjøre hva

## Steg

### 1. Generer SSL-sertifikater
```bash
mkdir -p certs

openssl req \
  -new \
  -x509 \
  -keyout certs/ca-key \
  -out certs/ca-cert \
  -days 365 \
  -passout pass:ca-password \
  -subj "/CN=ca"


for i in 1 2 3; do
  openssl req \
    -newkey rsa:2048 \
    -nodes \
    -keyout certs/broker-$i-key \
    -out certs/broker-$i.csr \
    -days 365 \
    -subj "/CN=broker-$i"

  openssl x509 \
    -req \
    -CA certs/ca-cert \
    -CAkey certs/ca-key \
    -in certs/broker-$i.csr \
    -out certs/broker-$i-signed \
    -days 365 \
    -CAcreateserial \
    -passin pass:ca-password

  openssl pkcs12 \
    -export \
    -in certs/broker-$i-signed \
    -inkey certs/broker-$i-key \
    -out certs/broker-$i-keystore.p12 \
    -name "broker-$i" \
    -passout pass:broker-$i-password

  keytool -importkeystore \
    -deststoretype JKS \
    -destkeystore certs/broker-$i-keystore.jks \
    -deststorepass broker-$i-password \
    -srckeystore certs/broker-$i-keystore.p12 \
    -srcstoretype PKCS12 \
    -srcstorepass broker-$i-password \
    -alias "broker-$i"

done

keytool -import -noprompt \
  -keystore certs/ca-truststore.jks \
  -storepass ca-password \
  -alias CARoot \
  -file certs/ca-cert

printf "broker-1-password" > certs/broker-1-password
printf "broker-2-password" > certs/broker-2-password
printf "broker-3-password" > certs/broker-3-password
printf "ca-password"       > certs/ca-password

openssl req \
  -newkey rsa:2048 \
  -nodes \
  -keyout certs/client.key \
  -out certs/client.csr \
  -subj "/CN=client"

openssl x509 \
  -req \
  -CA certs/ca-cert \
  -CAkey certs/ca-key \
  -in certs/client.csr \
  -out certs/client-signed \
  -days 365 \
  -CAcreateserial \
  -passin pass:ca-password

openssl pkcs12 \
  -export \
  -in certs/client-signed \
  -inkey certs/client.key \
  -out certs/client-keystore.p12 \
  -name client \
  -passout pass:client-password

keytool -importkeystore \
  -deststoretype JKS \
  -destkeystore certs/client-keystore.jks \
  -deststorepass client-password \
  -srckeystore certs/client-keystore.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass client-password \
  -alias client
```

### 2. Oppdater PKL-konfigurasjon
Nå skal vi ta i bruk SSL og vi bruker da en litt annen konfig enn i de forrige oppgavene. Opprett filen `pkl/kafka/secure.pkl`:

```pkl
amends "../modules/DockerCompose.pkl"

import "../modules/util/ServiceUtilSSL.pkl" as ServiceUtil

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

### 3. Opprett client-ssl.properties
Opprett filen `certs/client-ssl.properties`:
```properties
security.protocol=SSL
ssl.truststore.location=/etc/kafka/secrets/ca-truststore.jks
ssl.truststore.password=ca-password

ssl.keystore.location=/etc/kafka/secrets/client-keystore.jks
ssl.keystore.password=client-password
ssl.key.password=client-password
```

### 4. Generer og start sikker konfigurasjon
```bash
pkl eval pkl/kafka/secure.pkl --format yaml > docker-compose.yml
docker compose up -d
```


### 5. Test SSL-tilkobling
```bash
docker compose exec broker-1 kafka-topics --create \
  --bootstrap-server broker-1:9092 \
  --command-config /etc/kafka/secrets/client-ssl.properties \
  --topic secure-topic \
  --partitions 3 \
  --replication-factor 3

docker compose exec broker-1 kafka-console-producer \
  --bootstrap-server broker-1:9092 \
  --producer.config /etc/kafka/secrets/client-ssl.properties \
  --topic secure-topic
> Sikker melding 1
> Sikker melding 2

docker compose exec broker-1 kafka-console-consumer \
  --bootstrap-server broker-1:9092 \
  --consumer.config /etc/kafka/secrets/client-ssl.properties \
  --topic secure-topic \
  --from-beginning
```

## Neste steg
I neste oppgave skal vi implementere monitoring og logging av Kafka-clusteret. 
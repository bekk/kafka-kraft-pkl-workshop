# Oppgave 1: Oppsett av PKL og prosjektstruktur

## Mål
- Installere PKL
- Sette opp prosjektstruktur
- Forstå grunnleggende PKL-konsepter

## Steg

### 1. Installer PKL
Først må vi installere PKL. Du kan gjøre dette ved å følge instruksjonene på [PKL's offisielle nettside](https://pkl-lang.org/install/).

For macOS kan du bruke Homebrew:
```bash
brew install pkl
```

Videre trenger vi også PKL-extension i VS Code. Følg [instruksjonene her for](https://pkl-lang.org/vscode/current/installation.html) å installere den.


### 2. Verifiser installasjon
Kjør følgende kommando for å verifisere at PKL er installert:
```bash
pkl --version
```

### 3. Opprett prosjektstruktur
Opprett følgende mappestruktur:
```
.
├── docker
│   └── kafka
├── pkl
│   └── kafka
```

### 4. Test PKL
Opprett en test-fil `pkl/test.pkl`:
```pkl
name = "test"
version = "1.0.0"
```

Kjør følgende kommando for å teste:
```bash
pkl eval pkl/test.pkl
```

Hvis den går gjennom, så er alt installert korrekt

## Neste steg
I neste oppgave skal vi sette opp en enkel Kafka-konfigurasjon med KRaft modus. 
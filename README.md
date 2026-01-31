# 🚀 Raspberry Pi Deploy Template

Template per deploy automatico su Raspberry Pi tramite GitHub Actions con Tailscale.

![Deploy](https://github.com/CheckSim/raspberry-deploy-template/workflows/Deploy%20to%20Raspberry%20Pi/badge.svg)

## 📋 Cosa include questo template

- ✅ **Workflow GitHub Actions** per deploy automatico via Tailscale
- ✅ **Setup automatico servizi systemd** per progetti Python
- ✅ **Supporto multi-stack**: Node.js (PM2), Python (systemd), Docker Compose
- ✅ **Gestione automatica secrets** tramite file `.env`
- ✅ **Verifica post-deploy** con controllo stato servizi
- ✅ **Script di setup automatico** per Raspberry Pi
- ✅ **Ottimizzato per Raspberry Pi 2/4/5**
- ✅ **Documentazione completa**

## 🎯 Quick Start

### 1. Configura il Raspberry Pi

**Opzione A: Setup Automatico (CONSIGLIATO)**

Sul Raspberry Pi, scarica ed esegui lo script di setup:

```bash
curl -fsSL https://raw.githubusercontent.com/TUO_USERNAME/raspberry-deploy-template/main/setup-raspberry.sh -o setup-raspberry.sh
chmod +x setup-raspberry.sh
./setup-raspberry.sh
```

Lo script installerà tutto automaticamente: Python 3.12, Node.js, PM2, Tailscale, chiavi SSH, configurazione sudo.

**Opzione B: Setup Manuale**

Segui la [guida completa](docs/SETUP_SECRETS.md) per configurare manualmente ogni componente.

### 2. Usa questo template

Clicca su **"Use this template"** in alto per creare un nuovo repository dal template.

### 3. Configura i secrets

Vai su **Settings** → **Secrets and variables** → **Actions** e configura:

**Secrets obbligatori:**
- `TS_OAUTH_CLIENT_ID` - OAuth Client ID di Tailscale
- `TS_OAUTH_SECRET` - OAuth Client Secret di Tailscale
- `SSH_HOST` - IP Tailscale del Pi (es. `100.x.x.x`, ottienilo con `tailscale ip -4`)
- `SSH_USER` - Username (es. `pi`)
- `SSH_PRIVATE_KEY` - Chiave privata SSH (da `cat ~/.ssh/id_ed25519`)
- `GH_TOKEN_DEPLOY` - Personal Access Token GitHub con scope `repo`
- `ENV_FILE` - Contenuto del file `.env` (vedi `.env.example`)

**Secrets opzionali:**
- `PYTHON_VERSION` - Versione Python specifica (es. `3.12`)

📖 [Guida dettagliata configurazione secrets](docs/SETUP_SECRETS.md)

### 4. Push e deploy!

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

Il deploy partirà automaticamente! 🎉

---

## 📚 Documentazione completa

Per la guida completa su come configurare il Raspberry Pi e tutti i dettagli:

👉 **Scorri in basso in questo README per la guida completa**

---

## 🎯 Come usare questo template per nuovi progetti

### Metodo 1: Usa il pulsante "Use this template" (Consigliato)

1. Vai sulla pagina del repository template su GitHub
2. Clicca il pulsante verde **"Use this template"** in alto a destra
3. Seleziona **"Create a new repository"**
4. Compila:
   - **Repository name**: nome del tuo nuovo progetto
   - **Description**: descrizione del progetto
   - **Public** o **Private**: scegli la visibilità
5. Clicca **"Create repository"**
6. Clona il nuovo repository:
   ```bash
   git clone git@github.com:tuo-username/nuovo-progetto.git
   cd nuovo-progetto
   ```
7. Configura i secrets (vedi [docs/SETUP_SECRETS.md](docs/SETUP_SECRETS.md))
8. Sviluppa il tuo progetto!

### Metodo 2: Clona e riconfigura manualmente

```bash
# Clona il template
git clone git@github.com:tuo-username/raspberry-deploy-template.git nuovo-progetto
cd nuovo-progetto

# Rimuovi il remote originale
git remote remove origin

# Crea un nuovo repository su GitHub, poi:
git remote add origin git@github.com:tuo-username/nuovo-progetto.git
git push -u origin main
```

### Cosa fare dopo aver creato il progetto dal template

1. ✅ **Configura i secrets GitHub** (vedi [docs/SETUP_SECRETS.md](docs/SETUP_SECRETS.md))
2. ✅ **Copia `.env.example` in `.env`** localmente e configura le tue variabili
3. ✅ **Aggiungi il contenuto di `.env` nel secret `ENV_FILE`** su GitHub
4. ✅ **Sviluppa il tuo progetto** (Node.js, Python, Docker, ecc.)
5. ✅ **Fai commit e push** - il deploy partirà automaticamente!

---

## 🔥 Funzionalità avanzate

### Deploy automatico di progetti Python

Il workflow:
- ✅ Rileva automaticamente progetti Python (via `requirements.txt`)
- ✅ Cerca file entry point: `main.py`, `bot.py`, `app.py`, `run.py`
- ✅ **Crea automaticamente il servizio systemd** se non esiste
- ✅ Configura auto-restart in caso di crash
- ✅ Verifica che il servizio sia attivo dopo il deploy
- ✅ Mostra i log se ci sono errori

**Nessuna configurazione manuale necessaria!**

### Deploy automatico di progetti Node.js

Il workflow:
- ✅ Rileva automaticamente progetti Node.js (via `package.json`)
- ✅ Installa dipendenze con `npm install`
- ✅ Esegue build se presente script `build`
- ✅ Gestisce PM2 automaticamente (restart o start)

### Supporto Docker Compose

Il workflow:
- ✅ Rileva automaticamente `docker-compose.yml`
- ✅ Rebuilda e riavvia i container
- ⚠️ Consigliato solo per Raspberry Pi 4/5

---

## 🛠️ File e struttura

```
raspberry-deploy-template/
├── .github/
│   └── workflows/
│       └── deploy.yml          # Workflow GitHub Actions
├── docs/
│   └── SETUP_SECRETS.md        # Guida configurazione secrets
├── setup-raspberry.sh          # Script setup automatico Raspberry Pi
├── .env.example                # Template variabili d'ambiente
├── .gitignore                  # File da ignorare
└── README.md                   # Questa guida
```

---

## 🔒 Sicurezza

- ✅ **Tailscale**: Connessione sicura senza esporre SSH pubblicamente
- ✅ **Nessun port forwarding**: Funziona anche dietro CG-NAT
- ✅ **Secrets GitHub**: Variabili sensibili mai committate nel repository
- ✅ **Chiavi SSH separate**: Una per GitHub, una per GitHub Actions

---

## 🌟 Esempi di utilizzo

### Bot Telegram

```python
# main.py
import os
from telegram import Update
from telegram.ext import Application

TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')

app = Application.builder().token(TOKEN).build()
app.run_polling()
```

Secret `ENV_FILE`:
```
TELEGRAM_BOT_TOKEN=123456789:ABCdef...
```

### API REST con Flask

```python
# app.py
import os
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello World!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)))
```

Secret `ENV_FILE`:
```
PORT=5000
DATABASE_URL=postgresql://...
SECRET_KEY=your-secret-key
```

### Bot Discord con Node.js

```javascript
// index.js
require('dotenv').config();
const { Client, GatewayIntentBits } = require('discord.js');

const client = new Client({ 
  intents: [GatewayIntentBits.Guilds] 
});

client.login(process.env.DISCORD_TOKEN);
```

Secret `ENV_FILE`:
```
DISCORD_TOKEN=your-discord-token
```

---

## 📊 Monitoraggio

### Verifica stato servizi

```bash
# Per Python (systemd)
sudo systemctl status nome-progetto
sudo journalctl -u nome-progetto -f

# Per Node.js (PM2)
pm2 list
pm2 logs nome-progetto

# Per Docker
docker compose ps
docker compose logs -f
```

---

## 🆘 Supporto

Problemi? Controlla:
- 📖 [Guida completa](README.md#guida-deploy-automatico-da-github-a-raspberry-pi)
- 🔐 [Setup secrets](docs/SETUP_SECRETS.md)
- 🐛 [Troubleshooting](README.md#troubleshooting)

---

## 📝 License

MIT

---

# Guida: Deploy Automatico da GitHub a Raspberry Pi

Questa guida ti aiuterà a configurare un sistema di deploy automatico che fa il push del codice da GitHub al tuo Raspberry Pi ogni volta che fai un commit.

## 📋 Prerequisiti

- Un Raspberry Pi con Raspberry Pi OS installato
- Accesso SSH al Raspberry Pi
- Un account GitHub
- Connessione internet sul Raspberry Pi

## ⚠️ Nota per Raspberry Pi 2

Se hai un **Raspberry Pi 2 v1.1** (1GB RAM, 32-bit):
- Usa **Raspberry Pi OS Lite (32-bit, Legacy)**
- Evita Docker quando possibile (molto pesante su 1GB RAM)
- **Preferisci PM2 per Node.js e systemd per Python**
- Limita a 1-2 progetti contemporaneamente
- Aggiungi swap (v

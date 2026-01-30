# 🚀 Raspberry Pi Deploy Template

Template per deploy automatico su Raspberry Pi tramite GitHub Actions.

![Deploy](https://github.com/CheckSim/raspberry-deploy-template/workflows/Deploy%20to%20Raspberry%20Pi/badge.svg)

## 📋 Cosa include questo template

- ✅ **Workflow GitHub Actions** per deploy automatico
- ✅ **Supporto multi-stack**: Node.js (PM2), Python (systemd), Docker Compose
- ✅ **Gestione automatica secrets** tramite file `.env`
- ✅ **Ottimizzato per Raspberry Pi 2/4/5**
- ✅ **Documentazione completa**

## 🎯 Quick Start

### 1. Usa questo template

Clicca su **"Use this template"** in alto per creare un nuovo repository dal template.

### 2. Configura i secrets

Vai su **Settings** → **Secrets and variables** → **Actions** e configura:

- `TS_OAUTH_CLIENT_ID` - OAuth Client ID di Tailscale
- `TS_OAUTH_SECRET` - OAuth Client Secret di Tailscale
- `SSH_HOST` - IP Tailscale del Pi (es. `100.x.x.x`, ottienilo con `tailscale ip -4` sul Pi)
- `SSH_USER` - Username (es. `pi`)
- `SSH_PRIVATE_KEY` - Chiave privata SSH
- `ENV_FILE` - Contenuto del file `.env` (vedi `.env.example`)

📖 [Guida dettagliata configurazione secrets](docs/SETUP_SECRETS.md)

### 3. Push e deploy!

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

Il deploy partirà automaticamente! 🎉

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
2. ✅ **Copia `.env.example` in `.env`** e configura le tue variabili
3. ✅ **Sviluppa il tuo progetto** (Node.js, Python, Docker, ecc.)
4. ✅ **Fai commit e push** - il deploy partirà automaticamente!

### Badge deploy personalizzato

Nel README del tuo nuovo progetto, il badge deploy si aggiornerà automaticamente. Assicurati che l'URL corrisponda al tuo repository:

```markdown
![Deploy](https://github.com/tuo-username/tuo-progetto/workflows/Deploy%20to%20Raspberry%20Pi/badge.svg)
```

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

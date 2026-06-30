# Guida: Deploy Automatico da GitHub a Raspberry Pi

Questa guida ti aiuterà a configurare un sistema di deploy automatico che fa il push del codice da GitHub al tuo Raspberry Pi ogni volta che fai un commit.

## 📋 Prerequisiti

- Un Raspberry Pi con Raspberry Pi OS installato
- Accesso SSH al Raspberry Pi (o monitor e tastiera per la configurazione iniziale)
- Un account GitHub
- Connessione internet sul Raspberry Pi

## ⚠️ Nota per Raspberry Pi 2

Se hai un **Raspberry Pi 2 v1.1** (1GB RAM, 32-bit):
- Usa **Raspberry Pi OS Lite (32-bit, Legacy)**
- Evita Docker (molto pesante su 1GB RAM)
- **Preferisci PM2 per Node.js e systemd per Python**
- Limita a 1-2 progetti contemporaneamente
- Aggiungi swap (lo script di setup lo fa automaticamente)

Se hai un **Raspberry Pi 4/5**:
- Usa **Raspberry Pi OS Lite (64-bit)**
- Docker funzionerà senza problemi
- Puoi gestire più progetti contemporaneamente

---

## 🚀 Setup Rapido con Script Automatico

### Metodo 1: Setup Automatico (CONSIGLIATO)

Sul Raspberry Pi appena configurato, esegui:

```bash
# Scarica lo script di setup
curl -fsSL https://raw.githubusercontent.com/TUO_USERNAME/raspberry-deploy-template/main/setup-raspberry.sh -o setup-raspberry.sh

# Oppure crea manualmente il file e copia il contenuto dello script

# Rendi eseguibile
chmod +x setup-raspberry.sh

# Esegui lo script
./setup-raspberry.sh
```

Lo script installerà automaticamente:
- ✅ Python 3.12
- ✅ Node.js e PM2
- ✅ Tailscale
- ✅ Chiavi SSH per GitHub
- ✅ Configurazione sudo senza password
- ✅ Directory ~/projects
- ✅ (Opzionale) Docker
- ✅ (Opzionale) Ottimizzazioni per Pi 2

**Segui le istruzioni interattive dello script** e salva le informazioni che ti fornisce!

---

## 🛠️ Setup Manuale (se preferisci il controllo completo)

Se preferisci configurare manualmente ogni componente, segui questi passaggi:

### 1.1 Connessione SSH

Assicurati di avere SSH abilitato sul Pi. Se non lo hai ancora fatto:

```bash
sudo raspi-config
# Vai su: Interface Options → SSH → Enable
```

Prendi nota dell'indirizzo IP del tuo Raspberry Pi:

```bash
hostname -I
```

### 1.2 Aggiornamento del sistema

```bash
sudo apt update
sudo apt upgrade -y
```

### 1.3 Installazione Python 3.12

```bash
# Installazione dipendenze
sudo apt install -y build-essential libssl-dev libffi-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev \
    libncursesw5-dev xz-utils tk-dev liblzma-dev

# Download e compilazione Python 3.12
cd /tmp
wget https://www.python.org/ftp/python/3.12.7/Python-3.12.7.tgz
tar -xzf Python-3.12.7.tgz
cd Python-3.12.7
./configure --enable-optimizations
make -j4
sudo make altinstall

# Installazione pip
curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.12

# Verifica
python3.12 --version
```

⚠️ **Nota**: La compilazione può richiedere 20-30 minuti su Raspberry Pi 2.

### 1.4 Installazione Node.js e PM2

```bash
# Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# PM2
sudo npm install -g pm2
pm2 startup systemd -u $USER --hp $HOME
```

### 1.5 Installazione Docker (SOLO Pi 4/5, SCONSIGLIATO per Pi 2)

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Riavvia per applicare i permessi
```

### 1.6 Installazione e Configurazione Tailscale

```bash
# Installa Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Avvia e autenticati
sudo tailscale up

# Ottieni l'IP Tailscale
tailscale ip -4
```

Apri il link nel browser e fai login. Salva l'IP Tailscale (es. `100.x.x.x`) - lo userai come `SSH_HOST`.

### 1.7 Configurazione SSH

```bash
# Crea directory .ssh
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Genera chiave SSH per GitHub
ssh-keygen -t ed25519 -C "github-deploy" -f ~/.ssh/id_ed25519 -N ""

# Mostra chiave pubblica (da aggiungere a GitHub → Settings → SSH keys)
cat ~/.ssh/id_ed25519.pub

# Mostra chiave privata (da usare come secret SSH_PRIVATE_KEY)
cat ~/.ssh/id_ed25519
```

**Aggiungi la chiave pubblica a GitHub:**
1. Vai su GitHub.com → Settings → SSH and GPG keys
2. New SSH key
3. Incolla la chiave pubblica

### 1.8 Configurazione sudo senza password

```bash
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/99-deploy-nopasswd
sudo chmod 440 /etc/sudoers.d/99-deploy-nopasswd
```

### 1.9 Creazione directory progetti

```bash
mkdir -p ~/projects
```

### 1.10 (Opzionale) Ottimizzazioni per Raspberry Pi 2

```bash
# Aumento swap
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

---

## 🔐 Configurazione Tailscale OAuth per GitHub Actions

### 1. Crea OAuth Client

1. Vai su [login.tailscale.com/admin/settings/oauth](https://login.tailscale.com/admin/settings/oauth)
2. Clicca **"Generate OAuth Client"**
3. Compila:
   - **Description**: `GitHub Actions Deploy`
   - **Tags**: `tag:ci`
4. Clicca **"Generate client"**
5. Copia **Client ID** e **Client secret** (il secret si vede solo una volta!)

### 2. Configura ACL con tag "ci"

1. Vai su [login.tailscale.com/admin/acls/file](https://login.tailscale.com/admin/acls/file)
2. Aggiungi in `"tagOwners"`:
   ```json
   "tagOwners": {
     "tag:ci": ["autogroup:admin"],
   },
   ```
3. Aggiungi in `"acls"`:
   ```json
   "acls": [
     {
       "action": "accept",
       "src": ["tag:ci"],
       "dst": ["*:22"],
     },
   ],
   ```
4. Salva

---

## 🔑 Configurazione Secrets su GitHub

Per ogni progetto che vuoi deployare:

1. Vai sul repository GitHub → **Settings** → **Secrets and variables** → **Actions**
2. Clicca **"New repository secret"**
3. Aggiungi i seguenti secrets:

### Secrets obbligatori:

| Nome | Valore | Come ottenerlo |
|------|--------|----------------|
| `TS_OAUTH_CLIENT_ID` | Client ID OAuth di Tailscale | Da Tailscale admin console |
| `TS_OAUTH_SECRET` | Client Secret OAuth di Tailscale | Da Tailscale admin console |
| `SSH_HOST` | IP Tailscale del Pi (es. `100.x.x.x`) | `tailscale ip -4` sul Pi |
| `SSH_USER` | Username (es. `pi`) | `whoami` sul Pi |
| `SSH_PRIVATE_KEY` | Chiave privata SSH | `cat ~/.ssh/id_ed25519` sul Pi |
| `GH_TOKEN_DEPLOY` | Personal Access Token GitHub | GitHub Settings → Developer settings → Personal access tokens |
| `ENV_FILE` | Contenuto del file `.env` | Variabili d'ambiente del progetto |

### Secrets opzionali:

| Nome | Valore | Quando serve |
|------|--------|--------------|
| `PYTHON_VERSION` | `3.12` | Per specificare versione Python (default: `python3`) |

### Come creare `GH_TOKEN_DEPLOY`:

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. Seleziona scope: `repo` (Full control of private repositories)
4. Copia il token generato

### Esempio `ENV_FILE` per bot Telegram:

```
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
DATABASE_URL=postgresql://user:password@localhost:5432/botdb
NODE_ENV=production
```

---

## 📝 Aggiunta del Workflow al Progetto

### 1. Crea la cartella del workflow

Nel tuo progetto locale:

```bash
mkdir -p .github/workflows
```

### 2. Crea il file deploy.yml

Copia il contenuto del workflow `deploy.yml` in `.github/workflows/deploy.yml`

### 3. Commit e push

```bash
git add .github/workflows/deploy.yml
git commit -m "Add automatic deployment workflow"
git push origin main
```

---

## 🚀 Test del Deploy

### 1. Verifica che il workflow sia partito

1. Vai su GitHub → repository → tab **Actions**
2. Dovresti vedere "Deploy to Raspberry Pi" in esecuzione

### 2. Monitora l'esecuzione

Clicca sul workflow per vedere i log in tempo reale:
- ✅ Connessione a Tailscale
- ✅ Clone/update del repository
- ✅ Creazione file `.env`
- ✅ Installazione dipendenze
- ✅ Creazione servizio systemd (se non esiste)
- ✅ Riavvio del servizio
- ✅ Verifica stato del servizio

### 3. Verifica sul Raspberry Pi

```bash
# Connettiti al Pi
ssh pi@100.x.x.x  # Usa il tuo IP Tailscale

# Controlla il progetto
cd ~/projects/nome-repository
ls -la

# Verifica il servizio (per progetti Python)
sudo systemctl status nome-repository

# Verifica PM2 (per progetti Node.js)
pm2 list

# Vedi i log
sudo journalctl -u nome-repository -f
```

---

## 🔄 Uso Quotidiano

Ogni volta che fai un push:

```bash
git add .
git commit -m "Update feature"
git push origin main
```

Il deploy partirà automaticamente! Monitora su GitHub Actions.

---

## 🛠️ Configurazioni Specifiche per Tipo di Progetto

### Node.js con PM2

Il workflow rileva automaticamente `package.json`.

**Nessuna configurazione aggiuntiva necessaria!** PM2 viene gestito automaticamente.

### Python con systemd

Il workflow:
1. Rileva `requirements.txt`
2. Cerca file entry point: `main.py`, `bot.py`, `app.py`, `run.py`
3. **Crea automaticamente il servizio systemd** se non esiste
4. Riavvia il servizio

**Nessuna configurazione manuale necessaria!**

Se vuoi personalizzare il servizio systemd dopo la creazione:

```bash
sudo nano /etc/systemd/system/nome-progetto.service
sudo systemctl daemon-reload
sudo systemctl restart nome-progetto
```

### Docker Compose

Il workflow rileva automaticamente `docker-compose.yml`.

Assicurati che il compose file sia configurato correttamente:

```yaml
version: '3.8'
services:
  app:
    build: .
    restart: always
    env_file: .env
```

---

## 🔒 Sicurezza e Best Practices

### Tailscale per connessioni sicure

- ✅ SSH non esposto pubblicamente
- ✅ Funziona dietro CG-NAT
- ✅ Connessione crittografata end-to-end
- ✅ Nessun port forwarding necessario

### Gestione delle chiavi

- ✅ Non committare mai chiavi private nel repository
- ✅ Usa sempre i GitHub Secrets per dati sensibili
- ✅ Rigenera le chiavi periodicamente

### Firewall

Con Tailscale, puoi mantenere il firewall restrittivo:

```bash
sudo apt install ufw -y
sudo ufw allow from 100.64.0.0/10  # Solo traffico Tailscale
sudo ufw enable
```

---

## 🐛 Troubleshooting

### Il workflow fallisce alla connessione Tailscale

- Verifica `TS_OAUTH_CLIENT_ID` e `TS_OAUTH_SECRET`
- Controlla che il tag `ci` sia configurato negli ACLs
- Verifica che Tailscale sia attivo sul Pi: `sudo tailscale status`

### Il workflow fallisce alla connessione SSH

- Verifica `SSH_HOST` (deve essere l'IP Tailscale: `100.x.x.x`)
- Controlla che `SSH_PRIVATE_KEY` sia completo (con BEGIN e END)
- Verifica che la chiave pubblica sia su GitHub SSH keys

### Il file .env non viene creato

- Verifica che `ENV_FILE` sia configurato nei secrets
- Controlla nei log del workflow se ci sono errori

### Il servizio non parte

```bash
# Vedi i log del servizio
sudo journalctl -u nome-progetto -n 50

# Verifica lo stato
sudo systemctl status nome-progetto

# Riavvia manualmente
sudo systemctl restart nome-progetto
```

### Python: ModuleNotFoundError

Il virtual environment potrebbe non essere attivato correttamente nel servizio.

Verifica che in `/etc/systemd/system/nome-progetto.service`:

```ini
ExecStart=/home/pi/projects/nome-progetto/venv/bin/python main.py
```

Usi il path **completo** al Python del venv.

### Problemi di permessi

```bash
# Sul Raspberry Pi
sudo chown -R $USER:$USER ~/projects
```

---

## 📚 Risorse Utili

- [Documentazione GitHub Actions](https://docs.github.com/en/actions)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [PM2 Documentation](https://pm2.keymetrics.io/docs/usage/quick-start/)
- [Systemd Service Files](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

---

## 🎉 Conclusione

Ora hai un sistema completo di CI/CD casalingo! 

**Caratteristiche:**
- ✅ Deploy automatico ad ogni push
- ✅ Creazione automatica servizi systemd
- ✅ Gestione automatica dipendenze
- ✅ Verifica post-deploy
- ✅ Sicurezza con Tailscale
- ✅ Supporto multi-progetto

Buon coding! 🚀

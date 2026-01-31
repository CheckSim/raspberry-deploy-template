# Setup Secrets su GitHub

Per configurare i secrets del progetto e abilitare il deploy automatico su Raspberry Pi tramite Tailscale.

## 🔐 Secrets obbligatori

Vai su **Settings** → **Secrets and variables** → **Actions** del tuo repository e aggiungi:

### `TS_OAUTH_CLIENT_ID` e `TS_OAUTH_SECRET`

**OAuth credentials di Tailscale per GitHub Actions**

**Come ottenerle:**

1. Vai su [login.tailscale.com/admin/settings/oauth](https://login.tailscale.com/admin/settings/oauth)
2. Clicca **"Generate OAuth Client"**
3. Compila:
   - **Description**: `GitHub Actions Deploy`
   - **Tags**: `tag:ci`
4. Clicca **"Generate client"**
5. Copia **Client ID** → salvalo come `TS_OAUTH_CLIENT_ID`
6. Copia **Client secret** → salvalo come `TS_OAUTH_SECRET`

⚠️ **IMPORTANTE**: Il Client secret viene mostrato solo una volta! Salvalo subito.

**Configura anche gli ACLs di Tailscale:**

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

### `SSH_HOST`

**IP Tailscale del tuo Raspberry Pi**

**Valore**: es. `100.64.1.2`

**Come ottenerlo**: Sul Raspberry Pi esegui:
```bash
tailscale ip -4
```

---

### `SSH_USER`

**Username sul Raspberry Pi**

**Valore**: Solitamente `pi`

**Come ottenerlo**: Sul Raspberry Pi esegui:
```bash
whoami
```

---

### `SSH_PRIVATE_KEY`

**Chiave privata SSH per autenticazione**

**Valore**: L'intera chiave privata, da `-----BEGIN` a `-----END`

**Come ottenerla**: Sul Raspberry Pi esegui:
```bash
cat ~/.ssh/id_ed25519
```

Copia **TUTTO** l'output, incluse le righe BEGIN e END.

---

### `GH_TOKEN_DEPLOY`

**Personal Access Token di GitHub per clonare repository privati**

**Come crearlo:**

1. Vai su GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Clicca **"Generate new token (classic)"**
3. Dai un nome: `Raspberry Pi Deploy`
4. Seleziona scope: `repo` (Full control of private repositories)
5. Clicca **"Generate token"**
6. Copia il token (inizia con `ghp_...`)

⚠️ Il token si vede solo una volta! Salvalo subito.

---

### `ENV_FILE`

**Contenuto completo del file `.env` del progetto**

**Valore**: Tutte le variabili d'ambiente necessarie, una per riga

**Esempio per un Bot Telegram:**
```
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
DATABASE_URL=postgresql://user:password@localhost:5432/botdb
NODE_ENV=production
PORT=3000
```

**Esempio per una WebApp:**
```
DATABASE_URL=postgresql://user:password@localhost:5432/webapp
API_KEY=sk-abc123xyz
SECRET_KEY=your-super-secret-key
JWT_SECRET=jwt-token-secret
NODE_ENV=production
PORT=8080
REDIS_URL=redis://localhost:6379
```

**Nota**: Se il tuo progetto non ha bisogno di variabili d'ambiente, puoi non configurare questo secret.

---

## 🔧 Secrets opzionali

### `PYTHON_VERSION`

**Versione specifica di Python da usare**

**Valore**: es. `3.12`, `3.11`, `3.10`

**Default**: Se non specificato, usa `python3` (la versione predefinita del sistema)

**Quando usarlo**: 
- Se il tuo progetto richiede una versione specifica di Python
- Se hai installato Python 3.12 manualmente (come nel nostro setup)

**Esempio**: Per usare Python 3.12, imposta `PYTHON_VERSION` a `3.12`

---

## 📋 Riepilogo rapido

| Secret | Obbligatorio | Esempio |
|--------|--------------|---------|
| `TS_OAUTH_CLIENT_ID` | ✅ Sì | `k...` |
| `TS_OAUTH_SECRET` | ✅ Sì | `tskey-client-...` |
| `SSH_HOST` | ✅ Sì | `100.64.1.2` |
| `SSH_USER` | ✅ Sì | `pi` |
| `SSH_PRIVATE_KEY` | ✅ Sì | `-----BEGIN OPENSSH...` |
| `GH_TOKEN_DEPLOY` | ✅ Sì | `ghp_...` |
| `ENV_FILE` | ✅ Sì (se servono env vars) | `TELEGRAM_BOT_TOKEN=...` |
| `PYTHON_VERSION` | ❌ No | `3.12` |

---

## ✅ Verifica configurazione

Dopo aver configurato tutti i secrets:

### 1. Controlla che Tailscale sia configurato

Sul Raspberry Pi:
```bash
# Verifica che Tailscale sia attivo
sudo tailscale status

# Verifica l'IP Tailscale
tailscale ip -4
```

### 2. Verifica gli ACLs di Tailscale

- Vai su [login.tailscale.com/admin/acls/file](https://login.tailscale.com/admin/acls/file)
- Assicurati che `tag:ci` sia definito in `tagOwners`
- Assicurati che `tag:ci` abbia accesso alla porta 22

### 3. Fai un test di deploy

```bash
git add .
git commit -m "Test deploy"
git push origin main
```

### 4. Monitora il workflow

1. Vai su GitHub → repository → **Actions**
2. Clicca sul workflow "Deploy to Raspberry Pi"
3. Osserva i log in tempo reale

Se tutto è configurato correttamente:
- ✅ Tailscale si connette
- ✅ SSH funziona
- ✅ Repository viene clonato/aggiornato
- ✅ File .env viene creato
- ✅ Dipendenze vengono installate
- ✅ Servizio systemd viene creato (se non esiste)
- ✅ Servizio viene riavviato
- ✅ Verifica che il servizio sia attivo

### 5. Verifica sul Raspberry Pi

```bash
# Connettiti al Pi
ssh pi@100.x.x.x  # Usa il tuo IP Tailscale

# Controlla il progetto
cd ~/projects/nome-repository
ls -la

# Verifica che .env sia stato creato
cat .env

# Per progetti Python, verifica il servizio
sudo systemctl status nome-repository

# Vedi i log
sudo journalctl -u nome-repository -f
```

---

## 🐛 Troubleshooting

### ❌ Errore: "Permission denied (publickey)"

**Causa**: La chiave privata SSH non è corretta o incompleta.

**Fix**: 
- Verifica che `SSH_PRIVATE_KEY` includa `-----BEGIN OPENSSH PRIVATE KEY-----` e `-----END OPENSSH PRIVATE KEY-----`
- Assicurati di non aver aggiunto spazi extra o caratteri

---

### ❌ Errore: "Connection timeout" o "Unable to connect"

**Causa**: Tailscale non è configurato correttamente o gli ACLs bloccano la connessione.

**Fix**:
- Verifica che `TS_OAUTH_CLIENT_ID` e `TS_OAUTH_SECRET` siano corretti
- Controlla che il tag `ci` sia negli ACLs e permetta connessioni alla porta 22
- Verifica che Tailscale sia attivo sul Pi: `sudo tailscale status`

---

### ❌ Errore: "fatal: could not read Username"

**Causa**: Il token `GH_TOKEN_DEPLOY` non è configurato o non è valido.

**Fix**:
- Verifica che `GH_TOKEN_DEPLOY` sia impostato nei secrets
- Assicurati che il token abbia lo scope `repo`
- Rigenera il token se è scaduto

---

### ❌ Il file .env non viene creato

**Causa**: Il secret `ENV_FILE` non è configurato o è vuoto.

**Fix**:
- Controlla che `ENV_FILE` sia impostato nei secrets
- Verifica che contenga effettivamente le variabili (non sia vuoto)

---

### ❌ Il servizio non parte dopo il deploy

**Causa**: Errori nell'applicazione o configurazione mancante.

**Fix**:
```bash
# Sul Raspberry Pi, vedi i log
sudo journalctl -u nome-progetto -n 50

# Testa manualmente l'applicazione
cd ~/projects/nome-progetto
source venv/bin/activate  # Per Python
python main.py  # Vedi gli errori
```

---

## 📝 Checklist finale

Prima di fare il primo deploy, verifica:

- [ ] `TS_OAUTH_CLIENT_ID` configurato
- [ ] `TS_OAUTH_SECRET` configurato
- [ ] Tag `ci` configurato negli ACLs di Tailscale
- [ ] `SSH_HOST` configurato (IP Tailscale)
- [ ] `SSH_USER` configurato
- [ ] `SSH_PRIVATE_KEY` configurato (chiave completa)
- [ ] Chiave pubblica SSH aggiunta a GitHub (Settings → SSH keys)
- [ ] `GH_TOKEN_DEPLOY` configurato con scope `repo`
- [ ] `ENV_FILE` configurato con tutte le variabili necessarie
- [ ] (Opzionale) `PYTHON_VERSION` configurato se usi Python 3.12
- [ ] Tailscale attivo sul Raspberry Pi
- [ ] Directory `~/projects` creata sul Pi
- [ ] Sudo configurato senza password sul Pi

Tutto pronto? Fai push e guarda la magia! 🚀

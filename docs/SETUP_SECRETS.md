# Setup Secrets su GitHub

Per configurare i secrets del progetto e abilitare il deploy automatico su Raspberry Pi tramite Tailscale.

## 🔐 Secrets obbligatori (Deploy SSH + Tailscale)

Vai su **Settings** → **Secrets and variables** → **Actions** del tuo repository e aggiungi:

### `TS_OAUTH_CLIENT_ID` e `TS_OAUTH_SECRET`
- **Valore**: OAuth credentials di Tailscale
- **Come ottenerle**:
  1. Vai su [login.tailscale.com/admin/settings/oauth](https://login.tailscale.com/admin/settings/oauth)
  2. Clicca **Generate OAuth Client**
  3. Nella descrizione scrivi: `GitHub Actions Deploy`
  4. In **Tags**, scrivi: `tag:ci`
  5. Clicca **Generate client**
  6. Copia **Client ID** (salva come `TS_OAUTH_CLIENT_ID`)
  7. Copia **Client secret** (salva come `TS_OAUTH_SECRET`)
  
**IMPORTANTE**: Il Client secret viene mostrato solo una volta! Salvalo subito.

### `SSH_HOST`
- **Valore**: IP Tailscale del tuo Raspberry Pi (es. `100.x.x.x`)
- **Come ottenerlo**: Sul Raspberry Pi esegui `tailscale ip -4`

### `SSH_USER`
- **Valore**: Username sul Raspberry Pi (solitamente `pi`)

### `SSH_PRIVATE_KEY`
- **Valore**: Chiave privata SSH dal Raspberry Pi
- **Come ottenerla**:
  ```bash
  # Sul Raspberry Pi
  cat ~/.ssh/id_ed25519
  ```
- **Importante**: Copia TUTTO, incluso `-----BEGIN` e `-----END`

### `SSH_PORT` (opzionale)
- **Valore**: `22` (o la porta SSH personalizzata se l'hai cambiata)
- Se non specifichi, usa 22 di default

---

## 📦 Secrets applicazione

### `ENV_FILE`
- **Valore**: Contenuto completo del file `.env`
- **Come crearlo**: Copia il contenuto di `.env.example`, sostituisci i valori e incollalo qui

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
```

---

## ✅ Verifica configurazione

Dopo aver configurato i secrets:

1. **Verifica il tag ci negli ACLs di Tailscale**
   - Vai su [login.tailscale.com/admin/acls/file](https://login.tailscale.com/admin/acls/file)
   - Assicurati che `tag:ci` sia definito in `tagOwners` e abbia accesso SSH

2. **Fai un commit e push qualsiasi**
   ```bash
   git add .
   git commit -m "Test deploy"
   git push origin main
   ```

2. **Controlla Actions**
   - Vai su **Actions** nel repository
   - Dovresti vedere il workflow "Deploy to Raspberry Pi" in esecuzione
   - Clicca sul workflow per vedere i log in tempo reale

3. **Verifica sul Raspberry Pi**
   ```bash
   # Connettiti al Pi
   ssh pi@your-pi-ip
   
   # Controlla che il progetto sia stato deployato
   cd ~/projects/nome-repository
   ls -la
   
   # Verifica che .env sia stato creato
   cat .env
   ```

---

## 🐛 Troubleshooting

### ❌ Errore: "Permission denied (publickey)"
- Verifica che `SSH_PRIVATE_KEY` sia corretto
- Controlla che la chiave pubblica sia su GitHub (Settings → SSH keys)

### ❌ Errore: "Connection refused"
- Verifica che `SSH_HOST` sia corretto
- Controlla che SSH sia abilitato sul Pi: `sudo systemctl status ssh`

### ❌ Il .env non viene creato
- Verifica che il secret `ENV_FILE` sia configurato
- Controlla nei log del workflow se ci sono errori

### ❌ L'applicazione non si riavvia
- Per PM2: `pm2 logs` sul Pi
- Per systemd: `journalctl --user -u nome-servizio`
- Per Docker: `docker-compose logs`

---

## 📝 Checklist finale

Prima di fare il primo deploy, verifica:

- [ ] `SSH_HOST` configurato
- [ ] `SSH_USER` configurato
- [ ] `SSH_PRIVATE_KEY` configurato (chiave completa)
- [ ] `ENV_FILE` configurato con tutte le variabili necessarie
- [ ] Chiave pubblica SSH aggiunta a GitHub
- [ ] Raspberry Pi raggiungibile via SSH
- [ ] Directory `~/projects` creata sul Pi
- [ ] PM2/systemd configurato (se necessario)

Tutto pronto? Fai push e guarda la magia! 🚀

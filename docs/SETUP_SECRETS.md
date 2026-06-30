# Setup Secrets on GitHub

To configure the project secrets and enable automatic deployment on Raspberry Pi via Tailscale.

## 🔐 Required Secrets

Go to **Settings** → **Secrets and variables** → **Actions** in your repository and add:

### `TS_OAUTH_CLIENT_ID` and `TS_OAUTH_SECRET`

**Tailscale OAuth credentials for GitHub Actions**

**How to get them:**

1. Go to [login.tailscale.com/admin/settings/oauth](https://login.tailscale.com/admin/settings/oauth)
2. Click **"Generate OAuth Client"**
3. Fill in:
   - **Description**: `GitHub Actions Deploy`
   - **Tags**: `tag:ci`
4. Click **"Generate client"**
5. Copy **Client ID** → save it as `TS_OAUTH_CLIENT_ID`
6. Copy **Client secret** → save it as `TS_OAUTH_SECRET`

⚠️ **IMPORTANT**: The Client secret is shown only once! Save it immediately.

**Also configure Tailscale ACLs:**

1. Go to [login.tailscale.com/admin/acls/file](https://login.tailscale.com/admin/acls/file)
2. Add under `"tagOwners"`:
   ```json
   "tagOwners": {
     "tag:ci": ["autogroup:admin"],
   },
   ```
3. Add under `"acls"`:
   ```json
   "acls": [
     {
       "action": "accept",
       "src": ["tag:ci"],
       "dst": ["*:22"],
     },
   ],
   ```
4. Save

---

### `SSH_HOST`

**Tailscale IP of your Raspberry Pi**

**Value**: e.g., `100.64.1.2`

**How to get it**: On the Raspberry Pi, run:
```bash
tailscale ip -4
```

---

### `SSH_USER`

**Username on the Raspberry Pi**

**Value**: Usually `pi`

**How to get it**: On the Raspberry Pi, run:
```bash
whoami
```

---

### `SSH_PRIVATE_KEY`

**SSH private key for authentication**

**Value**: The entire private key, from `-----BEGIN` to `-----END`

**How to get it**: On the Raspberry Pi, run:
```bash
cat ~/.ssh/id_ed25519
```

Copy **ALL** the output, including the BEGIN and END lines.

---

### `GH_TOKEN_DEPLOY`

**GitHub Personal Access Token to clone private repositories**

**How to create it:**

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click **"Generate new token (classic)"**
3. Give it a name: `Raspberry Pi Deploy`
4. Select scope: `repo` (Full control of private repositories)
5. Click **"Generate token"**
6. Copy the token (starts with `ghp_...`)

⚠️ The token is shown only once! Save it immediately.

---

### `ENV_FILE`

**Complete content of the project's `.env` file**

**Value**: All required environment variables, one per line

**Example for a Telegram Bot:**
```
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
DATABASE_URL=postgresql://user:password@localhost:5432/botdb
NODE_ENV=production
```

**Example for a WebApp:**
```
DATABASE_URL=postgresql://user:password@localhost:5432/webapp
API_KEY=sk-abc123xyz
SECRET_KEY=your-super-secret-key
JWT_SECRET=jwt-token-secret
NODE_ENV=production
PORT=8080
REDIS_URL=redis://localhost:6379
```

**Note**: If your project does not need environment variables, you don't need to configure this secret.

---

## 🔧 Optional Secrets

### `PYTHON_VERSION`

**Specific Python version to use**

**Value**: e.g., `3.12`, `3.11`, `3.10`

**Default**: If not specified, it uses `python3` (the system's default version)

**When to use it**: 
- If your project requires a specific version of Python
- If you have installed Python 3.12 manually (as in our setup)

**Example**: To use Python 3.12, set `PYTHON_VERSION` to `3.12`

---

## 📋 Quick Summary

| Secret | Required | Example |
|--------|----------|---------|
| `TS_OAUTH_CLIENT_ID` | ✅ Yes | `k...` |
| `TS_OAUTH_SECRET` | ✅ Yes | `tskey-client-...` |
| `SSH_HOST` | ✅ Yes | `100.64.1.2` |
| `SSH_USER` | ✅ Yes | `pi` |
| `SSH_PRIVATE_KEY` | ✅ Yes | `-----BEGIN OPENSSH...` |
| `GH_TOKEN_DEPLOY` | ✅ Yes | `ghp_...` |
| `ENV_FILE` | ✅ Yes (if env vars are needed) | `TELEGRAM_BOT_TOKEN=...` |
| `PYTHON_VERSION` | ❌ No | `3.12` |

---

## ✅ Verify Configuration

After configuring all secrets:

### 1. Check that Tailscale is configured

On the Raspberry Pi:
```bash
# Verify that Tailscale is active
sudo tailscale status

# Verify Tailscale IP
tailscale ip -4
```

### 2. Verify Tailscale ACLs

- Go to [login.tailscale.com/admin/acls/file](https://login.tailscale.com/admin/acls/file)
- Ensure `tag:ci` is defined in `tagOwners`
- Ensure `tag:ci` has access to port 22

### 3. Run a deployment test

```bash
git add .
git commit -m "Test deploy"
git push origin main
```

### 4. Monitor the workflow

1. Go to GitHub → repository → **Actions**
2. Click on the "Deploy to Raspberry Pi" workflow
3. Observe real-time logs

If everything is configured correctly:
- ✅ Tailscale connects
- ✅ SSH works
- ✅ Repository is cloned/updated
- ✅ `.env` file is created
- ✅ Dependencies are installed
- ✅ systemd service is created (if it doesn't exist)
- ✅ Service is restarted
- ✅ Verify that the service is active

### 5. Verify on the Raspberry Pi

```bash
# Connect to the Pi
ssh pi@100.x.x.x  # Use your Tailscale IP

# Check the project
cd ~/projects/repository-name
ls -la

# Verify that .env has been created
cat .env

# For Python projects, verify the service
sudo systemctl status repository-name

# View logs
sudo journalctl -u repository-name -f
```

---

## 🐛 Troubleshooting

### ❌ Error: "Permission denied (publickey)"

**Cause**: The SSH private key is incorrect or incomplete.

**Fix**: 
- Verify that `SSH_PRIVATE_KEY` includes `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----`
- Ensure you have not added extra spaces or characters

---

### ❌ Error: "Connection timeout" or "Unable to connect"

**Cause**: Tailscale is not configured correctly or ACLs are blocking the connection.

**Fix**:
- Verify that `TS_OAUTH_CLIENT_ID` and `TS_OAUTH_SECRET` are correct
- Check that the `ci` tag is in ACLs and allows connections to port 22
- Verify that Tailscale is active on the Pi: `sudo tailscale status`

---

### ❌ Error: "fatal: could not read Username"

**Cause**: The `GH_TOKEN_DEPLOY` token is not configured or is invalid.

**Fix**:
- Verify that `GH_TOKEN_DEPLOY` is set in secrets
- Ensure the token has the `repo` scope
- Regenerate the token if it has expired

---

### ❌ The .env file is not created

**Cause**: The `ENV_FILE` secret is not configured or is empty.

**Fix**:
- Check that `ENV_FILE` is set in secrets
- Verify that it actually contains variables (is not empty)

---

### ❌ The service does not start after deployment

**Cause**: Errors in the application or missing configuration.

**Fix**:
```bash
# On the Raspberry Pi, view logs
sudo journalctl -u project-name -n 50

# Test the application manually
cd ~/projects/project-name
source venv/bin/activate  # For Python
python main.py  # View errors
```

---

## 📝 Final Checklist

Before running the first deployment, verify:

- [ ] `TS_OAUTH_CLIENT_ID` configured
- [ ] `TS_OAUTH_SECRET` configured
- [ ] Tag `ci` configured in Tailscale ACLs
- [ ] `SSH_HOST` configured (Tailscale IP)
- [ ] `SSH_USER` configured
- [ ] `SSH_PRIVATE_KEY` configured (complete key)
- [ ] Public SSH key added to GitHub (Settings → SSH keys)
- [ ] `GH_TOKEN_DEPLOY` configured with `repo` scope
- [ ] `ENV_FILE` configured with all necessary variables
- [ ] (Optional) `PYTHON_VERSION` configured if using Python 3.12
- [ ] Tailscale active on the Raspberry Pi
- [ ] `~/projects` directory created on the Pi
- [ ] Passwordless sudo configured on the Pi

All set? Push and watch the magic! 🚀

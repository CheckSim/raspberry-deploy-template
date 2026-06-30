# 🚀 Raspberry Pi Deploy Template

Template for automatic deployment on Raspberry Pi via GitHub Actions with Tailscale.

![Deploy](https://github.com/CheckSim/raspberry-deploy-template/workflows/Deploy%20to%20Raspberry%20Pi/badge.svg)

## 📋 What this template includes

- ✅ **GitHub Actions Workflow** for automatic deployment via Tailscale
- ✅ **Automatic setup of systemd services** for Python projects
- ✅ **Multi-stack support**: Node.js (PM2), Python (systemd), Docker Compose
- ✅ **Automatic secrets management** via `.env` file
- ✅ **Post-deploy verification** with service status check
- ✅ **Automatic setup script** for Raspberry Pi
- ✅ **Optimized for Raspberry Pi 2/4/5**
- ✅ **Complete documentation**

## 🎯 Quick Start

### 1. Configure the Raspberry Pi

**Option A: Automatic Setup (RECOMMENDED)**

On the Raspberry Pi, download and run the setup script:

```bash
curl -fsSL https://raw.githubusercontent.com/TUO_USERNAME/raspberry-deploy-template/main/setup-raspberry.sh -o setup-raspberry.sh
chmod +x setup-raspberry.sh
./setup-raspberry.sh
```

The script will install everything automatically: Python 3.12, Node.js, PM2, Tailscale, SSH keys, sudo configuration.

**Option B: Manual Setup**

Follow the [complete guide](docs/SETUP_SECRETS.md) to manually configure each component.

### 2. Use this template

Click on **"Use this template"** at the top to create a new repository from the template.

### 3. Configure secrets

Go to **Settings** → **Secrets and variables** → **Actions** and configure:

**Required secrets:**
- `TS_OAUTH_CLIENT_ID` - Tailscale OAuth Client ID
- `TS_OAUTH_SECRET` - Tailscale OAuth Client Secret
- `SSH_HOST` - Tailscale IP of the Pi (e.g., `100.x.x.x`, get it with `tailscale ip -4`)
- `SSH_USER` - Username (e.g., `pi`)
- `SSH_PRIVATE_KEY` - SSH private key (from `cat ~/.ssh/id_ed25519`)
- `GH_TOKEN_DEPLOY` - GitHub Personal Access Token with `repo` scope
- `ENV_FILE` - Content of the `.env` file (see `.env.example`)

**Optional secrets:**
- `PYTHON_VERSION` - Specific Python version (e.g., `3.12`)

📖 [Detailed secrets configuration guide](docs/SETUP_SECRETS.md)

### 4. Push and deploy!

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

The deployment will start automatically! 🎉

---

## 📚 Complete documentation

For the complete guide on how to configure the Raspberry Pi and all details:

👉 **Scroll down in this README for the complete guide**

---

## 🎯 How to use this template for new projects

### Method 1: Use the "Use this template" button (Recommended)

1. Go to the template repository page on GitHub
2. Click the green **"Use this template"** button in the top right
3. Select **"Create a new repository"**
4. Fill in:
   - **Repository name**: your new project's name
   - **Description**: project description
   - **Public** or **Private**: choose visibility
5. Click **"Create repository"**
6. Clone the new repository:
   ```bash
   git clone git@github.com:tuo-username/nuovo-progetto.git
   cd nuovo-progetto
   ```
7. Configure secrets (see [docs/SETUP_SECRETS.md](docs/SETUP_SECRETS.md))
8. Develop your project!

### Method 2: Clone and reconfigure manually

```bash
# Clone the template
git clone git@github.com:tuo-username/raspberry-deploy-template.git nuovo-progetto
cd nuovo-progetto

# Remove original remote
git remote remove origin

# Create a new repository on GitHub, then:
git remote add origin git@github.com:tuo-username/nuovo-progetto.git
git push -u origin main
```

### What to do after creating the project from the template

1. ✅ **Configure GitHub secrets** (see [docs/SETUP_SECRETS.md](docs/SETUP_SECRETS.md))
2. ✅ **Copy `.env.example` to `.env`** locally and configure your variables
3. ✅ **Add the content of `.env` to the `ENV_FILE` secret** on GitHub
4. ✅ **Develop your project** (Node.js, Python, Docker, etc.)
5. ✅ **Commit and push** - deployment will start automatically!

---

## 🔥 Advanced features

### Automatic deployment of Python projects

The workflow:
- ✅ Automatically detects Python projects (via `requirements.txt`)
- ✅ Looks for entry point files: `main.py`, `bot.py`, `app.py`, `run.py`
- ✅ **Automatically creates the systemd service** if it doesn't exist
- ✅ Configures auto-restart in case of crashes
- ✅ Verifies that the service is active after deployment
- ✅ Shows logs if there are errors

**No manual configuration required!**

### Automatic deployment of Node.js projects

The workflow:
- ✅ Automatically detects Node.js projects (via `package.json`)
- ✅ Installs dependencies with `npm install`
- ✅ Runs build if a `build` script is present
- ✅ Manages PM2 automatically (restart or start)

### Docker Compose Support

The workflow:
- ✅ Automatically detects `docker-compose.yml`
- ✅ Rebuilds and restarts containers
- ⚠️ Recommended only for Raspberry Pi 4/5

---

## 🛠️ Files and structure

```
raspberry-deploy-template/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions workflow
├── docs/
│   └── SETUP_SECRETS.md        # Secrets configuration guide
├── setup-raspberry.sh          # Raspberry Pi automatic setup script
├── .env.example                # Environment variables template
├── .gitignore                  # Files to ignore
└── README.md                   # This guide
```

---

## 🔒 Security

- ✅ **Tailscale**: Secure connection without exposing SSH publicly
- ✅ **No port forwarding**: Works even behind CG-NAT
- ✅ **GitHub Secrets**: Sensitive variables never committed to the repository
- ✅ **Separate SSH keys**: One for GitHub, one for GitHub Actions

---

## 🌟 Usage examples

### Telegram Bot

```python
# main.py
import os
from telegram import Update
from telegram.ext import Application

TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')

app = Application.builder().token(TOKEN).build()
app.run_polling()
```

`ENV_FILE` Secret:
```
TELEGRAM_BOT_TOKEN=123456789:ABCdef...
```

### REST API with Flask

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

`ENV_FILE` Secret:
```
PORT=5000
DATABASE_URL=postgresql://...
SECRET_KEY=your-secret-key
```

### Discord Bot with Node.js

```javascript
// index.js
require('dotenv').config();
const { Client, GatewayIntentBits } = require('discord.js');

const client = new Client({ 
  intents: [GatewayIntentBits.Guilds] 
});

client.login(process.env.DISCORD_TOKEN);
```

`ENV_FILE` Secret:
```
DISCORD_TOKEN=your-discord-token
```

---

## 📊 Monitoring

### Check service status

```bash
# For Python (systemd)
sudo systemctl status nome-progetto
sudo journalctl -u nome-progetto -f

# For Node.js (PM2)
pm2 list
pm2 logs nome-progetto

# For Docker
docker compose ps
docker compose logs -f
```

---

## 🆘 Support

Problems? Check:
- 📖 [Complete guide](README.md#guide-automatic-deployment-from-github-to-raspberry-pi)
- 🔐 [Setup secrets](docs/SETUP_SECRETS.md)
- 🐛 [Troubleshooting](README.md#troubleshooting)

---

## 📝 License

MIT

---

# Guide: Automatic Deployment from GitHub to Raspberry Pi

This guide will help you set up an automatic deployment system that pushes code from GitHub to your Raspberry Pi every time you commit.

## 📋 Prerequisites

- A Raspberry Pi with Raspberry Pi OS installed
- SSH access to the Raspberry Pi
- A GitHub account
- Internet connection on the Raspberry Pi

## ⚠️ Note for Raspberry Pi 2

If you have a **Raspberry Pi 2 v1.1** (1GB RAM, 32-bit):
- Use **Raspberry Pi OS Lite (32-bit, Legacy)**
- Avoid Docker when possible (very heavy on 1GB RAM)
- **Prefer PM2 for Node.js and systemd for Python**
- Limit to 1-2 projects concurrently
- Add swap (the setup script does it automatically)

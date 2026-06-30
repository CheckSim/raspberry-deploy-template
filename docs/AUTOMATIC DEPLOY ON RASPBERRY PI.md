# Guide: Automatic Deployment from GitHub to Raspberry Pi

This guide will help you set up an automatic deployment system that pushes code from GitHub to your Raspberry Pi every time you commit.

## 📋 Prerequisites

- A Raspberry Pi with Raspberry Pi OS installed
- SSH access to the Raspberry Pi (or monitor and keyboard for initial setup)
- A GitHub account
- Internet connection on the Raspberry Pi

## ⚠️ Note for Raspberry Pi 2

If you have a **Raspberry Pi 2 v1.1** (1GB RAM, 32-bit):
- Use **Raspberry Pi OS Lite (32-bit, Legacy)**
- Avoid Docker (very heavy on 1GB RAM)
- **Prefer PM2 for Node.js and systemd for Python**
- Limit to 1-2 projects concurrently
- Add swap (the setup script does it automatically)

If you have a **Raspberry Pi 4/5**:
- Use **Raspberry Pi OS Lite (64-bit)**
- Docker will work without issues
- You can manage multiple projects concurrently

---

## 🚀 Quick Setup with Automatic Script

### Method 1: Automatic Setup (RECOMMENDED)

On the newly configured Raspberry Pi, run:

```bash
# Download the setup script
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/raspberry-deploy-template/main/setup-raspberry.sh -o setup-raspberry.sh

# Or manually create the file and copy the script contents

# Make executable
chmod +x setup-raspberry.sh

# Run the script
./setup-raspberry.sh
```

The script will automatically install:
- ✅ Python 3.12
- ✅ Node.js and PM2
- ✅ Tailscale
- ✅ SSH keys for GitHub
- ✅ Passwordless sudo configuration
- ✅ `~/projects` directory
- ✅ (Optional) Docker
- ✅ (Optional) Optimizations for Pi 2

**Follow the interactive instructions of the script** and save the information it provides!

---

## 🛠️ Manual Setup (if you prefer complete control)

If you prefer to manually configure each component, follow these steps:

### 1.1 SSH Connection

Ensure SSH is enabled on the Pi. If you haven't done so yet:

```bash
sudo raspi-config
# Go to: Interface Options → SSH → Enable
```

Note your Raspberry Pi's IP address:

```bash
hostname -I
```

### 1.2 System Update

```bash
sudo apt update
sudo apt upgrade -y
```

### 1.3 Installing Python 3.12

```bash
# Install dependencies
sudo apt install -y build-essential libssl-dev libffi-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev \
    libncursesw5-dev xz-utils tk-dev liblzma-dev

# Download and compile Python 3.12
cd /tmp
wget https://www.python.org/ftp/python/3.12.7/Python-3.12.7.tgz
tar -xzf Python-3.12.7.tgz
cd Python-3.12.7
./configure --enable-optimizations
make -j4
sudo make altinstall

# Install pip
curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.12

# Verify
python3.12 --version
```

⚠️ **Note**: Compilation can take 20-30 minutes on a Raspberry Pi 2.

### 1.4 Installing Node.js and PM2

```bash
# Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# PM2
sudo npm install -g pm2
pm2 startup systemd -u $USER --hp $HOME
```

### 1.5 Installing Docker (Pi 4/5 ONLY, NOT RECOMMENDED for Pi 2)

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Restart to apply permissions
```

### 1.6 Installing and Configuring Tailscale

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start and authenticate
sudo tailscale up

# Get Tailscale IP
tailscale ip -4
```

Open the link in your browser and log in. Save the Tailscale IP (e.g., `100.x.x.x`) - you will use it as `SSH_HOST`.

### 1.7 SSH Configuration

```bash
# Create .ssh directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate SSH key for GitHub
ssh-keygen -t ed25519 -C "github-deploy" -f ~/.ssh/id_ed25519 -N ""

# Show public key (to add to GitHub → Settings → SSH keys)
cat ~/.ssh/id_ed25519.pub

# Show private key (to use as SSH_PRIVATE_KEY secret)
cat ~/.ssh/id_ed25519
```

**Add the public key to GitHub:**
1. Go to GitHub.com → Settings → SSH and GPG keys
2. Click "New SSH key"
3. Paste the public key

### 1.8 Passwordless Sudo Configuration

```bash
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/99-deploy-nopasswd
sudo chmod 440 /etc/sudoers.d/99-deploy-nopasswd
```

### 1.9 Creating Projects Directory

```bash
mkdir -p ~/projects
```

### 1.10 (Optional) Optimizations for Raspberry Pi 2

```bash
# Increase swap
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

---

## 🔐 Tailscale OAuth Configuration for GitHub Actions

### 1. Create OAuth Client

1. Go to [login.tailscale.com/admin/settings/oauth](https://login.tailscale.com/admin/settings/oauth)
2. Click **"Generate OAuth Client"**
3. Fill in:
   - **Description**: `GitHub Actions Deploy`
   - **Tags**: `tag:ci`
4. Click **"Generate client"**
5. Copy **Client ID** and **Client secret** (the secret is shown only once!)

### 2. Configure ACL with "ci" tag

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

## 🔑 Secrets Configuration on GitHub

For each project you want to deploy:

1. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"**
3. Add the following secrets:

### Required Secrets:

| Name | Value | How to get it |
|------|--------|----------------|
| `TS_OAUTH_CLIENT_ID` | Tailscale OAuth Client ID | From Tailscale admin console |
| `TS_OAUTH_SECRET` | Tailscale OAuth Client Secret | From Tailscale admin console |
| `SSH_HOST` | Tailscale IP of the Pi (e.g., `100.x.x.x`) | `tailscale ip -4` on the Pi |
| `SSH_USER` | Username (e.g., `pi`) | `whoami` on the Pi |
| `SSH_PRIVATE_KEY` | SSH private key | `cat ~/.ssh/id_ed25519` on the Pi |
| `GH_TOKEN_DEPLOY` | GitHub Personal Access Token | GitHub Settings → Developer settings → Personal access tokens |
| `ENV_FILE` | Content of the `.env` file | Project environment variables |

### Optional Secrets:

| Name | Value | When it is needed |
|------|--------|--------------|
| `PYTHON_VERSION` | `3.12` | To specify Python version (default: `python3`) |

### How to create `GH_TOKEN_DEPLOY`:

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. Select scope: `repo` (Full control of private repositories)
4. Copy the generated token

### Example `ENV_FILE` for Telegram bot:

```
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
DATABASE_URL=postgresql://user:password@localhost:5432/botdb
NODE_ENV=production
```

---

## 📝 Adding the Workflow to the Project

### 1. Create the workflow folder

In your local project:

```bash
mkdir -p .github/workflows
```

### 2. Create the deploy.yml file

Copy the contents of the `deploy.yml` workflow into `.github/workflows/deploy.yml`

### 3. Commit and push

```bash
git add .github/workflows/deploy.yml
git commit -m "Add automatic deployment workflow"
git push origin main
```

---

## 🚀 Testing the Deployment

### 1. Verify that the workflow has started

1. Go to GitHub → repository → **Actions** tab
2. You should see "Deploy to Raspberry Pi" running

### 2. Monitor execution

Click on the workflow to see real-time logs:
- ✅ Connecting to Tailscale
- ✅ Repository clone/update
- ✅ `.env` file creation
- ✅ Installing dependencies
- ✅ Creating systemd service (if it doesn't exist)
- ✅ Service restart
- ✅ Service status verification

### 3. Verify on the Raspberry Pi

```bash
# Connect to the Pi
ssh pi@100.x.x.x  # Use your Tailscale IP

# Check the project
cd ~/projects/nome-repository
ls -la

# Verify service (for Python projects)
sudo systemctl status nome-repository

# Verify PM2 (for Node.js projects)
pm2 list

# View logs
sudo journalctl -u nome-repository -f
```

---

## 🔄 Daily Use

Every time you push:

```bash
git add .
git commit -m "Update feature"
git push origin main
```

The deployment will start automatically! Monitor it on GitHub Actions.

---

## 🛠️ Specific Configurations per Project Type

### Node.js with PM2

The workflow automatically detects `package.json`.

**No additional configuration needed!** PM2 is managed automatically.

### Python with systemd

The workflow:
1. Detects `requirements.txt`
2. Looks for entry point files: `main.py`, `bot.py`, `app.py`, `run.py`
3. **Automatically creates the systemd service** if it doesn't exist
4. Restarts the service

**No manual configuration needed!**

If you want to customize the systemd service after creation:

```bash
sudo nano /etc/systemd/system/nome-progetto.service
sudo systemctl daemon-reload
sudo systemctl restart nome-progetto
```

### Docker Compose

The workflow automatically detects `docker-compose.yml`.

Ensure the compose file is properly configured:

```yaml
version: '3.8'
services:
  app:
    build: .
    restart: always
    env_file: .env
```

---

## 🔒 Security and Best Practices

### Tailscale for secure connections

- ✅ SSH not publicly exposed
- ✅ Works behind CG-NAT
- ✅ End-to-end encrypted connection
- ✅ No port forwarding required

### Key Management

- ✅ Never commit private keys to the repository
- ✅ Always use GitHub Secrets for sensitive data
- ✅ Regenerate keys periodically

### Firewall

With Tailscale, you can keep the firewall restrictive:

```bash
sudo apt install ufw -y
sudo ufw allow from 100.64.0.0/10  # Tailscale traffic only
sudo ufw enable
```

---

## 🐛 Troubleshooting

### The workflow fails at the Tailscale connection step

- Verify `TS_OAUTH_CLIENT_ID` and `TS_OAUTH_SECRET`
- Check that the `ci` tag is configured in ACLs
- Verify that Tailscale is active on the Pi: `sudo tailscale status`

### The workflow fails at the SSH connection step

- Verify `SSH_HOST` (must be the Tailscale IP: `100.x.x.x`)
- Check that `SSH_PRIVATE_KEY` is complete (including BEGIN and END lines)
- Verify that the public key is in GitHub SSH keys

### The .env file is not created

- Verify that `ENV_FILE` is configured in secrets
- Check the workflow logs for errors

### The service does not start

```bash
# View service logs
sudo journalctl -u nome-progetto -n 50

# Check status
sudo systemctl status nome-progetto

# Restart manually
sudo systemctl restart nome-progetto
```

### Python: ModuleNotFoundError

The virtual environment might not be correctly activated in the service.

Verify that in `/etc/systemd/system/nome-progetto.service`:

```ini
ExecStart=/home/pi/projects/nome-progetto/venv/bin/python main.py
```

You are using the **full** path to the venv's Python.

### Permission Issues

```bash
# On the Raspberry Pi
sudo chown -R $USER:$USER ~/projects
```

---

## 📚 Useful Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [PM2 Documentation](https://pm2.keymetrics.io/docs/usage/quick-start/)
- [Systemd Service Files](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

---

## 🎉 Conclusion

Now you have a complete home CI/CD system! 

**Features:**
- ✅ Automatic deployment on every push
- ✅ Automatic creation of systemd services
- ✅ Automatic dependency management
- ✅ Post-deploy verification
- ✅ Security with Tailscale
- ✅ Multi-project support

Happy coding! 🚀

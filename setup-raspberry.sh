#!/bin/bash

# ============================================
# Raspberry Pi Setup Script
# Prepara il Raspberry Pi per il deploy automatico da GitHub Actions
# ============================================

set -e

echo "🍓 Raspberry Pi Setup Script"
echo "===================================="
echo ""

# Verifica che lo script non sia eseguito come root
if [ "$EUID" -eq 0 ]; then 
   echo "❌ Non eseguire questo script come root!"
   echo "   Eseguilo come utente normale (es. pi)"
   exit 1
fi

# --------------------------------------------------
# 1. Aggiornamento sistema
# --------------------------------------------------
echo "📦 Step 1/8: Aggiornamento sistema..."
sudo apt update
sudo apt upgrade -y

# --------------------------------------------------
# 2. Installazione pacchetti base
# --------------------------------------------------
echo "📦 Step 2/8: Installazione pacchetti base..."
sudo apt install -y \
    git \
    curl \
    wget \
    htop \
    vim \
    nano \
    build-essential \
    libssl-dev \
    libffi-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    llvm \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    liblzma-dev

# --------------------------------------------------
# 3. Installazione Python 3.11
# --------------------------------------------------
echo "🐍 Step 3/8: Installazione Python 3.11..."

if ! command -v python3.11 &> /dev/null; then
    # Controlla se è disponibile nei repository
    if apt-cache show python3.11 &> /dev/null; then
        echo "   Installazione Python 3.11 dai repository Debian..."
        sudo apt install -y python3.11 python3.11-venv python3.11-dev
        echo "   ✅ Python 3.11 installato dai repository"
    else
        echo "   Python 3.11 non disponibile nei repository, compilazione da sorgente..."
        echo "   ⚠️  Questo richiederà 15-25 minuti su Raspberry Pi 2"
        
        cd /tmp
        wget https://www.python.org/ftp/python/3.11.11/Python-3.11.11.tgz
        tar -xzf Python-3.11.11.tgz
        cd Python-3.11.11
        ./configure --enable-optimizations
        make -j$(nproc)
        sudo make altinstall
        cd ~
        sudo rm -rf /tmp/Python-3.11.11*
        echo "   ✅ Python 3.11 compilato e installato"
    fi
else
    echo "   ✅ Python 3.11 già installato"
fi

# Verifica installazione
python3.11 --version

# Installa pip per Python 3.11
if ! python3.11 -m pip --version &> /dev/null 2>&1; then
    echo "   Installazione pip per Python 3.11..."
    curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.11
fi

# Rendi Python 3.11 la versione predefinita (opzionale)
echo ""
read -p "🐍 Vuoi rendere Python 3.11 la versione predefinita del sistema? [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "   Configurazione Python 3.11 come versione predefinita..."
    
    # Trova il path corretto di Python 3.11
    PYTHON311_PATH=$(command -v python3.11)
    
    sudo update-alternatives --install /usr/bin/python python "$PYTHON311_PATH" 1
    sudo update-alternatives --install /usr/bin/python3 python3 "$PYTHON311_PATH" 1
    
    # Imposta come default
    sudo update-alternatives --set python "$PYTHON311_PATH" 2>/dev/null || true
    sudo update-alternatives --set python3 "$PYTHON311_PATH" 2>/dev/null || true
    
    echo "   ✅ Python 3.11 configurato come versione predefinita"
    echo "   Verifica: $(python --version)"
else
    echo "   ⏭️  Python 3.11 installato ma non impostato come predefinito"
    echo "   Potrai usarlo con: python3.11"
fi

# --------------------------------------------------
# 4. Installazione Node.js e PM2
# --------------------------------------------------
echo "📦 Step 4/8: Installazione Node.js e PM2..."

if ! command -v node &> /dev/null; then
    echo "   Rilevamento architettura..."
    ARCH=$(dpkg --print-architecture)
    echo "   Architettura rilevata: $ARCH"
    
    if [ "$ARCH" = "armhf" ]; then
        # Raspberry Pi 2/Zero (32-bit) - Usa versione dai repository Debian
        echo "   ⚠️  Architettura armhf: installazione Node.js dai repository Debian..."
        sudo apt install -y nodejs npm
        echo "   ✅ Node.js installato: $(node --version)"
        echo "   ℹ️  Nota: versione dai repository Debian (potrebbe non essere l'ultima LTS)"
    else
        # Raspberry Pi 3/4/5 (64-bit) - Usa NodeSource
        echo "   Installazione Node.js LTS da NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt install -y nodejs
        echo "   ✅ Node.js installato: $(node --version)"
    fi
else
    echo "   ✅ Node.js già installato: $(node --version)"
fi

if ! command -v pm2 &> /dev/null; then
    echo "   Installazione PM2..."
    sudo npm install -g pm2
    
    # Configura PM2 per auto-start
    echo "   Configurazione PM2 auto-start..."
    PM2_STARTUP_CMD=$(pm2 startup systemd -u $USER --hp $HOME | grep "sudo env" | tail -n1)
    
    if [ -n "$PM2_STARTUP_CMD" ]; then
        eval "$PM2_STARTUP_CMD"
        echo "   ✅ PM2 installato e configurato per auto-start"
    else
        echo "   ✅ PM2 installato (auto-start da configurare manualmente)"
    fi
else
    echo "   ✅ PM2 già installato"
fi

# --------------------------------------------------
# 5. Installazione Docker (opzionale, solo per Pi 4/5)
# --------------------------------------------------
read -p "🐳 Vuoi installare Docker? (Sconsigliato per Raspberry Pi 2) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if ! command -v docker &> /dev/null; then
        echo "   Installazione Docker dai repository Debian..."
        sudo apt update
        sudo apt install -y docker.io docker-compose
        sudo usermod -aG docker $USER
        echo "   ✅ Docker installato (riavvia per applicare i permessi)"
    else
        echo "   ✅ Docker già installato"
    fi
else
    echo "   ⏭️  Docker non installato"
fi

# --------------------------------------------------
# 6. Installazione Tailscale
# --------------------------------------------------
echo "🔒 Step 5/8: Installazione Tailscale..."

if ! command -v tailscale &> /dev/null; then
    echo "   Installazione Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    echo "   ✅ Tailscale installato"
else
    echo "   ✅ Tailscale già installato"
fi

echo ""
echo "   🔐 Configura Tailscale:"
echo "   1. Esegui: sudo tailscale up"
echo "   2. Apri il link nel browser e fai login"
echo "   3. Prendi nota dell'IP Tailscale con: tailscale ip -4"
echo ""
read -p "Vuoi configurare Tailscale ora? [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    sudo tailscale up
    echo ""
    echo "   📝 Il tuo IP Tailscale è: $(tailscale ip -4)"
    echo "   Salvalo! Lo userai come SSH_HOST nei secrets GitHub"
    echo ""
    read -p "Premi INVIO per continuare..."
fi

# --------------------------------------------------
# 7. Configurazione SSH
# --------------------------------------------------
echo "🔑 Step 6/8: Configurazione SSH..."

# Crea directory .ssh se non esiste
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Chiave SSH per GitHub
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "   Generazione chiave SSH per GitHub..."
    ssh-keygen -t ed25519 -C "github-deploy-$(hostname)" -f ~/.ssh/id_ed25519 -N ""
    echo "   ✅ Chiave SSH generata"
else
    echo "   ✅ Chiave SSH già esistente"
fi

# Aggiungi la chiave pubblica agli authorized_keys per permettere a GitHub Actions di connettersi
echo "   Configurazione authorized_keys per GitHub Actions..."

# Crea il file authorized_keys se non esiste
if [ ! -f ~/.ssh/authorized_keys ]; then
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

# Aggiungi la chiave se non è già presente
if ! grep -q "$(cat ~/.ssh/id_ed25519.pub)" ~/.ssh/authorized_keys 2>/dev/null; then
    cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    echo "   ✅ Authorized_keys configurato"
else
    echo "   ✅ Chiave già presente in authorized_keys"
fi

echo ""
echo "   📋 Chiave pubblica per GitHub (da aggiungere in Settings → SSH keys):"
echo "   ════════════════════════════════════════════════════════════════"
cat ~/.ssh/id_ed25519.pub
echo "   ════════════════════════════════════════════════════════════════"
echo ""
read -p "   Premi INVIO dopo aver aggiunto la chiave a GitHub..."

# Test connessione GitHub
echo "   Testing connessione a GitHub..."
ssh -T git@github.com || true

# Chiave SSH per GitHub Actions
echo ""
echo "   📋 Chiave PRIVATA per GitHub Actions (secret SSH_PRIVATE_KEY):"
echo "   ════════════════════════════════════════════════════════════════"
cat ~/.ssh/id_ed25519
echo "   ════════════════════════════════════════════════════════════════"
echo ""
echo "   ⚠️  COPIA QUESTA CHIAVE E SALVALA COME SECRET 'SSH_PRIVATE_KEY' SU GITHUB!"
echo ""
read -p "   Premi INVIO dopo aver salvato la chiave..."

# --------------------------------------------------
# 8. Configurazione sudo senza password
# --------------------------------------------------
echo "🔐 Step 7/8: Configurazione sudo senza password..."

SUDOERS_FILE="/etc/sudoers.d/99-deploy-nopasswd"

if [ ! -f "$SUDOERS_FILE" ]; then
    echo "   Aggiunta regola sudo NOPASSWD..."
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 440 "$SUDOERS_FILE"
    echo "   ✅ Sudo configurato senza password"
else
    echo "   ✅ Sudo già configurato"
fi

# --------------------------------------------------
# 9. Creazione directory progetti
# --------------------------------------------------
echo "📁 Step 8/8: Creazione directory progetti..."
mkdir -p ~/projects
echo "   ✅ Directory ~/projects creata"

# --------------------------------------------------
# 10. Ottimizzazioni per Raspberry Pi 2 (opzionale)
# --------------------------------------------------
echo ""
read -p "🔧 Hai un Raspberry Pi 2? Vuoi applicare ottimizzazioni (swap, ecc.)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   Aumento swap a 1GB..."
    sudo dphys-swapfile swapoff
    sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
    sudo dphys-swapfile setup
    sudo dphys-swapfile swapon
    echo "   ✅ Swap aumentato a 1GB"
fi

# --------------------------------------------------
# Riepilogo finale
# --------------------------------------------------
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✨ Setup completato!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📋 Informazioni da salvare per i secrets GitHub:"
echo ""
echo "   SSH_HOST: $(tailscale ip -4 2>/dev/null || echo 'Configura Tailscale prima!')"
echo "   SSH_USER: $USER"
echo "   SSH_PRIVATE_KEY: (chiave mostrata sopra)"
echo ""
echo "📝 Prossimi passi:"
echo ""
echo "   1. Aggiungi la chiave pubblica SSH a GitHub (Settings → SSH keys)"
echo "   2. Configura Tailscale OAuth per GitHub Actions:"
echo "      → https://login.tailscale.com/admin/settings/oauth"
echo "   3. Configura i secrets nel tuo repository GitHub"
echo "   4. Fai push e il deploy partirà automaticamente!"
echo ""
echo "🔄 Se hai installato Docker, riavvia il sistema: sudo reboot"
echo ""
echo "════════════════════════════════════════════════════════════════"

#!/usr/bin/env bash
set -euo pipefail

# ==============================================================
# KasmVNC Setup for Tencent Cloud Studio (Ubuntu)
# ==============================================================
# This script installs KasmVNC natively (no Docker) with a
# lightweight XFCE desktop environment, configured for Cloud
# Studio's port forwarding and ephemeral workspace model.
# ==============================================================

KASMVNC_VERSION="${KASMVNC_VERSION:-1.3.2}"
KASMVNC_PORT="${KASMVNC_PORT:-8443}"
DESKTOP="${DESKTOP:-xfce4}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# --------------------------------------------------------------
# Step 1: Detect environment
# --------------------------------------------------------------
echo "=============================================="
echo " KasmVNC Setup for Cloud Studio"
echo " Version: $KASMVNC_VERSION"
echo " Desktop: $DESKTOP"
echo " Port:    $KASMVNC_PORT"
echo "=============================================="
echo ""

if [ "$(id -u)" -ne 0 ]; then
    warn "Not running as root - some steps may need sudo"
fi

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -cs 2>/dev/null || echo "jammy")
log "Detected Ubuntu codename: $UBUNTU_VERSION"

# --------------------------------------------------------------
# Step 2: Install system dependencies
# --------------------------------------------------------------
log "Installing system dependencies..."
apt-get update -qq

# XFCE desktop environment (lightweight)
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    $DESKTOP xfce4-terminal \
    xauth x11-xkb-utils xkb-data \
    procps \
    ssl-cert \
    wget curl \
    ca-certificates \
    perl libswitch-perl \
    libyaml-tiny-perl libhash-merge-simple-perl \
    libscalar-list-utils-perl liblist-moreutils-perl \
    libtry-tiny-perl libdatetime-perl libdatetime-timezone-perl \
    libgbm1 2>&1 | tail -5

log "Dependencies installed successfully"

# --------------------------------------------------------------
# Step 3: Download and install KasmVNC
# --------------------------------------------------------------
KASMVNC_DEB="kasmvncserver_ubuntu_${UBUNTU_VERSION}_${KASMVNC_VERSION}_amd64.deb"
KASMVNC_URL="https://github.com/kasmtech/KasmVNC/releases/download/v${KASMVNC_VERSION}/${KASMVNC_DEB}"

if [ ! -f "/tmp/${KASMVNC_DEB}" ]; then
    log "Downloading KasmVNC v${KASMVNC_VERSION}..."
    wget -q --show-progress "${KASMVNC_URL}" -O "/tmp/${KASMVNC_DEB}" || {
        # Fallback: try jammy if version-specific fails
        warn "Exact version not found, trying jammy package..."
        KASMVNC_DEB="kasmvncserver_ubuntu_jammy_${KASMVNC_VERSION}_amd64.deb"
        KASMVNC_URL="https://github.com/kasmtech/KasmVNC/releases/download/v${KASMVNC_VERSION}/${KASMVNC_DEB}"
        wget -q --show-progress "${KASMVNC_URL}" -O "/tmp/${KASMVNC_DEB}"
    }
fi

log "Installing KasmVNC package..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "/tmp/${KASMVNC_DEB}" 2>&1 | tail -3

log "KasmVNC installed successfully"

# --------------------------------------------------------------
# Step 4: Add user to ssl-cert group
# --------------------------------------------------------------
log "Adding current user to ssl-cert group..."
addgroup "$(whoami)" ssl-cert 2>/dev/null || true

# --------------------------------------------------------------
# Step 5: Configure KasmVNC for Cloud Studio
# --------------------------------------------------------------
log "Writing KasmVNC configuration..."
mkdir -p /etc/kasmvnc

cat > /etc/kasmvnc/kasmvnc.yaml << 'KASMVNC_YAML'
network:
  protocol: http
  interface: 0.0.0.0
  websocket_port: KASMVNC_PORT_PLACEHOLDER
  use_ipv4: true
  use_ipv6: false

desktop:
  resolution:
    width: 1280
    height: 720
  allow_resize: true
  pixel_depth: 24
  hw3d: false
  drinode: /dev/dri/renderD128

server:
  http:
    headers:
      - Cross-Origin-Embedder-Policy=require-corp
      - Cross-Origin-Opener-Policy=same-origin
  advanced:
    x_font_path: auto
  auto_shutdown:
    no_user_session_timeout: never
    active_user_session_timeout: never
    inactive_user_session_timeout: never

logging:
  level: info
KASMVNC_YAML

# Replace placeholder with actual port
sed -i "s/KASMVNC_PORT_PLACEHOLDER/${KASMVNC_PORT}/" /etc/kasmvnc/kasmvnc.yaml

log "Configuration written to /etc/kasmvnc/kasmvnc.yaml"

# --------------------------------------------------------------
# Step 6: Create xstartup script for XFCE
# --------------------------------------------------------------
log "Creating xstartup script..."
cat > /usr/share/kasmvnc/xstartup << 'XSTARTUP'
#!/bin/sh
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share

# Start XFCE desktop
startxfce4
XSTARTUP
chmod 755 /usr/share/kasmvnc/xstartup

# --------------------------------------------------------------
# Step 7: Create helper scripts
# --------------------------------------------------------------
cp "$(dirname "$0")/start.sh" /usr/local/bin/kasmvnc-start
cp "$(dirname "$0")/stop.sh"  /usr/local/bin/kasmvnc-stop
chmod 755 /usr/local/bin/kasmvnc-start /usr/local/bin/kasmvnc-stop

# --------------------------------------------------------------
# Done
# --------------------------------------------------------------
log "============================================"
log " Setup complete!"
log "============================================"
log ""
log "Next steps:"
log "  1. Logout and log back in (or run: newgrp ssl-cert)"
log "  2. Run: kasmvnc-start"
log "  3. In Cloud Studio, find the port forwarding URL:"
log "     https://\${X_IDE_SPACE_KEY}--${KASMVNC_PORT}.\${REGION}.cloudstudio.work/"
log ""
log "  4. First-time login will prompt you to:"
log "     - Set a KasmVNC password"
log "     - Select desktop environment (choose XFCE)"
log ""
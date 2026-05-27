#!/usr/bin/env bash
set -euo pipefail

# ==============================================================
# KasmVNC Start - for Cloud Studio ephemeral sessions
# ==============================================================
# Run this each time you open a new Cloud Studio workspace
# session to start the KasmVNC desktop.
# ==============================================================

KASMVNC_PORT="${KASMVNC_PORT:-8443}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

# --------------------------------------------------------------
# Check if KasmVNC is already running
# --------------------------------------------------------------
if pgrep -f "kasmvnc" > /dev/null 2>&1; then
    warn "KasmVNC appears to be already running."
    info "Run 'kasmvnc-stop' first if you want to restart it."
    # Print existing sessions
    vncserver -list 2>/dev/null || true
    echo ""
fi

# --------------------------------------------------------------
# Ensure ssl-cert group membership is effective
# --------------------------------------------------------------
if ! groups | grep -q ssl-cert; then
    warn "User not in ssl-cert group. Attempting to add..."
    sudo addgroup "$(whoami)" ssl-cert 2>/dev/null || true
    warn "Group change won't take effect until next login."
    warn "If SSL cert access fails, run: newgrp ssl-cert"
fi

# --------------------------------------------------------------
# Create KasmVNC password if not exists
# --------------------------------------------------------------
KASMPASSWD="${HOME}/.kasmpasswd"
if [ ! -f "${KASMPASSWD}" ]; then
    log "No KasmVNC password found. You'll be prompted to create one."
    echo ""
fi

# --------------------------------------------------------------
# Start KasmVNC
# --------------------------------------------------------------
log "Starting KasmVNC on display :1 (port ${KASMVNC_PORT})..."
echo ""

vncserver -display :1 \
    -localhost no \
    -websocketPort "${KASMVNC_PORT}" \
    -geometry 1280x720 \
    -depth 24

echo ""

# --------------------------------------------------------------
# Print access instructions
# --------------------------------------------------------------
log "KasmVNC is running!"
echo ""
echo "============================================"
echo "  ACCESS YOUR DESKTOP"
echo "============================================"
echo ""

# Try to detect Cloud Studio environment variables
SPACE_KEY="${X_IDE_SPACE_KEY:-}"
REGION="${REGION:-}"
if [ -n "$SPACE_KEY" ] && [ -n "$REGION" ]; then
    echo "  Cloud Studio Port Forwarding URL:"
    echo ""
    echo "    https://${SPACE_KEY}--${KASMVNC_PORT}.${REGION}.cloudstudio.work/"
    echo ""
    echo "  Or find the port forwarding URL in Cloud Studio's"
    echo "  'Ports' panel (look for port ${KASMVNC_PORT})."
else
    echo "  Cloud Studio Port Forwarding:"
    echo ""
    echo "  1. Open the Cloud Studio terminal panel"
    echo "  2. Go to the 'Ports' tab"
    echo "  3. Look for port ${KASMVNC_PORT}"
    echo "  4. Click the globe icon to open in browser"
    echo ""
fi

echo "  Login credentials:"
    echo "    - Set during first-time setup"
    echo ""
    echo "  First-time login will ask you to:"
    echo "    1. Set a KasmVNC password"
    echo "    2. Select desktop (choose XFCE)"
    echo ""
    echo "============================================"

# Print session info
echo ""
info "Active sessions:"
vncserver -list 2>/dev/null || true
echo ""

log "To stop: kasmvnc-stop"
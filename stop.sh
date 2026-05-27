#!/usr/bin/env bash
set -euo pipefail

# ==============================================================
# KasmVNC Stop
# ==============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; }

log "Stopping KasmVNC..."
vncserver -kill :1 2>/dev/null || {
    fail "No KasmVNC session found on :1 (or already stopped)"
    exit 0
}

log "KasmVNC stopped."
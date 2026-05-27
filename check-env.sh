#!/usr/bin/env bash
# ==============================================================
# Cloud Studio Environment Check
# ==============================================================
# Validates that the current environment meets KasmVNC
# requirements before running the full setup.
# ==============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

echo "============================================"
echo " Cloud Studio Environment Check"
echo "============================================"
echo ""

FAILED=0

# Check OS
echo "--- OS Check ---"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "  OS: $NAME $VERSION_ID"
    echo "  Arch: $(uname -m)"
    if echo "$ID" | grep -qiE "ubuntu|debian"; then
        pass "Supported OS: $NAME"
    else
        warn "Untested OS: $NAME (KasmVNC supports Ubuntu/Debian best)"
    fi
else
    fail "Cannot detect OS"
    FAILED=$((FAILED + 1))
fi
echo ""

# Check root
echo "--- Permission Check ---"
if [ "$(id -u)" -eq 0 ]; then
    warn "Running as root — KasmVNC will work but this is unusual"
else
    pass "Running as non-root user: $(whoami)"
fi
echo ""

# Check architecture
echo "--- Architecture Check ---"
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "aarch64" ]; then
    pass "Supported architecture: $ARCH"
else
    fail "Unsupported architecture: $ARCH (KasmVNC requires amd64 or arm64)"
    FAILED=$((FAILED + 1))
fi
echo ""

# Check internet access
echo "--- Network Check ---"
if curl -s --connect-timeout 5 https://github.com > /dev/null 2>&1; then
    pass "Internet access: OK"
else
    fail "Cannot reach GitHub — downloads will fail"
    FAILED=$((FAILED + 1))
fi
echo ""

# Check disk space
echo "--- Disk Space Check ---"
AVAIL_KB=$(df / --output=avail 2>/dev/null | tail -1)
AVAIL_MB=$((AVAIL_KB / 1024))
if [ "$AVAIL_MB" -ge 2048 ]; then
    pass "Disk space: ${AVAIL_MB}MB available (>= 2GB recommended)"
elif [ "$AVAIL_MB" -ge 512 ]; then
    warn "Limited disk: ${AVAIL_MB}MB (may be tight for XFCE + KasmVNC)"
else
    fail "Insufficient disk: ${AVAIL_MB}MB (need at least 512MB)"
    FAILED=$((FAILED + 1))
fi
echo ""

# Check memory
echo "--- Memory Check ---"
MEM_MB=$(free -m | awk '/^Mem:/{print $2}')
if [ "$MEM_MB" -ge 2048 ]; then
    pass "Memory: ${MEM_MB}MB (>= 2GB recommended)"
elif [ "$MEM_MB" -ge 1024 ]; then
    warn "Limited memory: ${MEM_MB}MB (may affect desktop performance)"
else
    fail "Insufficient memory: ${MEM_MB}MB (need at least 1GB)"
    FAILED=$((FAILED + 1))
fi
echo ""

# Check if Docker is available (informational)
echo "--- Docker Check ---"
if command -v docker &> /dev/null; then
    pass "Docker is available (good, but not required for this setup)"
else
    warn "Docker not found (expected — general workspaces don't support it)"
fi
echo ""

# Check Cloud Studio specific env vars
echo "--- Cloud Studio Check ---"
if [ -n "${X_IDE_SPACE_KEY:-}" ]; then
    pass "Cloud Studio detected (SPACE_KEY: ${X_IDE_SPACE_KEY})"
else
    warn "Not in Cloud Studio or env vars not set (running locally?)"
fi
echo ""

# Summary
echo "============================================"
if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}All checks passed! Run ./setup.sh to install KasmVNC.${NC}"
else
    echo -e "${RED}${FAILED} check(s) failed. Review above before proceeding.${NC}"
fi
echo "============================================"
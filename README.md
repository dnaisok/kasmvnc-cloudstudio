# KasmVNC on Tencent Cloud Studio — Technical Validation

Deploy a browser-accessible Linux desktop (XFCE) via KasmVNC inside Tencent Cloud Studio's cloud IDE environment — **without Docker**.

## Overview

KasmVNC provides a web-native remote desktop that runs in any modern browser. This project validates whether KasmVNC can function inside Cloud Studio's containerized workspace, using native `.deb` installation (Cloud Studio general workspaces do not support Docker).

### Architecture

```
┌─────────────────────────────────────────────────────┐
│  Cloud Studio Workspace (Ubuntu Container)           │
│  ┌───────────────────────────────────────────────┐  │
│  │  KasmVNC Server (native .deb install)          │  │
│  │  ┌─────────────────┐  ┌────────────────────┐  │  │
│  │  │ Xvnc (X Server)  │  │ WebSocket Server   │  │  │
│  │  └────────┬────────┘  └─────────┬──────────┘  │  │
│  │           │                      │              │  │
│  │  ┌────────▼─────────────────────▼──────────┐  │  │
│  │  │  XFCE Desktop Environment               │  │  │
│  │  └─────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────┘  │
│           │                                          │
│           │ port 8443 (HTTP)                          │
│           ▼                                          │
│  Cloud Studio Port Forwarding                        │
│  https://{key}--8443.{region}.cloudstudio.work/      │
└─────────────────────────────────────────────────────┘
           │
           │ (browser)
           ▼
      You  ←  no VNC client needed
```

## Prerequisites

- A [Tencent Cloud](https://cloud.tencent.com) account
- Access to [Cloud Studio](https://cloud.tencent.com/product/cloudstudio)
- A GitHub repository (or import this project directly)

## Quick Start

### Step 1: Import into Cloud Studio

1. Push this project to a GitHub repository
2. Log into [Cloud Studio](https://console.cloud.tencent.com/cloudstudio)
3. Click **Create Workspace → Import from Git**
4. Paste your repository URL
5. Choose **Ubuntu** pre-installed environment
6. Click **Create**

> Alternatively, use any Ubuntu-based template and clone this repo later via terminal.

### Step 2: Run Setup

Open the Cloud Studio terminal and run:

```bash
# Make scripts executable
chmod +x setup.sh start.sh stop.sh

# Run the full setup (~5 minutes, installs XFCE + KasmVNC)
./setup.sh
```

The script will:
- Install XFCE desktop environment (lightweight)
- Install KasmVNC native `.deb` package
- Configure KasmVNC for HTTP mode (Cloud Studio's gateway handles HTTPS)
- Set port to `8443`
- Create `kasmvnc-start` / `kasmvnc-stop` helper commands

### Step 3: Start KasmVNC

```bash
kasmvnc-start
```

On **first run only**, you'll be prompted to:
1. Set a **KasmVNC password**
2. Select a **desktop environment** → choose **XFCE**

### Step 4: Find the Access URL

#### Via Terminal

Run `kasmvnc-start` — it will auto-detect Cloud Studio's environment variables and print the URL:

```
Cloud Studio Port Forwarding URL:
https://abcdef--8443.ap-guangzhou.cloudstudio.work/
```

#### Via Cloud Studio UI

1. Open the bottom panel in Cloud Studio
2. Go to the **PORTS** tab
3. Find port `8443`
4. Click the **globe icon** 🌐 to open in browser

> **Note for free workspaces:** Port forwarding via the PORTS tab URL works. For paid/HAI workspaces, you can also use a public IP.

### Step 5: Access the Desktop

Open the port forwarding URL in a new browser tab. You should see:

1. KasmVNC login page → enter the password you set
2. An XFCE Linux desktop in your browser

## Session Lifecycle (Important!)

Cloud Studio workspaces have these behaviors:

| Event | Behavior |
|---|---|
| Close browser tab | Workspace sleeps after ~10 min → KasmVNC stops |
| Reopen workspace | Terminal session resumes → Run `kasmvnc-start` again |
| **Weekly setup** | The setup (`.deb`, packages) persists across sessions |

Since this is an **ephemeral environment**, expect to run `kasmvnc-start` each time you open the workspace.

## Validation Checklist

Use this to confirm KasmVNC works in Cloud Studio:

- [ ] `./setup.sh` completes without errors
- [ ] `kasmvnc-start` starts without errors
- [ ] Port forwarding URL is accessible
- [ ] KasmVNC login page loads in browser
- [ ] XFCE desktop appears and is responsive
- [ ] Mouse and keyboard input work
- [ ] Window manager (Openbox/XFWM) works
- [ ] Terminal inside desktop works (`xfce4-terminal`)
- [ ] Clipboard copy/paste functions
- [ ] File upload/download via desktop browser works
- [ ] `kasmvnc-stop` cleanly terminates the session

## Troubleshooting

### "Cannot open display :1"

```bash
# Check if display is already in use
vncserver -list

# Kill existing session
kasmvnc-stop

# Retry
kasmvnc-start
```

### "Failed to read SSL certificate"

```bash
# Ensure ssl-cert group membership
sudo addgroup $(whoami) ssl-cert

# Apply group change in current session
newgrp ssl-cert

# Restart
kasmvnc-start
```

### Port 8443 already in use

Override with a different port:

```bash
KASMVNC_PORT=9090 kasmvnc-start
```

### Desktop shows blank/black screen

The xstartup script may need adjustment:

```bash
# Edit xstartup
nano ~/.vnc/xstartup

# Try starting XFCE explicitly:
# exec startxfce4
```

### "KasmVNC: command not found"

```bash
# Re-run setup
./setup.sh
```

## Files

| File | Purpose |
|---|---|
| `setup.sh` | One-time setup: installs KasmVNC + XFCE |
| `start.sh` | Start KasmVNC (run per session) |
| `stop.sh` | Stop KasmVNC gracefully |
| `README.md` | This file |

## Tech Stack

- **KasmVNC** v1.3.4 — Web-native remote desktop streaming
- **XFCE** — Lightweight desktop environment
- **Ubuntu** — Cloud Studio base environment
- **Cloud Studio Port Forwarding** — HTTPS access via `*.cloudstudio.work`

---

*This is a technical validation project. KasmVNC in Cloud Studio is not recommended for production use due to the ephemeral workspace lifecycle.*
# Remote Tauri Shim – Kommandos & Flags

## Voraussetzungen
- Bridge läuft (WSL):  
  ```bash
  cd humanlayer-wui
  bun run remote-bridge
  ```
- Optional: Daemon separat in WSL starten (z. B. auf 7777) oder über Bridge-Invoke starten.

## Frontend (WUI) mit Shim & Bridge starten
Aus `humanlayer-wui`:
```bash
VITE_REMOTE_TAURI_SHIM=1 \
VITE_TAURI_BRIDGE_URL=http://localhost:17650 \
VITE_HUMANLAYER_DAEMON_URL=http://localhost:7777 \  # falls Daemon extern läuft
bun run tauri dev
```

Wichtig:
- `VITE_REMOTE_TAURI_SHIM=1` aktiviert die Alias-Weiterleitungen auf die Shim-Module.
- `VITE_TAURI_BRIDGE_URL` zeigt auf die Bridge (Standard: `http://localhost:17650`).
- `VITE_HUMANLAYER_DAEMON_URL` nur setzen, wenn der Daemon bereits läuft (z. B. in WSL). Alternativ kann der Bridge-Invoke `start_daemon` den Daemon starten.

## Bridge-Umgebungsvariablen
- `HUMANLAYER_REMOTE_BRIDGE_PORT` (Default: 17650)
- `HUMANLAYER_REMOTE_BRIDGE_DAEMON_BIN` (Pfad zu `hld-dev`/`hld`)
- `HUMANLAYER_REMOTE_BRIDGE_DAEMON_PORT` (Falls der Bridge-Daemon-Start einen festen Port nutzen soll)
- `HUMANLAYER_BRIDGE_BRANCH` (Branch-ID/Version-Override für den Daemon)
- `HUMANLAYER_REMOTE_BRIDGE_DEBUG=1` (Request-/Invoke-Logging der Bridge)

## Daemon (WSL) manuell starten
```bash
cd hld
HUMANLAYER_DAEMON_HTTP_HOST=0.0.0.0 \
HUMANLAYER_DAEMON_HTTP_PORT=7777 \
./hld-dev
```

## Simplest Happy Path (alles in WSL)
1. Bridge: `cd humanlayer-wui && bun run remote-bridge`
2. (Optional) Daemon separat auf 7777 starten wie oben.
3. WUI: `VITE_REMOTE_TAURI_SHIM=1 VITE_TAURI_BRIDGE_URL=http://localhost:17650 VITE_HUMANLAYER_DAEMON_URL=http://localhost:7777 bun run tauri dev`

## Notes
- Ohne Shim-Flag (`VITE_REMOTE_TAURI_SHIM` unset) läuft das WUI wie bisher direkt gegen Tauri.
- `bun run dev` (reiner Browser) ist mit Shim überlebensfähig, aber viele Tauri-Features sind gestubbt; für die reale App weiterhin `bun run tauri dev` nutzen.

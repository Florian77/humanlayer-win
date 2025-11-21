# Remote Bridge Architektur

## 🎯 Das Problem

Die WUI (Web UI/Tauri-App) läuft normalerweise direkt auf dem Host-System und greift über Tauri-APIs auf das Dateisystem zu. Aber in unserem Fall:
- Entwicklung findet in WSL (Linux) statt
- Windows-App soll gegen WSL-Dateisystem laufen
- Direkter Zugriff von Windows-Tauri auf WSL-Dateien ist kompliziert

## 🏗️ Die Lösung: Remote Bridge

Die Bridge entkoppelt das Frontend von direkten Tauri-Calls durch eine HTTP-Middleware:

```
┌──────────────────┐
│  React Frontend  │
│  (Tauri/Browser) │
└────────┬─────────┘
         │ import '@tauri-apps/...'
         │ ↓ (wenn VITE_REMOTE_TAURI_SHIM=1)
         │ ↓ Vite Alias leitet um
         │
┌────────▼─────────┐
│  Shim-Module     │  ← plugin-fs.ts, api-core.ts, etc.
│  (Bridge Client) │     Ersetzen Tauri-APIs
└────────┬─────────┘
         │ HTTP Requests
         │ fetch('http://localhost:17650/...')
         │
┌────────▼─────────┐
│  Bridge Server   │  ← humanlayer-wui/remote-bridge/server.ts
│  (Node/Bun HTTP) │     Läuft in WSL
└────────┬─────────┘
         │ Node.js FS APIs
         │
┌────────▼─────────┐
│  WSL Filesystem  │
│  + hld daemon    │
└──────────────────┘
```

## 📋 Komponenten im Detail

### 1. Vite Config (vite.config.ts:74-100)

```typescript
if (useRemoteTauriShim) {
  // Ersetzt alle Tauri-Imports durch Shims
  '@tauri-apps/plugin-fs': shim('plugin-fs.ts'),
  '@tauri-apps/api/core': shim('api-core.ts'),
  // ... etc
}
```

Wenn `VITE_REMOTE_TAURI_SHIM=1` gesetzt ist, werden alle Tauri-Imports automatisch durch die Shim-Dateien ersetzt.

### 2. Shim-Module (src/remote-tauri-shim/)

**Beispiel plugin-fs.ts:**
```typescript
export async function readDir(path: string): Promise<DirEntry[]> {
  const res = await bridgeRequest('/fs/readDir', { query: { path } })
  return res.entries
}
```

Shims bieten dieselbe API wie Tauri, machen aber HTTP-Requests statt nativer Calls.

**Verfügbare Shims:**
- `plugin-fs.ts` - Dateisystem-Operationen
- `api-core.ts` - Tauri invoke() Calls
- `api-path.ts` - Pfad-Utilities (homeDir, appLogDir)
- `api-window.ts` - Fenster-Management (stubbed)
- `api-event.ts` - Event-System (stubbed)
- `plugin-log.ts` - Logging
- `plugin-notification.ts` - Benachrichtigungen (stubbed)
- `plugin-clipboard-manager.ts` - Zwischenablage (stubbed)
- `plugin-opener.ts` - Externe Links öffnen (stubbed)
- `plugin-global-shortcut.ts` - Tastenkombinationen (stubbed)

### 3. Bridge Client (bridge-client.ts)

```typescript
export async function bridgeRequest(path, options) {
  const url = `${DEFAULT_BRIDGE_URL}${path}`
  const resp = await fetch(url, { method, body })
  return await resp.json()
}
```

Zentrale Fetch-Funktion für alle Bridge-Requests.

### 4. Bridge Server (remote-bridge/server.ts)

HTTP-Server mit folgenden Endpoints:

#### Dateisystem
- `GET /fs/readDir?path=...` → `fs.readdir()` mit File-Metadaten
- `GET /fs/exists?path=...` → `fs.access()` Check
- `GET /path/homeDir` → `os.homedir()`
- `GET /path/appLogDir` → `~/.humanlayer/logs`

#### Logs
- `POST /log/read-lines` → Letzte N Zeilen aus Logfile
  ```json
  { "path": "/path/to/log", "n": 200 }
  ```

#### Tauri Commands (via POST /invoke)
```json
{ "cmd": "command_name", "args": { ... } }
```

**Verfügbare Commands:**
- `start_daemon` - Startet `hld` in WSL
  - Env: `HUMANLAYER_DAEMON_HTTP_PORT`, `HUMANLAYER_DAEMON_HTTP_HOST`
  - Args: `{ port?, socketPath?, databasePath?, branchId? }`
  - Returns: `DaemonInfo`

- `stop_daemon` - Stoppt daemon Process

- `get_daemon_info` - Status/Port/PID
  ```typescript
  {
    port: number
    pid: number
    database_path: string
    socket_path: string
    branch_id: string
    is_running: boolean
  }
  ```

- `is_daemon_running` - Boolean Check

- `get_log_directory` - Returns Log-Verzeichnis Pfad

- `read_last_log_lines` - Liest letzte N Zeilen
  - Args: `{ log_path?, n? }`

- `save_window_state` / `load_window_state` - Window-State Persistierung
  - State: `{ x, y, width, height, ... }`

- `get_stored_configs` - Gibt leeres Array zurück (Platzhalter)

- `get_config_path` - Config-File Pfad

#### Health Check
- `GET /health` → `{ ok: true }`

## 🚀 Usage

### 1. Bridge starten (WSL)
```bash
cd humanlayer-wui
bun run remote-bridge  # Port 17650
```

**Optionale Env-Vars:**
```bash
HUMANLAYER_REMOTE_BRIDGE_PORT=17650              # Bridge Port
HUMANLAYER_REMOTE_BRIDGE_DAEMON_BIN=./hld/hld-dev  # Daemon Binary
HUMANLAYER_REMOTE_BRIDGE_DAEMON_PORT=7777        # Daemon Default Port
HUMANLAYER_BRIDGE_BRANCH=dev                     # Branch ID für Daemon
HUMANLAYER_REMOTE_BRIDGE_DEBUG=1                 # Debug Logging
```

### 2. Tauri App mit Shim starten
```bash
VITE_REMOTE_TAURI_SHIM=1 \
VITE_TAURI_BRIDGE_URL=http://localhost:17650 \
bun run tauri dev
```

### 3. Optional: Daemon manuell starten
```bash
cd hld
HUMANLAYER_DAEMON_HTTP_HOST=0.0.0.0 \
HUMANLAYER_DAEMON_HTTP_PORT=7777 \
./hld-dev
```

Oder via Bridge:
```bash
# Bridge startet Daemon automatisch bei Bedarf
curl -X POST http://localhost:17650/invoke \
  -H "Content-Type: application/json" \
  -d '{"cmd":"start_daemon","args":{"port":7777}}'
```

## 🎨 Smart Details

### 1. Conditional Loading
Ohne `VITE_REMOTE_TAURI_SHIM=1` läuft alles wie bisher mit nativen Tauri-APIs.

### 2. Path Expansion
Die Bridge expandiert `~/...` automatisch zu WSL `$HOME/...`:
```typescript
function expandHome(p: string) {
  if (p.startsWith('~')) {
    return path.join(os.homedir(), p.slice(1))
  }
  return p
}
```

### 3. Daemon Management
Bridge kann den daemon selbst spawnen und verwalten:
```typescript
const child = spawn(bin, [], {
  env: {
    HUMANLAYER_DAEMON_HTTP_PORT: desiredPort,
    HUMANLAYER_DAEMON_HTTP_HOST: '0.0.0.0',
    HUMANLAYER_DAEMON_SOCKET: socketPath,
    HUMANLAYER_DATABASE_PATH: databasePath,
    HUMANLAYER_DAEMON_VERSION_OVERRIDE: branchId,
  }
})
```

### 4. CORS Headers
Saubere CORS-Header für Development:
```typescript
res.setHeader('Access-Control-Allow-Origin', '*')
res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
res.setHeader('Access-Control-Allow-Headers', 'Content-Type')
```

### 5. Debug-Modus
Mit `HUMANLAYER_REMOTE_BRIDGE_DEBUG=1`:
```
[remote-bridge] GET /fs/readDir ?path=/home/user len=0
[remote-bridge] invoke body: {"cmd":"start_daemon","args":{}}
```

### 6. Fehlerbehandlung
Alle Endpoints liefern strukturierte JSON-Responses:
```json
// Success
{ "result": ... }

// Error
{ "error": "error message" }
```

## 🔮 Nächster Schritt: Windows → WSL

Nach erfolgreicher WSL-Verifikation kann die **Windows-Tauri-App** gegen dieselbe Bridge kompiliert werden:

```bash
# Windows Build gegen WSL Bridge
VITE_REMOTE_TAURI_SHIM=1 \
VITE_TAURI_BRIDGE_URL=http://localhost:17650 \
bun run tauri build
```

Die Bridge bleibt dabei in WSL und vermittelt zwischen:
- **Windows Tauri App** (UI/Frontend)
- **WSL Filesystem** (Dateien, Config, Logs)
- **WSL hld Daemon** (Backend-Service)

## 📁 Dateistruktur

```
humanlayer-wui/
├── vite.config.ts                    # Alias-Konfiguration
├── remote-bridge/
│   └── server.ts                     # Bridge HTTP Server
└── src/
    └── remote-tauri-shim/
        ├── bridge-client.ts          # Shared HTTP Client
        ├── plugin-fs.ts              # FS Operations
        ├── api-core.ts               # invoke() Shim
        ├── api-path.ts               # Path Utilities
        ├── api-window.ts             # Window Stubs
        ├── api-event.ts              # Event Stubs
        ├── api-webview.ts            # Webview Stubs
        ├── api-webviewWindow.ts      # WebviewWindow Stubs
        ├── plugin-log.ts             # Logging
        ├── plugin-notification.ts    # Notification Stubs
        ├── plugin-clipboard-manager.ts  # Clipboard Stubs
        ├── plugin-opener.ts          # Opener Stubs
        └── plugin-global-shortcut.ts # Shortcut Stubs
```

## 🧪 Testing

### Smoke Tests
1. **File-Browser**: Directory-Listing funktioniert
2. **Fuzzy-Search**: File-Suche über Bridge
3. **Logs**: Settings → Debug Panel zeigt Logs
4. **Debug-Panel**: Daemon-Info anzeigen
5. **Keine Crashes**: Kein Fehler wegen fehlender Tauri-APIs

### Test-Varianten
```bash
# 1. Native Tauri (Baseline)
bun run tauri dev

# 2. Mit Bridge (WSL → WSL)
VITE_REMOTE_TAURI_SHIM=1 \
VITE_TAURI_BRIDGE_URL=http://localhost:17650 \
bun run tauri dev

# 3. Windows → WSL Bridge (Future)
# (Windows Build mit VITE_REMOTE_TAURI_SHIM=1)
```

## 📚 Siehe auch

- [REMOTE_TAURI_SHIM_PLAN.md](./REMOTE_TAURI_SHIM_PLAN.md) - Ursprünglicher Implementierungsplan
- [REMOTE_TAURI_SHIM_COMMANDS.md](./REMOTE_TAURI_SHIM_COMMANDS.md) - Command Reference
- [REMOTE_TAURI_SHIM_TODO.md](./REMOTE_TAURI_SHIM_TODO.md) - Offene Tasks
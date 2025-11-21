# Remote Tauri Shim & Bridge – Umsetzungsplan

## Ziele
- Frontend von direkten Tauri-/Systemcalls entkoppeln, indem wir sie über eine Shims-Schicht leiten.
- Shims sprechen mit einem kleinen HTTP-Bridge-Service (läuft in WSL), der die benötigten Funktionen (FS, Pfade, Logs, ggf. Daemon-Start/Stop) anbietet.
- Minimale Eingriffe in bestehenden React-Code: nur Vite-Alias-Schalter + neue Shim-Dateien.
- Erstes Ziel: Alles in WSL entwickeln und testen (Tauri-Build und Bridge laufen in WSL). Danach kann das WUI als Windows-App gegen dieselbe Bridge kompiliert werden.

## Vorgehen
1) **Vite-Alias-Schalter einbauen**  
   - Neues Flag `VITE_REMOTE_TAURI_SHIM=1` aktiviert Alias-Weiterleitungen für alle genutzten Tauri-Imports auf unsere Shim-Module.
   - Ohne Flag bleibt das aktuelle Verhalten unverändert.

2) **Shim-Module bereitstellen (Frontend)**  
   - Pfad `src/remote-tauri-shim/…` mit Ersetzungen für:  
     `@tauri-apps/plugin-fs`, `@tauri-apps/api/path`, `@tauri-apps/api/core`,  
     `@tauri-apps/api/window`, `@tauri-apps/api/webview`, `@tauri-apps/api/webviewWindow`,  
     `@tauri-apps/api/event`, `@tauri-apps/plugin-global-shortcut`,  
     `@tauri-apps/plugin-notification`, `@tauri-apps/plugin-clipboard-manager`,  
     `@tauri-apps/plugin-opener`, `@tauri-apps/plugin-log`.
   - FS/Path/Log-Aufrufe gehen über HTTP an die Bridge.  
   - Fenster/Shortcuts/Notifications/Clipboard/Opener werden sicher gestubbt oder auf Browser-Fallbacks gelegt.

3) **Bridge-Service (WSL)**  
   - Leichter HTTP-Server (Bun/Node) unter `humanlayer-wui/remote-bridge/server.ts`.  
   - Endpunkte:  
     - `/health`  
     - `/path/homeDir`, `/path/appLogDir`  
     - `/fs/readDir?path=…`, `/fs/exists?path=…`  
     - `/log/read-lines` (POST: { path?, n })  
     - `/invoke` (POST: { cmd, args }) mit Implementierungen für:  
       - `get_log_directory`, `read_last_log_lines`,  
       - `save_window_state`, `load_window_state`,  
       - `start_daemon`, `stop_daemon`, `get_daemon_info`, `is_daemon_running` (Basis-Implementierung; Daemon wird in WSL gestartet/gestoppt)  
     - Alle Pfade referenzieren WSL-Dateisystem (`os.homedir()` etc.).
   - Konfigurierbar via Env (`HUMANLAYER_REMOTE_BRIDGE_PORT`, `HUMANLAYER_REMOTE_BRIDGE_DAEMON_BIN`, `HUMANLAYER_REMOTE_BRIDGE_DAEMON_PORT`).

4) **Skripte & Nutzung**  
   - Neues Skript in `humanlayer-wui/package.json`, z. B. `remote-bridge`: startet den Bridge-Service.  
   - Start in WSL:  
     ```bash
     cd humanlayer-wui
     bun run remote-bridge  # Bridge
     VITE_REMOTE_TAURI_SHIM=1 VITE_TAURI_BRIDGE_URL=http://localhost:17650 bun run tauri dev
     ```  
   - Daemon in WSL wie bisher (z. B. `HUMANLAYER_DAEMON_HTTP_HOST=0.0.0.0 HUMANLAYER_DAEMON_HTTP_PORT=7777 ./hld/hld-dev`), oder über Bridge `start_daemon`.

5) **Tests / Verifikation (WSL zuerst)**  
   - Smoke: File-Browser/Fuzzy-Search, Logs (Settings/Debug Panel), Debug-Panel-Daemon-Info, kein Crash wegen fehlender Tauri-APIs.  
   - Varianten:  
     - Shim aus (`VITE_REMOTE_TAURI_SHIM` unset) → sollte unverändert laufen.  
     - Shim an mit Bridge → Entkopplung aktiv.

6) **Nächste Schritte (nach WSL-Verifikation)**  
   - Build der Windows-Tauri-App gegen laufende Bridge in WSL (nur Env anpassen).  
   - Optional: Robustheit/Fehlerhandling des Bridge-Servers sowie Feintuning der Daemon-Start/Stop-Logik.

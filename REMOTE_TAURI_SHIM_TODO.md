# Remote Tauri Shim – Offene Punkte & Zukunftsideen

## Noch nicht abgedeckt / bewusst gestubbt
- Fenster-/Webview-APIs: `getCurrentWindow`, `WebviewWindow`, Drag&Drop, Focus/Resize → aktuell No-ops bzw. minimale Rückgaben.
- Global Shortcuts: Registrierung ist No-op.
- Notifications: Browser-Web-Notification-Fallback, keine System-Notifications.
- Clipboard: Browser-Fallback, kein systemweites Clipboard.
- Opener: `openUrl` öffnet neuen Tab, `openPath` ist No-op.
- Logging: `attachConsole` ist No-op; Logs aus Tauri-Plugin werden nicht geroutet.
- Window-State: Persistenz läuft über Bridge-File, nicht über natives Window-Objekt.
- `invoke`-Abdeckung: Nur die in der App genutzten Commands sind gemappt (`get_log_directory`, `read_last_log_lines`, `save_window_state`, `load_window_state`, `start_daemon`, `stop_daemon`, `get_daemon_info`, `is_daemon_running`, `get_stored_configs`, `get_config_path`). Andere Commands wären 400.
- FS: nur `readDir`/`exists`. Kein File-Read/Write, kein stat, kein glob.
- Security: Bridge ohne Auth/CORS-Restriktion (nur Dev gedacht).

## Potenzielle Verbesserungen
- Vollständiger Tauri-API-Surface für Notifications/Shortcuts/Window (z. B. via Proxy in WSL mit nativer Ausführung).
- FS erweitern (lesen/schreiben, stat, symlink-handling) mit Pfadsicherheit.
- Logs: Rotationen, mehrere Targets, Rückkanal für Live-Streaming.
- Opener: Dateien/Ordner via WSL-zu-Windows-Bridge öffnen (z. B. `wslview` oder PowerShell-Aufruf).
- Auth/Tokens für Bridge, konfigurierbares CORS/Host-Binding.
- Robustheit: bessere Fehlercodes, Timeouts, Retries, Health-Check im FE.
- Tests: E2E-Szenarien mit Bridge-Flag (`VITE_REMOTE_TAURI_SHIM=1`) abdecken.
- Daemon-Steuerung: optionaler Prozess-Manager im Bridge-Server, Cleanup-Hooks, multi-instance Support.

# Remote-Frontend-Setup (WSL Backend, Windows WUI)

## Ziel
- Daemon/Backend in WSL weiterlaufen lassen, aber das WUI nativ unter Windows starten, um die Dev-Experience zu beschleunigen.
- Nur vorhandene Env-Variablen nutzen, minimale Eingriffe in den Code.

## Aktueller Stand des Projekts
- `humanlayer-wui` startet im Dev-Modus per `bun run tauri dev`. Tauri startet zuerst `bun run dev` (Vite) und liefert das UI an den eingebetteten Webview.
- Der Daemon wird von Tauri standardmäßig automatisch gestartet (`src-tauri/src/daemon.rs`). Das lässt sich mit `HUMANLAYER_WUI_AUTOLAUNCH_DAEMON=false` abschalten.
- Das React-Frontend spricht ausschließlich per HTTP mit dem Daemon (`HTTPDaemonClient` in `src/lib/daemon/http-client.ts`). Der Ziel-URL kommt aus:
  1) `VITE_HUMANLAYER_DAEMON_URL`, sonst
  2) `VITE_HUMANLAYER_DAEMON_HTTP_PORT/HOST`, sonst
  3) dem von Tauri gemanagten Port.
- Im UI gibt es bereits einen „Connect to custom“-Pfad (Debug Panel), der über `window.__HUMANLAYER_DAEMON_URL` auf einen externen Daemon umschaltet.

## Empfohlener Weg (ohne Code-Änderung)
1) **Daemon in WSL mit festem, erreichbarem Port starten**  
   - Beispiel:  
     ```bash
     cd ~/projects/humanlayer/hld
     HUMANLAYER_DAEMON_HTTP_HOST=0.0.0.0 HUMANLAYER_DAEMON_HTTP_PORT=7777 ./hld-dev
     ```  
     (oder `make daemon-dev` nach Anpassung der Env; Port 0 vermeiden, sonst muss man den zufälligen Port aus dem Log ablesen)

2) **WUI auf Windows gegen diesen Port starten**  
   - Im Ordner `humanlayer-wui`:  
     ```bash
     set HUMANLAYER_WUI_AUTOLAUNCH_DAEMON=false
     set VITE_HUMANLAYER_DAEMON_URL=http://localhost:7777
     bun run tauri dev
     ```  
   - Falls der Port belegt ist, `VITE_PORT=1421` o. Ä. setzen; HMR nutzt `port+1`.  
   - SDK-Pfad (`@humanlayer/hld-sdk` → `../hld/sdk/typescript`) muss lesbar sein; aus WSL einmal `bun install`/`bun run build` im Repo ausführen, damit die Files vorhanden sind.

3) **Optional: Über das Debug Panel verbinden**  
   - In der laufenden App im Debug Panel eine Custom URL (`http://localhost:7777`) setzen. Intern wird `window.__HUMANLAYER_DAEMON_URL` genutzt.

## Verhalten von Tauri-APIs im Browser-Only-Dev (`bun run dev`)
- Viele Komponenten importieren `@tauri-apps/*` (FS, Fenster, Global Shortcuts, Notifications, Window-State, etc.). Ohne Tauri-Host/Webview kämen hier Laufzeitfehler.  
- `isTauri()` wird nur an wenigen Stellen geprüft; ein reiner Vite-Browser-Start ist daher **nicht** safe, solange keine systematischen Guards/Mocks vorhanden sind.  
- Deshalb: Für die Windows-Seite weiterhin `bun run tauri dev` verwenden (liefert den Tauri-Host), nur der Daemon läuft extern in WSL. Das erfüllt das Ziel ohne neue Mocks.

## Optionale Mini-Verbesserung (falls gewünscht)
- Neues Make-Target z. B. `wui-remote` in `humanlayer-wui/Makefile`, das nur Env-Variablen setzt und `bun run tauri dev` startet. Eingriff minimal, kein Risiko für das Team.

## Auswirkungen auf das restliche Team
- Keine Verhaltensänderungen, solange nur Env-Variablen genutzt werden.
- Kein Eingriff in CI oder Core-Code; alle Standard-Workflows bleiben unverändert.

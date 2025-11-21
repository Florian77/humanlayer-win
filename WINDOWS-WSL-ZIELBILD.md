# Windows + WSL Zielbild (Kurznotiz)

- Ziel: Frontend (humanlayer-wui, Tauri/React) soll als native Windows-App laufen, die Bedienung erfolgt komplett von Windows aus.
- Backend-Lage: Der Go-Daemon `hld` laeuft unveraendert in WSL; spaetere Cloud-/Service-Instanzen (TS/DB/etc.) laufen ebenfalls dort in derselben Netzumgebung.
- Kopplung: UI auf Windows spricht per JSON-RPC/HTTP zu den Endpunkten des Daemons in WSL (localhost/WSL-Hostname, Ports nach Windows freigegeben).
- Vorteil des Splits: Windows fuer UI/UX und OS-Integration, WSL fuer Linux-Tooling und ohne Portierungsaufwand fuer den Daemon.

Offene Punkte fuer die naechste Runde:
1) Kommunikationspfad und Port-Freigaben (evtl. kleiner Reverse-Proxy), damit UI -> WSL-Daemon stabil funktioniert.
2) Dev-Startpfad/Make-Targets anpassen: Frontend unter Windows starten, Daemon/Services in WSL booten.
3) Pfad- und Filesystem-Fragen pruefen (WSL <-> Windows Pfade, Temp-Verzeichnisse) sowie Implikationen fuer Tauri-Builds.
4) Deployment/Updates: Wie die Desktop-App sicherstellt, dass der WSL-Daemon erreichbar und gestartet ist (Dokumentation/Helper-Skripte).

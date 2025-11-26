# WebUIAgent Status Log #002

**Datum:** 2025-11-23  
**Agent:** WebUIAgent  
**Aufgabe:** Registrierungs-Request schlägt im LAN fehl (ERR_CONNECTION_REFUSED)  
**Status:** Done

---

## 1. Ziel
- Ursache für `Failed to fetch` beim Register-Request im LAN finden und beheben.

## 2. Ist-Analyse
- UI läuft auf `http://192.168.178.52:5173` (LAN).
- API-Base-URL Fallback war `http://localhost:8080`. Von einem anderen Gerät zeigt `localhost` auf das Gerät selbst → Request geht ins Leere → Connection refused.
- API CORS-Default erlaubt nur `http://localhost:5173`, daher muss beim Backend ggf. das LAN-Origin ergänzt werden.

## 3. Umsetzung
- `webui/src/lib/api.js`: Default-Base-URL dynamisch auf `window.location.hostname:8080` gestellt, wenn keine `VITE_API_BASE_URL` gesetzt ist; Trailing-Slash entfernt. Netzwerkfehler werfen jetzt eine klare Meldung mit der Ziel-URL.
- `webui/src/pages/Register.jsx`, `Login.jsx`: Nutzen jetzt `apiRequest` für konsistente Fehlerbehandlung (inkl. Netzwerkfehler).
- `webui/src/pages/Dashboard.jsx`: Health-Check nutzt `apiRequest` → bessere Fehlermeldungen bei Unerreichbarkeit.
- Build-Test: `npm run build` (läuft durch, Hinweis: Node 20.18.1 < empfohlene 20.19+).

## 4. Ergebnis / Hinweise
- Browser auf Fremdgerät nutzt jetzt automatisch `http://<aktueller-host>:8080` als API, sodass Requests nicht mehr auf das lokale Gerät laufen.
- Backend muss auf Port 8080 erreichbar sein **und** CORS muss das Origin `http://192.168.178.52:5173` (oder `http://<host>:5173`) erlauben.
- Optional: `.env.local` setzen auf `VITE_API_BASE_URL=http://192.168.178.52:8080` für explizite Steuerung.

## 5. Nächste Schritte
- CORS-Whitelist im API-Start (ENV `CORS_ORIGINS`) um das LAN-Origin ergänzen.
- Sicherstellen, dass API auf Port 8080 läuft und von LAN erreichbar ist (z.B. `curl http://localhost:8080/health` auf dem Host).
- Node auf ≥20.19 aktualisieren, um die Vite-Warnung zu beseitigen.

Terminal freigegeben.

# NAS.AI v1.0 - Secure. Automated. Beautiful.

NAS.AI liefert einen komplett automatisierten, sicherheitsgehärteten Storage-Stack mit Nebula Glassmorphism UI, Auto-Backup-Scheduler und Fail-Fast-Architektur (JWT/CSRF, CORS-Whitelist, Rate-Limits).

## Key Features
- Auto-Backup Scheduler (Cron, Retention, Zielpfad)
- Nebula Glassmorphism UI (Files, Backups, Alerts)
- Fail-Fast Security Architecture (JWT/CSRF, starke Secrets, CORS/Ratelimit)
- Postgres Persistence & Redis Caching

## Quickstart (Production)
1) Images bereitstellen (z.B. Registry oder lokal gebaut als `nas-api:1.0.0`, `nas-webui:1.0.0`, Agents entsprechend).
2) Compose starten:
```bash
docker compose -f infrastructure/docker-compose.prod.yml up -d
```
3) UI aufrufen: http://localhost:3001 (API unter http://localhost:8080).

## Screenshots (Platzhalter)
- Dashboard Overview – `docs/img/dashboard-placeholder.png`
- Backup Planner – `docs/img/backup-placeholder.png`
- Security & Alerts – `docs/img/alerts-placeholder.png`

## Dienste
- API: http://localhost:8080
- WebUI: http://localhost:3001
- Monitoring Agent: sendet System-Metriken an `/api/v1/system/metrics`
- Analysis Agent: bewertet Metriken, schreibt Alerts in `system_alerts`
- Pentester Agent: prüft Security Headers & einfache Schwachstellen

## Struktur
- `infrastructure/` – API, WebUI, Agents, Docker Compose.
- `docs/` – Guides, Policies, Architektur.
- `status/` – Saubere Status-Historie ab v1.x (Archiv unter `status/archive`).
- `scripts/` – Admin- und Security-Skripte.

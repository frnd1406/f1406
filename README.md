# NAS AI System - Autonomous Server Guardian

Ein schlankes Agenten-Setup, das deinen Server rund um die Uhr überwacht, kritische Zustände erkennt und Sicherheits-Checks automatisiert. Optimiert für Raspberry Pi, lauffähig auf jeder Docker-Hostumgebung.

## Features
- 📊 Live Monitoring (CPU, RAM, Disk)
- 🧠 Intelligent Analysis (Auto-Detection of critical states)
- 🛡️ Self-Auditing (Internal Pentester checks for Security Headers & Weak Passwords)
- 🐳 Docker Native (Runs everywhere, specialized for Raspberry Pi)

## Quick Start
1) Repository holen
```bash
git clone https://github.com/your-org/nas-ai-system.git
cd nas-ai-system
```
2) API-Umgebung vorbereiten
```bash
cp infrastructure/api/.env.example infrastructure/api/.env
```
3) Stack starten (Dev)
```bash
docker compose -f infrastructure/docker-compose.dev.yml up -d --build
```

## Screenshots
- Dashboard Overview (Placeholder)
- Alert Details (Placeholder)
- Security Audit (Placeholder)

## Dienste (Dev)
- API: http://localhost:8080
- WebUI: http://localhost:3001
- Monitoring Agent: sendet System-Metriken an `/api/v1/system/metrics`
- Analysis Agent: bewertet Metriken, schreibt Alerts in `system_alerts`
- Pentester Agent: prüft Security Headers & einfache Schwachstellen

## Struktur
- `infrastructure/` – Source Code für API, WebUI, Agents, Docker Compose.
- `docs/` – Guides, Policies, Architektur.
- `status/` – Status-Logs & Reports der Agenten.
- `scripts/` – Admin-Skripte (z.B. `git_savepoint.sh`).

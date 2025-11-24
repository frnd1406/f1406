# NAS.AI System

Ein intelligentes, sicheres und modulares NAS-System, gesteuert durch KI-Agenten.

## Status
- Phase 3 Completed – Monitoring & Analysis aktiv.

## 🚀 Quick Start
1. Architektur: `NAS_AI_SYSTEM.md` (Single Source of Truth)
2. Dev-Setup: `docs/development/DEV_GUIDE.md`
3. Security: `docs/security/SECURITY_HANDBOOK.pdf`
4. Dev-Stack starten:
   ```bash
   docker compose -f infrastructure/docker-compose.dev.yml up -d api webui monitoring-agent analysis-agent
   ```

## 🛰️ Services (Dev)
- API (`nas-api`): http://localhost:8080
- WebUI (`nas-webui`): http://localhost:3001 (spricht mit API auf 8080)
- Monitoring Agent (`nas-monitoring-agent`): sendet System-Metriken an `/api/v1/system/metrics`
- Analysis Agent (`nas-analysis-agent`): bewertet Metriken, schreibt Alerts in `system_alerts`

## 📂 Struktur
- `docs/` - Handbücher, Pläne und Policies.
- `infrastructure/` - Source Code (API, WebUI, Agents, Compose).
- `status/` - Agenten-Logs und Reports.

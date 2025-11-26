# NAS.AI Infrastructure

**Version:** 1.0
**Datum:** 2025-11-21
**Status:** Foundation Setup (Phase 1)

---

## STRUKTUR

```
infrastructure/
├── api/              # Go Backend API (APIAgent)
├── webui/            # React/Vite Frontend (WebUIAgent)
├── orchestrator/     # Event-Dienst & Queue (Go)
├── monitoring/       # Prometheus, Grafana, Loki
└── scripts/          # Deployment & Maintenance Scripts
```

---

## COMPONENTS

### 1. API (Backend)
- **Technologie:** Go 1.22+
- **Owner:** APIAgent
- **Pfad:** `infrastructure/api/`
- **Dokumentation:** `infrastructure/api/README.md`
- **Status:** Phase 1 - Foundation Setup

### 2. WebUI (Frontend)
- **Technologie:** React 18 + Vite + TypeScript
- **Owner:** WebUIAgent
- **Pfad:** `infrastructure/webui/`
- **Dokumentation:** `infrastructure/webui/README.md`
- **Status:** Phase 1 - Setup Pending

### 3. Orchestrator
- **Technologie:** Go Event Service
- **Owner:** Orchestrator + SystemSetupAgent
- **Pfad:** `infrastructure/orchestrator/`
- **Status:** Phase 2 - Planned

### 4. Monitoring
- **Technologie:** Prometheus, Grafana, Loki
- **Owner:** SystemSetupAgent
- **Pfad:** `infrastructure/monitoring/`
- **Status:** Phase 2 - Deployment Pending

### 5. Scripts
- **Inhalt:** Deployment, Backup, Maintenance Scripts
- **Owner:** SystemSetupAgent
- **Pfad:** `infrastructure/scripts/`
- **Status:** As needed

---

## DEVELOPMENT WORKFLOW

### Setup (First Time)

1. **Install Prerequisites:**
   ```bash
   # Go 1.22+
   go version

   # Node.js 20+
   node --version

   # Docker & Docker Compose
   docker --version
   docker compose version
   ```

2. **Clone Repository:**
   ```bash
   git clone <repo-url>
   cd Agent/infrastructure
   ```

3. **Setup Backend:**
   ```bash
   cd api
   # Follow instructions in api/README.md
   ```

4. **Setup Frontend:**
   ```bash
   cd ../webui
   # Follow instructions in webui/README.md
   ```

### Running Development Environment

```bash
# From infrastructure/ directory

# Start dev infrastructure (DB, Redis, etc.)
docker compose -f docker-compose.dev.yml up -d

# Start backend API
cd api && go run src/main.go

# Start frontend (in another terminal)
cd webui && npm run dev
```

---

## ARCHITECTURE REFERENCES

- **System Overview:** `/home/user/Agent/NAS_AI_SYSTEM.md`
- **Roadmap:** `/home/user/Agent/docs/planning/MASTER_ROADMAP.md`
- **Agent Matrix:** `/home/user/Agent/docs/planning/AGENT_MATRIX.md`
- **Dev Guide:** `/home/user/Agent/docs/development/DEV_GUIDE.md`
- **Security:** `/home/user/Agent/docs/security/SECURITY_HANDBOOK.pdf`

---

## DEPLOYMENT

### Phase 1 Goals (Current)
- ✅ Directory structure created
- ⏳ API Foundation (Go backend with Auth, Files, Health)
- ⏳ WebUI Foundation (React/Vite with Auth flow)
- ⏳ Docker Compose Dev Environment
- ⏳ CI/CD Pipeline (Tests, Linting, Security Scans)

### Phase 2 Goals
- Vault Integration
- Prometheus + Loki + Grafana
- Orchestrator Event Service
- Advanced Security (CSRF, Rate Limiting)

---

## AGENT ASSIGNMENTS

| Component | Owner | Phase | Status |
|-----------|-------|-------|--------|
| API Backend | APIAgent | 1 | ⏳ Starting |
| WebUI Frontend | WebUIAgent | 1 | ⏳ Starting |
| Docker Dev Env | SystemSetupAgent | 1 | ⏳ Pending |
| Orchestrator | Orchestrator | 2 | ⏳ Planned |
| Monitoring Stack | SystemSetupAgent | 2 | ⏳ Planned |

---

## CONTACT & SUPPORT

**Orchestrator:** Koordiniert alle Infrastructure-Aktivitäten
**Status Logs:** `/home/user/Agent/status/<AgentName>/`
**Issues:** Incident-Tickets in `/var/lib/orchestrator/incidents/` (future)

---

**Letzte Aktualisierung:** 2025-11-21
**Nächste Milestone:** Phase 1 Foundation Complete (Target: 2025-11-28)

Terminal freigegeben.

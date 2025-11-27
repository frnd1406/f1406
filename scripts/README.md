# NAS.AI Scripts - Dokumentation

Dieser Ordner enthält verschiedene Skripte zur Verwaltung der NAS.AI API und Infrastruktur.

## 📋 Verfügbare Skripte

### 1. 🚀 Deployment Scripts

#### `deploy-prod.sh`
Vollständiges Deployment der Produktions-Umgebung mit Datenbank-Initialisierung.

**Features:**
- Interaktive Datenbank-Reset-Abfrage
- WebUI-Build mit korrekter API-URL
- Container Health Checks
- API Erreichbarkeits-Validierung
- Automatische Fehlerdiagnose

**Verwendung:**
```bash
./scripts/deploy-prod.sh
```

**Was es macht:**
1. Überprüft `.env.prod` Datei
2. Fragt ob Datenbank zurückgesetzt werden soll
3. Stoppt alle Container
4. Baut WebUI neu mit Production API URL
5. Startet alle Container
6. Initialisiert Datenbank (falls Reset)
7. Validiert Container-Status
8. Testet API Health Endpoint

---

#### `restart-prod.sh` (in `/infrastructure/scripts/`)
Schneller Neustart der Production-Container mit Validierung.

**Features:**
- Farb-codierter Output
- Container-Validierung nach Neustart
- Automatische Log-Anzeige bei Fehlern
- Fail-Fast Verhalten

**Verwendung:**
```bash
./infrastructure/scripts/restart-prod.sh
```

---

### 2. 🧪 API Testing

#### `test-api-endpoints.sh`
Automatisiertes Testen aller API-Endpunkte.

**Features:**
- Public und Protected Endpoints
- Authentifizierungs-Tests
- Verbose Mode für Debugging
- Farbiger Output
- Flexible API-URL Konfiguration

**Verwendung:**

**Basic Test:**
```bash
./scripts/test-api-endpoints.sh
```

**Verbose Mode:**
```bash
VERBOSE=true ./scripts/test-api-endpoints.sh
```

**Mit anderem API-Server:**
```bash
API_URL=http://localhost:8080 ./scripts/test-api-endpoints.sh
```

**Mit Authentifizierung:**
```bash
JWT_TOKEN='your-jwt-token' CSRF_TOKEN='your-csrf-token' ./scripts/test-api-endpoints.sh
```

**Beispiel Output:**
```
✅ GET /health - Health Check
✅ GET /api/v1/system/metrics?limit=1 - System Metrics (Latest)
✅ GET /api/v1/system/alerts - System Alerts List
❌ GET /api/v1/system/settings - Get System Settings (Unauthorized)
   Expected: 401, Got: 404
```

---

### 3. ➕ Endpoint hinzufügen

#### `add-api-endpoint.sh`
Interaktiver Generator für neue API-Endpunkte.

**Features:**
- Interaktive Eingabe
- Automatische Handler-Generierung
- Route-Registrierungs-Anleitung
- Test-Code-Generierung
- Build & Deploy Anweisungen

**Verwendung:**
```bash
./scripts/add-api-endpoint.sh
```

**Ablauf:**
1. **Eingabe sammeln:**
   - Endpoint-Name (z.B. "tasks")
   - HTTP Methode (GET/POST/PUT/DELETE)
   - Endpoint-Pfad (z.B. "/api/v1/tasks")
   - Authentifizierung erforderlich? (y/n)
   - Beschreibung

2. **Handler erstellen:**
   - Generiert `/infrastructure/api/src/handlers/{name}.go`
   - Enthält Beispiel-Code für GET/POST

3. **Anweisungen anzeigen:**
   - Zeigt wie Route in `main.go` registriert wird
   - Zeigt wie Test-Eintrag hinzugefügt wird
   - Zeigt Build & Deploy Befehle

**Beispiel:**
```bash
$ ./scripts/add-api-endpoint.sh

Endpoint-Name: tasks
HTTP Methode: GET
Endpoint-Pfad: /api/v1/tasks
Authentifizierung erforderlich?: y
Kurze Beschreibung: Liste aller Aufgaben

✅ Handler erstellt: /home/freun/Agent/infrastructure/api/src/handlers/tasks.go

Füge folgende Zeile zu main.go hinzu:
tasksV1 := r.Group("/api/v1/tasks")
tasksV1.Use(
    middleware.AuthMiddleware(jwtService, redis, logger),
    middleware.CSRFMiddleware(redis, logger),
)
{
    tasksV1.GET("", handlers.TasksHandler(logger))
}
```

---

### 4. 📚 Dokumentation

#### `generate-api-docs.sh`
Generiert vollständige API-Dokumentation.

**Features:**
- Markdown-Dokumentation aller Endpunkte
- curl-Beispiele
- Request/Response Formate
- Quick Reference (ASCII-Art)
- Status Codes Übersicht

**Verwendung:**
```bash
./scripts/generate-api-docs.sh
```

**Erstellt:**
- `/home/freun/Agent/API_ENDPOINTS.md` - Vollständige Dokumentation
- `/home/freun/Agent/scripts/API_QUICK_REFERENCE.txt` - Schnellreferenz

**Quick Reference ansehen:**
```bash
cat /home/freun/Agent/scripts/API_QUICK_REFERENCE.txt
```

---

## 🔄 Typischer Workflow

### Neuen Endpoint hinzufügen

```bash
# 1. Generator starten
./scripts/add-api-endpoint.sh

# 2. Handler implementieren
nano /home/freun/Agent/infrastructure/api/src/handlers/your-endpoint.go

# 3. Route in main.go registrieren
nano /home/freun/Agent/infrastructure/api/src/main.go

# 4. API neu bauen
cd /home/freun/Agent/infrastructure/api
docker build --no-cache -t nas-api:1.0.0 .

# 5. Production deployen
cd /home/freun/Agent/infrastructure
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d api

# 6. Endpoint testen
cd /home/freun/Agent/scripts
./test-api-endpoints.sh

# 7. Dokumentation aktualisieren
./generate-api-docs.sh
```

---

### Production-Probleme debuggen

```bash
# 1. Container-Status prüfen
docker compose --env-file /home/freun/Agent/infrastructure/.env.prod \
  -f /home/freun/Agent/infrastructure/docker-compose.prod.yml ps

# 2. API-Logs ansehen
docker compose --env-file /home/freun/Agent/infrastructure/.env.prod \
  -f /home/freun/Agent/infrastructure/docker-compose.prod.yml logs --tail=50 api

# 3. Endpoints testen
VERBOSE=true ./scripts/test-api-endpoints.sh

# 4. Neustart mit Validierung
./infrastructure/scripts/restart-prod.sh
```

---

### API vollständig neu deployen

```bash
# Mit Datenbank-Reset
./scripts/deploy-prod.sh
# Antworte mit 'y' bei "Datenbank KOMPLETT löschen?"

# Ohne Datenbank-Reset (Update Mode)
./scripts/deploy-prod.sh
# Antworte mit 'n' bei "Datenbank KOMPLETT löschen?"
```

---

## 🛠️ Weitere nützliche Befehle

### API Image neu bauen
```bash
cd /home/freun/Agent/infrastructure/api
docker build --no-cache -t nas-api:1.0.0 .
```

### WebUI Image neu bauen
```bash
cd /home/freun/Agent/infrastructure
docker build \
  --build-arg VITE_API_BASE_URL="https://api.freund-felix.com" \
  -t nas-webui:1.0.0 \
  webui
```

### Container-Logs live ansehen
```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml logs -f api
```

### Backup-Permissions fixen
```bash
sudo chmod 777 /var/lib/docker/volumes/infrastructure_nas_backups/_data
sudo chmod 777 /var/lib/docker/volumes/infrastructure_nas_data/_data
```

### Alle Container stoppen und Volumes löschen
```bash
cd /home/freun/Agent/infrastructure
docker compose --env-file .env.prod -f docker-compose.prod.yml down -v
```

---

## 📊 Script Overview

| Script | Zweck | Interaktiv | Dauer |
|--------|-------|------------|-------|
| `deploy-prod.sh` | Full Production Deployment | Ja | 2-5 Min |
| `restart-prod.sh` | Quick Restart | Nein | 10-20 Sek |
| `test-api-endpoints.sh` | API Testing | Nein | 5-10 Sek |
| `add-api-endpoint.sh` | Endpoint Generator | Ja | 1-2 Min |
| `generate-api-docs.sh` | Documentation | Nein | < 1 Sek |

---

## 🚨 Troubleshooting

### "Permission Denied" bei Backups
```bash
sudo chmod 777 /var/lib/docker/volumes/infrastructure_nas_backups/_data
```

### API gibt 404 für neue Endpoints
```bash
# API wurde nicht neu gebaut!
cd /home/freun/Agent/infrastructure/api
docker build --no-cache -t nas-api:1.0.0 .
docker compose --env-file ../infrastructure/.env.prod -f ../infrastructure/docker-compose.prod.yml up -d api
```

### Container startet nicht
```bash
# Logs ansehen
docker compose --env-file .env.prod -f docker-compose.prod.yml logs api

# Health Check
docker compose --env-file .env.prod -f docker-compose.prod.yml exec api wget -q --spider http://localhost:8080/health
```

### WebUI zeigt alte Version
```bash
# Browser-Cache leeren oder Hard Reload:
# Chrome/Firefox: Ctrl+Shift+R
# Safari: Cmd+Option+R
```

---

## 📝 Best Practices

1. **Immer testen nach Änderungen:**
   ```bash
   ./scripts/test-api-endpoints.sh
   ```

2. **Dokumentation aktualisieren:**
   ```bash
   ./scripts/generate-api-docs.sh
   ```

3. **Logs bei Problemen:**
   ```bash
   docker compose -f docker-compose.prod.yml logs --tail=100 api
   ```

4. **Backups vor großen Änderungen:**
   ```bash
   # Via WebUI oder API
   curl -X POST https://felix-freund.com/api/v1/backups \
     -H "Authorization: Bearer $JWT_TOKEN" \
     -H "X-CSRF-Token: $CSRF_TOKEN"
   ```

---

## 🔗 Weiterführende Links

- API Dokumentation: `/home/freun/Agent/API_ENDPOINTS.md`
- Quick Reference: `/home/freun/Agent/scripts/API_QUICK_REFERENCE.txt`
- Docker Compose Config: `/home/freun/Agent/infrastructure/docker-compose.prod.yml`
- API Source: `/home/freun/Agent/infrastructure/api/`
- WebUI Source: `/home/freun/Agent/infrastructure/webui/`

---

**Erstellt:** 2025-11-27
**Version:** 1.0.0

# SEC-2025-003 & PERF-001 – Statusbestätigung

**Datum:** 2025-11-25
**Agent:** APIAgent

## SEC-2025-003 (JWT Default Secret)
- Aktueller Stand: JWT_SECRET ist verpflichtend (Validation in config.LoadConfig/ValidateJWTSecret). Kein Default mehr.
- Verifikation: `go test ./...` durchgelaufen (inkl. services/password_service Tests).
- Nächster Schritt: In CI einen Secret-Check als Blocking Gate (env var vorhanden, Länge >=32).

## PERF-001 (Fail-Fast)
- Aktueller Stand: Config/DB/Redis initialisieren fail-fast mit Fatal-Exit bei Fehlern.
- Verifikation: Testlauf `go test ./...` erfolgreich.
- Nächster Schritt: Healthcheck-Pfade um Redis/DB/Warnungen erweitern, damit Deployment-Checks schneller scheitern.

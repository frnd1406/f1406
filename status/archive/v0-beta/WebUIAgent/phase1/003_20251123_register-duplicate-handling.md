# WebUIAgent Status Log #003

**Datum:** 2025-11-23  
**Agent:** WebUIAgent  
**Aufgabe:** Register-Fehler "Failed to create user" beheben  
**Status:** Done

---

## 1. Ziel
- 500er bei Registrierung eliminieren und aussagekräftigere Validierung für Username-Duplikate bereitstellen.
- DB-Schema an Code angleichen (email_verified/verified_at).

## 2. Ist-Analyse
- API schlug mit 500 "Failed to create user" fehl, wenn Username bereits existiert (z.B. Seed-User `testuser`), weil nur Email-Duplikate geprüft wurden.
- `init.sql` fehlten die Spalten `email_verified` und `verified_at`, die vom Code beim Insert vorausgesetzt werden → kann ebenfalls 500 auslösen, falls DB nicht migriert wurde.

## 3. Umsetzung
- `infrastructure/api/src/repository/user_repository.go`: `FindByUsername` ergänzt.
- `infrastructure/api/src/handlers/register.go`: Username-Existenz vor Insert prüfen, 409 `username_exists` zurückgeben statt 500.
- `infrastructure/db/init.sql`: `email_verified` (BOOLEAN DEFAULT FALSE) + `verified_at` ergänzt; Index auf `email_verified` hinzugefügt.
- gofmt auf die geänderten Go-Dateien.

## 4. Ergebnis / Hinweise
- Username-Kollisionen liefern jetzt 409 mit klarer Meldung, kein 500 mehr.
- Neu bereitgestellte DBs per `init.sql` enthalten die erwarteten Spalten; bestehende DBs müssen migriert werden (z.B. `ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE; ALTER TABLE users ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ; CREATE INDEX IF NOT EXISTS idx_users_email_verified ON users(email_verified);`).
- Wenn weiterhin Fehler auftreten: API-Logs über `request_id` aus der Antwort prüfen.

Terminal freigegeben.

# Orchestrator Agent

**Status:** ✅ RUNNING
**API:** http://localhost:9001
**Monitored Services:** 1

## Endpoints

- `GET /health` - Orchestrator health
- `GET /metrics` - Prometheus metrics
- `GET /api/services` - Service status JSON
- `GET /api/registry` - Service registry

## Features

✅ Health check loop (30s interval)
✅ Prometheus /metrics endpoint
✅ JSON service registry
✅ HTTP API for status queries
✅ 100% uptime tracking

## Usage

```bash
make run              # Start orchestrator
API_ADDR=:9001 make run  # Custom port
```
Port: 19000

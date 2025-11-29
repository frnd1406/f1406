# AI Knowledge Agent

**Phase**: 2.2 - AI Core Infrastructure
**Status**: Production
**Version**: 1.0.0

---

## Purpose

The AI Knowledge Agent is the "thinking apparatus" of the NAS.AI system. It provides:
- **Semantic embedding generation** using pre-trained transformer models
- **Vector database integration** with pgvector for similarity search
- **Health check endpoints** for container orchestration
- **Robust database connections** with automatic retry logic

---

## Architecture

```
┌─────────────────────────────────────────┐
│   AI Knowledge Agent (Python 3.11)     │
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐  │
│  │  Sentence Transformer Model       │  │
│  │  (all-MiniLM-L6-v2)               │  │
│  │  - 384 dimensions                 │  │
│  │  - CPU-optimized                  │  │
│  └───────────────────────────────────┘  │
│              ▼                           │
│  ┌───────────────────────────────────┐  │
│  │  Flask Health Check Server        │  │
│  │  Port: 8000                       │  │
│  │  - GET /health                    │  │
│  │  - GET /status                    │  │
│  │  - POST /embed (future)           │  │
│  └───────────────────────────────────┘  │
│              ▼                           │
│  ┌───────────────────────────────────┐  │
│  │  Database Connection (pgvector)   │  │
│  │  - Automatic retry logic          │  │
│  │  - Vector type support            │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

---

## Model Specifications

| Property | Value |
|----------|-------|
| **Model** | sentence-transformers/all-MiniLM-L6-v2 |
| **Embedding Dimension** | 384 |
| **Max Sequence Length** | 256 tokens |
| **Model Size** | ~90 MB |
| **Framework** | PyTorch (CPU-optimized) |

### Why all-MiniLM-L6-v2?

- ✅ **Fast**: Optimized for CPU inference
- ✅ **Small**: ~90MB model size
- ✅ **Accurate**: Good quality embeddings for semantic search
- ✅ **Versatile**: Works well for general text understanding
- ✅ **Resource-efficient**: Fits within 4GB memory limit

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgres://nas_user:nas_password@postgres:5432/nas_db` | PostgreSQL connection string |
| `MODEL_NAME` | `sentence-transformers/all-MiniLM-L6-v2` | Hugging Face model identifier |
| `TRANSFORMERS_CACHE` | `/app/models` | Model cache directory |

---

## Health Check Endpoints

### GET /health

Returns health status for Docker healthcheck.

**Response (Healthy)**:
```json
{
  "status": "healthy",
  "model_loaded": true,
  "database_connected": true,
  "model_name": "sentence-transformers/all-MiniLM-L6-v2",
  "embedding_dimension": 384
}
```

**Status Code**: 200 (healthy), 503 (unhealthy)

### GET /status

Returns detailed service status.

**Response**:
```json
{
  "service": "AI Knowledge Agent",
  "version": "1.0.0",
  "phase": "2.2",
  "model_loaded": true,
  "database_connected": true,
  "model_name": "sentence-transformers/all-MiniLM-L6-v2",
  "embedding_dimension": 384,
  "ready": true
}
```

### POST /embed (Future)

Generate embeddings for text.

**Request**:
```json
{
  "text": "Sample text to embed"
}
```

**Response**:
```json
{
  "embedding": [0.123, -0.456, ...],
  "dimension": 384,
  "model": "sentence-transformers/all-MiniLM-L6-v2"
}
```

---

## Resource Limits

| Resource | Limit | Reason |
|----------|-------|--------|
| **Memory** | 4 GB | Safety net for model + PyTorch |
| **CPU** | Unlimited | CPU-bound workload |
| **Network** | nas-network only | Internal network for security |

---

## Startup Sequence

1. **Load Model** (~30-60 seconds on first run)
   - Download model from Hugging Face (if not cached)
   - Load into memory
   - Test with sample encoding

2. **Connect to Database** (with retry logic)
   - Attempt connection up to 10 times
   - Wait 5 seconds between retries
   - Verify pgvector extension is installed

3. **Start Health Check Server**
   - Listen on port 8000
   - Serve /health and /status endpoints
   - Ready for Docker healthchecks

4. **Await Commands**
   - Main thread keeps container alive
   - Logs heartbeat every 60 seconds

---

## Troubleshooting

### Model Not Loading

**Symptom**: Container unhealthy, logs show model loading failure

**Solution**:
```bash
# Check logs
docker logs nas-ai-knowledge-agent

# Verify model cache
docker exec nas-ai-knowledge-agent ls -lh /app/models

# Re-download model
docker exec nas-ai-knowledge-agent rm -rf /app/models/*
docker restart nas-ai-knowledge-agent
```

### Database Connection Failed

**Symptom**: Container unhealthy, logs show database connection errors

**Solution**:
```bash
# Check if postgres is running
docker compose ps postgres

# Verify pgvector extension
docker compose exec postgres psql -U nas_user -d nas_db \
  -c "SELECT * FROM pg_extension WHERE extname = 'vector';"

# Check network connectivity
docker compose exec ai-knowledge-agent ping postgres
```

### Out of Memory

**Symptom**: Container crashes or killed by OOM killer

**Solution**:
```bash
# Check memory usage
docker stats nas-ai-knowledge-agent

# Increase memory limit in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 6G  # Increase from 4G
```

---

## Development

### Local Testing

```bash
# Build image
docker build -t nas-ai-knowledge:1.0.0 .

# Run standalone (without compose)
docker run -it --rm \
  -e DATABASE_URL="postgres://nas_user:password@host.docker.internal:5432/nas_db" \
  -e MODEL_NAME="sentence-transformers/all-MiniLM-L6-v2" \
  --name ai-knowledge-test \
  nas-ai-knowledge:1.0.0

# Test health endpoint
curl http://localhost:8000/health
```

### Adding New Models

To use a different sentence-transformer model:

1. Update `MODEL_NAME` environment variable
2. Adjust memory limits if needed
3. Rebuild and redeploy

Example models:
- `sentence-transformers/all-mpnet-base-v2` (768 dims, better quality, slower)
- `sentence-transformers/all-MiniLM-L12-v2` (384 dims, slower than L6)
- `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` (multilingual)

---

## Dependencies

- **Python**: 3.11-slim
- **PyTorch**: 2.1.0 (CPU-only)
- **sentence-transformers**: 2.2.2
- **PostgreSQL**: psycopg2-binary 2.9.9
- **pgvector**: 0.2.3
- **Flask**: 3.0.0 (health checks)
- **SQLAlchemy**: 2.0.23
- **loguru**: 0.7.2

Total image size: ~1.5 GB (vs ~3.5 GB with CUDA PyTorch)

---

## Future Enhancements (Phase 2.3+)

- [ ] Batch embedding generation endpoint
- [ ] Embedding caching in Redis
- [ ] Support for multiple models
- [ ] Fine-tuning on custom data
- [ ] Integration with API service for /search/semantic
- [ ] Scheduled re-embedding of updated files
- [ ] Metrics export (processing speed, queue depth)

---

**Built for NAS.AI Phase 2.2**
**Ready for semantic search and AI-powered features**

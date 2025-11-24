#!/usr/bin/env bash

set -euo pipefail

echo "Lade KI-Modell (Phi-3 Mini)... Das dauert etwas..."
docker exec nas-ollama ollama pull phi3:mini
echo "Modell bereit!"

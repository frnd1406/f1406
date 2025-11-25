#!/bin/bash

# Farben für bessere Lesbarkeit
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 💾 NAS AI SYSTEM SAVEPOINT MANAGER ===${NC}"

# 1. Prüfen, ob wir in einem Git-Repo sind
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Initialisiere neues Git-Repository...${NC}"
    git init
else
    echo -e "${GREEN}Git Repository gefunden.${NC}"
fi

# 2. Remote URL Check (Nur fragen, wenn noch nicht gesetzt)
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")

if [ -z "$CURRENT_REMOTE" ]; then
    echo ""
    echo -e "${YELLOW}Kein Remote-Server konfiguriert.${NC}"
    read -p "Bitte gib die GitHub-URL ein (z.B. https://github.com/user/repo.git): " REMOTE_URL
    
    if [ ! -z "$REMOTE_URL" ]; then
        git remote add origin "$REMOTE_URL"
        echo -e "${GREEN}Remote 'origin' gesetzt auf: $REMOTE_URL${NC}"
    else
        echo -e "${RED}Keine URL eingegeben. Fahre lokal fort.${NC}"
    fi
else
    echo -e "Remote URL ist bereits gesetzt: ${BLUE}$CURRENT_REMOTE${NC}"
fi

# 3. Status anzeigen
echo ""
echo -e "${BLUE}--- Status der Änderungen ---${NC}"
git status -s

# Prüfen, ob es überhaupt Änderungen gibt
if [ -z "$(git status --porcelain)" ]; then
    echo ""
    echo -e "${GREEN}Alles sauber. Keine Änderungen zum Speichern.${NC}"
    exit 0
fi

# 4. Dateien hinzufügen
echo ""
echo -e "${YELLOW}Füge alle Änderungen hinzu (git add .)...${NC}"
git add .

# 5. Name des Savepoints abfragen
echo ""
read -p "Wie soll dieser Savepoint heißen? (z.B. 'Phase 7 Start'): " COMMIT_MSG

# Fallback, falls leer
if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="Auto-Savepoint: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${YELLOW}Kein Name eingegeben. Nutze Standard: '$COMMIT_MSG'${NC}"
fi

# 6. Commit erstellen
echo ""
echo -e "${YELLOW}Erstelle Commit...${NC}"
git commit -m "$COMMIT_MSG"

# 7. Push (Nur wenn Remote existiert)
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
if [ ! -z "$CURRENT_REMOTE" ]; then
    echo ""
    echo -e "${YELLOW}Lade hoch zu GitHub (Push)...${NC}"
    
    # Versuche Push. Wenn Branch noch nicht upstream ist, setze upstream.
    CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
    git push -u origin "$CURRENT_BRANCH"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Savepoint '$COMMIT_MSG' erfolgreich gespeichert und hochgeladen!${NC}"
    else
        echo ""
        echo -e "${RED}❌ Fehler beim Upload. Bitte Internetverbindung oder Zugangsdaten prüfen.${NC}"
    fi
else
    echo ""
    echo -e "${GREEN}✅ Savepoint '$COMMIT_MSG' lokal gespeichert (kein Remote konfiguriert).${NC}"
fi
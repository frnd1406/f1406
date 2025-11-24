#!/bin/bash
# Erstellt neues Status-Log mit korrekter Nummerierung
# Erstellt: 2025-11-15 (DocumentationAgent)
# Referenz: status/DocumentationAgent/035_20251115_status-structure-analysis.md

set -e

if [ $# -lt 2 ]; then
  echo "Usage: $0 <AgentName> <description>"
  echo ""
  echo "Beispiele:"
  echo "  $0 SystemSetupAgent vault-tls-deployment"
  echo "  $0 APIAgent jwt-hardening-complete"
  echo "  $0 DocumentationAgent contributing-guide"
  echo ""
  echo "Verfügbare Agents:"
  ls -d /home/freun/Agent/status/*/ 2>/dev/null | xargs -n1 basename | grep -v "^archive$\|^reports$\|^security$"
  exit 1
fi

AGENT=$1
DESC=$2
BASE_DIR="/home/freun/Agent"

# Validiere Agent-Name
AGENT_DIR="$BASE_DIR/status/$AGENT"
if [ ! -d "$AGENT_DIR" ]; then
  echo "❌ Fehler: Agent '$AGENT' nicht gefunden"
  echo ""
  echo "Verfügbare Agents:"
  ls -d $BASE_DIR/status/*/ 2>/dev/null | xargs -n1 basename | grep -v "^archive$\|^reports$\|^security$"
  exit 1
fi

# Finde höchste Nummer (rekursiv in Unterordnern)
LAST=$(find "$AGENT_DIR" -name "*.md" -type f \
  | grep -o '[0-9]\{3\}_' \
  | sort -n \
  | tail -1 \
  | sed 's/_//')

if [ -z "$LAST" ]; then
  NEXT="001"
else
  NEXT=$(printf "%03d" $((10#$LAST + 1)))
fi

# Datum (YYYYMMDD)
DATE=$(date +%Y%m%d)

# Validiere Beschreibung (nur lowercase + dashes)
if ! [[ "$DESC" =~ ^[a-z0-9-]+$ ]]; then
  echo "❌ Fehler: Beschreibung darf nur lowercase + dashes enthalten"
  echo "Ungültig: $DESC"
  echo "Gültig: vault-tls-deployment"
  exit 1
fi

# Dateiname
FILENAME="${NEXT}_${DATE}_${DESC}.md"
FILEPATH="$AGENT_DIR/$FILENAME"

# Prüfe ob Datei bereits existiert
if [ -f "$FILEPATH" ]; then
  echo "❌ Fehler: Datei existiert bereits: $FILEPATH"
  exit 1
fi

# Beschreibung mit erstem Buchstaben groß
DESC_TITLE=$(echo "$DESC" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

# Erstelle Datei mit Template
cat > "$FILEPATH" <<EOF
# $DESC_TITLE – Status Log

**Agent:** $AGENT
**Datum:** $(date +"%d. %B %Y")
**Status:** 🔄 IN PROGRESS

---

## Auftrag

(Beschreibung der Aufgabe)

---

## Durchgeführte Schritte

1. ...

---

## Ergebnis

**Status:**

(Zusammenfassung des Ergebnisses)

---

**$AGENT – Terminal freigegeben.**
EOF

echo "✅ Status-Log erstellt: $FILEPATH"
echo ""
echo "📝 Nächste Schritte:"
echo "   1. Datei bearbeiten: nano $FILEPATH"
echo "   2. Git hinzufügen: git add $FILEPATH"
echo "   3. Commit erstellen: git commit -m \"Add $FILENAME\""
echo ""
echo "📖 Namenskonvention: NNN_YYYYMMDD_lowercase-description.md"
echo "📚 Referenz: status/DocumentationAgent/035_20251115_status-structure-analysis.md"

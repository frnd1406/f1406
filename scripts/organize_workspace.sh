#!/bin/bash

# Definiere das Archiv-Verzeichnis
ARCHIVE_DIR="Agent/docs/archive_planning"

# Erstelle das Archiv, falls es nicht existiert
if [ ! -d "$ARCHIVE_DIR" ]; then
    echo "Erstelle Archiv-Ordner: $ARCHIVE_DIR"
    mkdir -p "$ARCHIVE_DIR"
fi

echo "--- Starte Aufräumarbeiten ---"

# 1. Verschiebe reine Planungsunterlagen (Roadmaps, Matrizen)
if [ -d "Agent/docs/planning" ]; then
    echo "Verschiebe 'planning' ins Archiv..."
    mv Agent/docs/planning "$ARCHIVE_DIR/"
fi

# 2. Verschiebe Visionen und Konzepte (keine konkrete Technik)
if [ -d "Agent/docs/vision" ]; then
    echo "Verschiebe 'vision' ins Archiv..."
    mv Agent/docs/vision "$ARCHIVE_DIR/"
fi

# 3. Verschiebe Struktur-Vorschläge
if [ -f "Agent/docs/STRUCTURE_PROPOSAL.md" ]; then
    mv Agent/docs/STRUCTURE_PROPOSAL.md "$ARCHIVE_DIR/"
fi

if [ -f "Agent/docs/vision/FUTURE_CONCEPTS.md" ]; then
     # Falls der Ordner oben nicht verschoben wurde (weil Datei einzeln)
     mv Agent/docs/vision/FUTURE_CONCEPTS.md "$ARCHIVE_DIR/"
fi

echo "--- Aufräumen abgeschlossen ---"
echo "Die technischen Blueprints (Agent/docs/blueprints) und Developer Guides wurden BEHALTEN,"
echo "da diese für die Programmierung notwendig sind."
echo "Alle Planungsdateien liegen nun in: $ARCHIVE_DIR"
#!/usr/bin/env bash
# Descarga el modelo de IA local que se empaqueta como asset de la app
# (ADR-03). Se ejecuta UNA VEZ, antes de compilar: el modelo resultante no
# sale de assets/modelo_ia/ ni viaja por red durante el uso normal de la app.
#
# El fichero no se versiona (ver .gitignore): pesa ~1,6 GB y GitHub rechaza
# archivos de más de 100 MB en un commit normal.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/assets/modelo_ia"
ARCHIVO="$DIR/qwen2.5-1.5b-instruct-q8.task"
URL="https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv1280.task"

mkdir -p "$DIR"

if [ -f "$ARCHIVO" ]; then
  echo "Ya existe: $ARCHIVO"
  exit 0
fi

echo "Descargando modelo de IA local (~1,6 GB)…"
curl -sSL -o "$ARCHIVO" "$URL"
echo "Listo: $ARCHIVO"

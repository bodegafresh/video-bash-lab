#!/bin/bash

command -v montage >/dev/null 2>&1 || { echo >&2 "ImageMagick (montage) no está instalado. Instálalo con 'sudo apt install imagemagick' o 'brew install imagemagick'"; exit 1; }

# Uso: ./thumbs_contact_sheet.sh thumbs_labeled/ 6
# Une todas las imágenes de thumbs_labeled/ en una matriz de 6 columnas

DIR="${1:-thumbs_labeled}"
COLS="${2:-6}"
montage "$DIR"/thumb_*.jpg -tile "${COLS}x" -geometry +2+2 contact_sheet.jpg
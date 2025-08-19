#!/bin/bash

command -v montage >/dev/null 2>&1 || { echo >&2 "ImageMagick (montage) no está instalado. Instálalo con 'sudo apt install imagemagick' o 'brew install imagemagick'"; exit 1; }
command -v mogrify >/dev/null 2>&1 || { echo >&2 "ImageMagick (mogrify) no está instalado. Instálalo con 'sudo apt install imagemagick' o 'brew install imagemagick'"; exit 1; }

DIR="${1:-thumbs_labeled}"
COLS="${2:-6}"
ROWS="${3:-6}"
TMPDIR="tmp_contact"
OUT="contact_sheet.jpg"

mkdir -p "$TMPDIR"
cp "$DIR"/*.jpg "$TMPDIR/"
cd "$TMPDIR"

# Redimensionar todas las miniaturas a 320px de ancho (ajusta si quieres)
mogrify -resize 320x *.jpg

# Eliminar imágenes corruptas o vacías
for img in *.jpg; do
  identify "$img" >/dev/null 2>&1 || rm -f "$img"
done

find_valid_images() {
  for img in *.jpg; do
    identify "$img" >/dev/null 2>&1 && echo "$img"
  done
}

# ...existing code...

level=0
while true; do
  files=( $(find_valid_images | grep -v "^sheet_") )
  sheets=( $(find_valid_images | grep "^sheet_") )
  count=${#files[@]}
  sheet_count=${#sheets[@]}

  # Si ya no hay miniaturas y solo queda un sheet, ese es el resultado final
  if [[ $count -eq 0 && $sheet_count -eq 1 ]]; then
    mv "${sheets[0]}" "../$OUT"
    break
  fi
  # Si no hay imágenes válidas, aborta
  if [[ $count -eq 0 && $sheet_count -eq 0 ]]; then
    echo "No hay imágenes válidas para montar."
    exit 1
  fi

  i=0
  for ((start=0; start<count; start+=COLS*ROWS)); do
    group=( "${files[@]:start:COLS*ROWS}" )
    montage "${group[@]}" -tile ${COLS}x${ROWS} -geometry +2+2 "sheet_${level}_$i.jpg"
    ((i++))
  done
  rm -f $(printf "%s\n" "${files[@]}")
  ((level++))
done

cd ..
rm -rf "$TMPDIR"

echo "Contact sheet generado: $OUT"
#!/bin/bash

command -v convert >/dev/null 2>&1 || { echo >&2 "ImageMagick (convert) no está instalado. Instálalo con 'sudo apt install imagemagick' o 'brew install imagemagick'"; exit 1; }

VTT_FILE="thumbnails.vtt"
INPUT_DIR="thumbs"
OUTPUT_DIR="thumbs_labeled"

mkdir -p "$OUTPUT_DIR"

# Contador para enlazar imágenes con líneas del VTT
i=1

while IFS= read -r line; do
  # Solo procesar líneas de tiempo tipo 00:00:00.000 --> 00:00:05.000
  if [[ "$line" == *"-->"* ]]; then
    start_time=$(echo "$line" | cut -d ' ' -f1)
    input_img=$(printf "$INPUT_DIR/thumb_%04d.jpg" "$i")
    output_img=$(printf "$OUTPUT_DIR/thumb_%04d.jpg" "$i")

    if [[ -f "$input_img" ]]; then
      convert "$input_img" -gravity SouthEast -fill white -undercolor '#00000080' \
        -font DejaVu-Sans -pointsize 18 -annotate +5+5 "$start_time" "$output_img"
    fi

    ((i++))
  fi
done < "$VTT_FILE"

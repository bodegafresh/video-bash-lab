#!/bin/bash

command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "ffmpeg no está instalado. Instálalo con 'sudo apt install ffmpeg' o 'brew install ffmpeg'"; exit 1; }

# Uso: ./thumbs_vtt.sh input.mp4 [intervalo_segundos]
# Genera miniaturas en thumbs/ y un thumbnails.vtt compatible

# ...existing code...
VIDEO="$1"
INTERVAL="${2:-5}" # Intervalo en segundos (default: 5)
OUTDIR="thumbs"
VTT="thumbnails.vtt"

if [[ -z "$VIDEO" || ! -f "$VIDEO" ]]; then
  echo "ERROR: Debes indicar un archivo de video válido como primer argumento."
  echo "Ejemplo: ./thumbs_vtt.sh input_videos/input_r03_01.mkv"
  exit 1
fi

mkdir -p "$OUTDIR"
rm -f "$OUTDIR"/*.jpg "$VTT"
# ...existing code...

# 1. Extraer duración
DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO")
DUR=${DUR%.*}

# 2. Generar miniaturas
i=1
for ((t=0; t<DUR; t+=INTERVAL)); do
  ffmpeg -y -ss "$t" -i "$VIDEO" -vframes 1 -q:v 2 "$(printf "$OUTDIR/thumb_%04d.jpg" "$i")"
  ((i++))
done

# 3. Generar VTT
echo "WEBVTT" > "$VTT"
i=1
for ((t=0; t<DUR; t+=INTERVAL)); do
  start=$(printf "%02d:%02d:%02d.000" $((t/3600)) $(( (t%3600)/60 )) $((t%60)))
  end_t=$((t+INTERVAL))
  [[ $end_t -gt $DUR ]] && end_t=$DUR
  end=$(printf "%02d:%02d:%02d.000" $((end_t/3600)) $(( (end_t%3600)/60 )) $((end_t%60)))
  echo -e "\n$start --> $end\n$(printf "$OUTDIR/thumb_%04d.jpg" "$i")" >> "$VTT"
  ((i++))
done
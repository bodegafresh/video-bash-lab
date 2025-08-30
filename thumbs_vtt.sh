#!/usr/bin/env bash
set -euo pipefail

command -v ffmpeg >/dev/null || { echo "ffmpeg no está instalado"; exit 1; }
command -v ffprobe >/dev/null || { echo "ffprobe no está instalado"; exit 1; }

usage() {
  cat <<EOF
Uso: $0 input.mp4 [--fps N | --interval S] [--width W] [--format jpg|png|webp] [--quality Q] [--outdir DIR]
Ejemplos:
  $0 video.mp4 --fps 2 --format png               # Máxima calidad (sin pérdida)
  $0 video.mp4 --fps 2 --format webp --quality 100 --lossless 1
  $0 video.mp4 --fps 2 --format jpg --quality 2   # JPG casi sin pérdidas visibles
EOF
  exit 1
}

VIDEO="${1:-}"; shift || true
[[ -z "${VIDEO}" || ! -f "${VIDEO}" ]] && usage

FPS=""
INTERVAL=""
WIDTH=320
FORMAT="jpg"      # jpg | png | webp
QUALITY=""        # jpg/webp: 1..31 (1=mejor). png: 0..9 (0=sin compresión)
LOSSLESS=""       # webp: 1 para lossless
OUTDIR="thumbs"
VTT="thumbnails.vtt"

# Parseo simple
while [[ $# -gt 0 ]]; do
  case "$1" in
    --fps)      FPS="$2"; shift 2 ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    --width)    WIDTH="$2"; shift 2 ;;
    --format)   FORMAT="$2"; shift 2 ;;
    --quality)  QUALITY="$2"; shift 2 ;;
    --lossless) LOSSLESS="$2"; shift 2 ;;
    --outdir)   OUTDIR="$2"; shift 2 ;;
    *) echo "Flag desconocida: $1"; usage ;;
  esac
done

if [[ -n "$INTERVAL" ]]; then
  FPS=$(awk -v i="$INTERVAL" 'BEGIN { if (i<=0) exit 1; printf "%.6f", 1.0/i }') || { echo "Intervalo inválido"; exit 1; }
fi
FPS=${FPS:-2}

mkdir -p "$OUTDIR"
rm -f "$OUTDIR"/thumb_* "$VTT"

# Duración en float
DUR=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$VIDEO")

# Filtros de video: fps + escala de alta calidad
VF="fps=${FPS},scale=${WIDTH}:-1:flags=lanczos"

# Opciones específicas por formato
EXT="$FORMAT"
ENC_OPTS=()
case "$FORMAT" in
  jpg|jpeg)
    EXT="jpg"
    # -q:v 1..3 = muy alta calidad; 1 es el máximo.
    Q="${QUALITY:-2}"
    ENC_OPTS=(-q:v "$Q")
    ;;
  png)
    EXT="png"
    # -compression_level 0..9 (9 = más compresión, mismo contenido SIN pérdida)
    CL="${QUALITY:-9}"
    ENC_OPTS=(-compression_level "$CL" -pred mixed)
    ;;
  webp)
    EXT="webp"
    if [[ "${LOSSLESS:-0}" == "1" ]]; then
      ENC_OPTS=(-lossless 1 -q:v "${QUALITY:-100}")
    else
      # WEBP con pérdida: 0..100 (100 = mejor calidad)
      ENC_OPTS=(-q:v "${QUALITY:-95}")
    fi
    ;;
  *)
    echo "Formato no soportado: $FORMAT"; exit 1;;
esac

# 1) Extraer las imágenes en UNA pasada (máxima nitidez + calidad)
ffmpeg -hide_banner -loglevel error -y \
  -i "$VIDEO" \
  -vf "$VF" \
  -sws_flags lanczos+accurate_rnd \
  "${ENC_OPTS[@]}" \
  "$OUTDIR/thumb_%06d.$EXT"

# Recuento
COUNT=$(ls -1 "$OUTDIR"/thumb_*."$EXT" 2>/dev/null | wc -l | tr -d '[:space:]')

# Helper: segundos(float) -> HH:MM:SS.mmm
sec_to_vtt() {
  local s="$1"
  local H=$(awk -v s="$s" 'BEGIN{printf "%02d", int(s/3600)}')
  local M=$(awk -v s="$s" 'BEGIN{printf "%02d", int(s%3600/60)}')
  local S=$(awk -v s="$s" 'BEGIN{printf "%06.3f", s%60}')
  echo "${H}:${M}:${S}"
}

# 2) Generar VTT
echo "WEBVTT" > "$VTT"
for ((k=1;k<=COUNT;k++)); do
  start=$(awk -v k="$k" -v r="$FPS" 'BEGIN{printf "%.3f", (k-1)/r}')
  end=$(awk -v k="$k" -v r="$FPS" -v d="$DUR" 'BEGIN{e=k/r; if(e>d)e=d; printf "%.3f", e}')
  printf "\n%s --> %s\n%s\n" "$(sec_to_vtt "$start")" "$(sec_to_vtt "$end")" \
         "$(printf "%s/thumb_%06d.%s" "$OUTDIR" "$k" "$EXT")" >> "$VTT"
done

echo "Listo. Thumbs en $OUTDIR/*.${EXT} y VTT en $VTT"

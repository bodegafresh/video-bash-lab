#!/usr/bin/env bash

command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "ffmpeg no está instalado. Instálalo con 'sudo apt install ffmpeg' o 'brew install ffmpeg'"; exit 1; }

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Uso: $0 input_video output.mov"
  exit 1
fi

IN="$1"
OUT="$2"

ffmpeg -y -i "$IN" \
  -c:v prores_ks -profile:v 1 \
  -pix_fmt yuv422p10le \
  -color_range tv -colorspace bt709 -color_primaries bt709 -color_trc bt709 \
  -vf "format=yuv422p10le" \
  -c:a pcm_s16le -ar 48000 -ac 2 \
  "$OUT"

# Alternativa DNxHR:
# ffmpeg -y -i "$IN" -c:v dnxhd -profile:v dnxhr_lb -pix_fmt yuv422p \
#   -c:a pcm_s16le -ar 48000 -ac 2 "$OUT"
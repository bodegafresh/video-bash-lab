#!/usr/bin/env bash
command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "ffmpeg no está instalado. Instálalo con 'sudo apt install ffmpeg' o 'brew install ffmpeg'"; exit 1; }

set -euo pipefail
if [[ $# -lt 3 ]]; then
  echo "Uso: $0 input_video audio_nuevo.wav output_video.mp4|.mov"
  exit 1
fi

IN_V="$1"
IN_A="$2"
OUT="$3"

ffmpeg -y -i "$IN_V" -i "$IN_A" \
  -map 0:v:0 -map 1:a:0 -c:v copy \
  -c:a aac -b:a 192k -ar 48000 \
  -movflags +faststart \
  "$OUT"

# Para PCM sin pérdidas:
# ffmpeg -y -i "$IN_V" -i "$IN_A" -map 0:v:0 -map 1:a:0 -c:v copy -c:a pcm_s16le "$OUT"
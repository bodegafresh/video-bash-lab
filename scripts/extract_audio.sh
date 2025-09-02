#!/usr/bin/env bash

command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "ffmpeg no está instalado. Instálalo con 'sudo apt install ffmpeg' o 'brew install ffmpeg'"; exit 1; }

set -euo pipefail
if [[ $# -lt 2 ]]; then
  echo "Uso: $0 input_video output.wav"
  exit 1
fi

ffmpeg -y -i "$1" -vn -ac 2 -ar 48000 -c:a pcm_s24le "$2"
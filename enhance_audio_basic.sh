#!/usr/bin/env bash

command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "ffmpeg no está instalado. Instálalo con 'sudo apt install ffmpeg' o 'brew install ffmpeg'"; exit 1; }

set -euo pipefail
if [[ $# -lt 3 ]]; then
  echo "Uso: $0 input.wav rnnoise.model output_enhanced.wav"
  exit 1
fi

IN="$1"
MODEL="$2"
OUT="$3"

if [[ ! -f "$MODEL" ]]; then
  echo "No se encontró el modelo rnnoise: $MODEL"
  exit 1
fi

ffmpeg -y -i "$IN" -ac 2 -ar 48000 -c:a pcm_s24le \
-af "
arnndn=m=$MODEL,                                    \
loudnorm=I=-14:TP=-1.0:LRA=11:measured_I=-999,      \
acompressor=threshold=-20dB:ratio=3.5:attack=5:release=150:makeup=4, \
equalizer=f=110:t=s:w=1.0:g=3,                      \
equalizer=f=7500:t=s:w=1.0:g=-2                     \
" \
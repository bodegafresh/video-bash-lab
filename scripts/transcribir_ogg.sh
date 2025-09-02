#!/usr/bin/env bash
set -euo pipefail

# =========================
# Transcribir .ogg con ffmpeg + whisper.cpp
# Requisitos: git, build-essential (o make/clang/gcc), ffmpeg, curl
# Salida: .txt y .srt en ./salida/<base>/
# Vars opcionales:
#   MODEL_SIZE: tiny|base|small|medium|large-v3   (por defecto: small)
#   LANG: es|en|auto                              (por defecto: auto)
# =========================

INPUT="${1:-}"
if [[ -z "${INPUT}" ]]; then
  echo "Uso: $0 archivo.ogg [--keep-wav]"
  exit 1
fi
KEEP_WAV="${2:-}"

MODEL_SIZE="${MODEL_SIZE:-small}"
LANG="${LANG:-auto}"
OUT_ROOT="salida"

command -v ffmpeg >/dev/null || { echo "Falta ffmpeg. Instálalo: sudo apt-get install ffmpeg"; exit 1; }
command -v git >/dev/null || { echo "Falta git. Instálalo: sudo apt-get install git"; exit 1; }
command -v make >/dev/null || { echo "Falta make. Instálalo: sudo apt-get install build-essential"; exit 1; }

# 1) Preparar whisper.cpp
if [[ ! -d whisper.cpp ]]; then
  echo "[+] Clonando whisper.cpp..."
  git clone --depth=1 https://github.com/ggerganov/whisper.cpp.git
fi

if [[ ! -x whisper.cpp/main ]]; then
  echo "[+] Compilando whisper.cpp..."
  make -C whisper.cpp -j
fi

# 2) Descargar modelo (GGUF) si no existe
# Usamos el script oficial que trae el repo para evitar nombres cambiantes
MODEL_DIR="whisper.cpp/models"
mkdir -p "${MODEL_DIR}"
MODEL_GLOB="${MODEL_DIR}/ggml-${MODEL_SIZE}"*.bin

if ! ls ${MODEL_GLOB} >/dev/null 2>&1; then
  echo "[+] Descargando modelo ${MODEL_SIZE} (GGUF)..."
  bash whisper.cpp/models/download-ggml-model.sh "${MODEL_SIZE}"
fi

# Seleccionar el primer modelo que coincida (p.ej., ggml-small-q5_1.gguf)
MODEL_FILE=$(ls ${MODEL_GLOB} | head -n1)
if [[ ! -f "${MODEL_FILE}" ]]; then
  echo "No se encontró el modelo GGUF descargado en ${MODEL_DIR}. Revisa la descarga."
  exit 1
fi

# 3) Convertir OGG -> WAV mono 16 kHz (formato ideal para whisper.cpp)
BASENAME="$(basename "${INPUT%.*}")"
OUT_DIR="${OUT_ROOT}/${BASENAME}"
mkdir -p "${OUT_DIR}"
WAV="${OUT_DIR}/${BASENAME}.wav"

echo "[+] Convirtiendo a WAV mono 16k..."
ffmpeg -y -i "${INPUT}" -ac 1 -ar 16000 -vn -hide_banner -loglevel error "${WAV}"

# 4) Transcribir con whisper.cpp
# -osrt y -otxt generan SRT y TXT
# -ofolder escribe en el mismo directorio de salida
# -l <idioma> (omitimos si es auto)
WHISPER_CMD=( ./whisper.cpp/main -m "${MODEL_FILE}" -f "${WAV}" -osrt -otxt -ofolder "${OUT_DIR}" )
if [[ "${LANG}" != "auto" ]]; then
  WHISPER_CMD+=( -l "${LANG}" )
fi

echo "[+] Transcribiendo con whisper.cpp (modelo: ${MODEL_SIZE}, idioma: ${LANG})..."
"${WHISPER_CMD[@]}"

# 5) Limpieza opcional
if [[ "${KEEP_WAV}" != "--keep-wav" ]]; then
  rm -f "${WAV}"
fi

echo
echo "✅ Listo."
echo "TXT: ${OUT_DIR}/${BASENAME}.wav.txt"
echo "SRT: ${OUT_DIR}/${BASENAME}.wav.srt"

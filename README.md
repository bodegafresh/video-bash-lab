# 🎬 video-bash-lab

Colección de scripts Bash para acelerar y automatizar tareas de edición de video en Linux y macOS.  
Ideal para creadores, editores y entusiastas que usan DaVinci Resolve, OBS Studio, Audacity y flujos profesionales.

---

## ¡Bienvenido/a!

¿Te resultó útil? ¡Dale una estrella, comparte y contribuye con tus mejoras!  
Este proyecto está pensado para la comunidad: si tienes ideas, pull requests o mejoras, ¡son bienvenidas!

**Autor:** [bodegafresh](https://github.com/bodegafresh)  
**Instagram/TikTok:** [@bodegafresh_dev - Instagram](https://instagram.com/bodegafresh_dev)/[@bodegafresh_dev - Tiktok](http://www.titok.com/@bodegafresh_dev)

---

## Compatibilidad y dependencias

**Todos los scripts funcionan en Linux y macOS** si tienes instalados:

- [ffmpeg](https://ffmpeg.org/)
- [ImageMagick](https://imagemagick.org/) (`convert`, `montage`)

### Instalación rápida en macOS (con Homebrew):

```bash
brew install ffmpeg imagemagick
```

### Instalación rápida en Linux (Debian/Ubuntu):

```bash
sudo apt update
sudo apt install ffmpeg imagemagick
```

> Todos los scripts verifican automáticamente que las dependencias estén instaladas antes de ejecutarse.

---

## Índice de scripts

- [🎬 video-bash-lab](#-video-bash-lab)
  - [¡Bienvenido/a!](#bienvenidoa)
  - [Compatibilidad y dependencias](#compatibilidad-y-dependencias)
    - [Instalación rápida en macOS (con Homebrew):](#instalación-rápida-en-macos-con-homebrew)
    - [Instalación rápida en Linux (Debian/Ubuntu):](#instalación-rápida-en-linux-debianubuntu)
  - [Índice de scripts](#índice-de-scripts)
  - [thumbs\_vtt.sh](#thumbs_vttsh)
  - [tiempo\_thumbs.sh](#tiempo_thumbssh)
  - [thumbs\_contact\_sheet.sh](#thumbs_contact_sheetsh)
  - [to\_resolve.sh](#to_resolvesh)
  - [extract\_audio.sh](#extract_audiosh)
  - [replace\_audio.sh](#replace_audiosh)
  - [enhance\_audio\_basic.sh](#enhance_audio_basicsh)
  - [enhance\_audio\_rnnoise.sh](#enhance_audio_rnnoisesh)
  - [Ejemplo de flujo recomendado](#ejemplo-de-flujo-recomendado)
  - [Notas y sugerencias](#notas-y-sugerencias)
  - [Exclusión de archivos procesados](#exclusión-de-archivos-procesados)

---

## thumbs_vtt.sh

Genera miniaturas y un archivo VTT para previsualización de videos (útil para reproductores web o análisis posterior).

**Uso:**  
```bash
./thumbs_vtt.sh input.mp4 [intervalo_segundos]
```
- Crea una carpeta `thumbs/` con miniaturas y un archivo `thumbnails.vtt` con los tiempos de cada imagen.

---

## tiempo_thumbs.sh

Toma las miniaturas y el archivo VTT generados por `thumbs_vtt.sh` y crea nuevas imágenes con el tiempo incrustado en cada miniatura (útil para análisis visual o IA).

**Uso:**  
```bash
./tiempo_thumbs.sh
```
- Lee `thumbnails.vtt` y las imágenes en `thumbs/`, y genera imágenes etiquetadas en `thumbs_labeled/`.

---

## thumbs_contact_sheet.sh

(Opcional) Une todas las miniaturas etiquetadas en una sola imagen tipo "contact sheet" o matriz, ideal para revisión rápida o entrada a modelos de IA.

**Uso:**  
```bash
./thumbs_contact_sheet.sh thumbs_labeled/ 6
```
- El segundo argumento es el número de columnas (por defecto 6).
- Requiere ImageMagick (`montage`).

---

## to_resolve.sh

Convierte un video a un formato "mezzanine" editable y liviano para DaVinci Resolve (ProRes 422 LT + audio PCM 48kHz).

**Uso:**  
```bash
./to_resolve.sh input_video output.mov
```
- Usa ProRes 422 LT (intra-frame, decodifica muy liviano).
- Mantiene espacio de color BT.709 y 10-bit para grading.
- Alternativa DNxHR incluida en comentarios.

---

## extract_audio.sh

Extrae el audio principal de un video a WAV 48kHz listo para procesar.

**Uso:**  
```bash
./extract_audio.sh input_video output.wav
```
- Exporta en 24-bit para mayor headroom (puedes cambiar a 16-bit si prefieres).

---

## replace_audio.sh

Reemplaza el audio de un video por un archivo WAV/AAC ya procesado, sin recomprimir el video.

**Uso:**  
```bash
./replace_audio.sh input_video audio_nuevo.wav output_video.mp4
```
- Por defecto, exporta en AAC 192k.
- Si trabajas en MOV/ProRes y quieres PCM sin pérdidas, revisa los comentarios del script.

---

## enhance_audio_basic.sh

Mejora automática de audio con ffmpeg: reducción de ruido básica (afftdn), normalización, compresión y ecualización.

**Uso:**  
```bash
./enhance_audio_basic.sh input.wav output_enhanced.wav
```
- NR: afftdn=nr=12 (ajustable).
- Normaliza a -14 LUFS.
- Compresor y EQ para voz más grave y menos sibilancia.

---

## enhance_audio_rnnoise.sh

Mejora avanzada de audio usando reducción de ruido con RNNoise (arnndn), normalización, compresión y EQ.

**Uso:**  
```bash
./enhance_audio_rnnoise.sh input.wav rnnoise.model output_enhanced.wav
```
- Descarga un modelo RNNoise compatible y pásalo como argumento.
- Ideal para ambientes con mucho ruido.

---

## Ejemplo de flujo recomendado

```bash
# 1. Convertir a mezzanine para editar fluido:
./to_resolve.sh input.mp4 master_edit.mov

# 2. Extraer audio:
./extract_audio.sh master_edit.mov voz_orig.wav

# 3. Mejorar audio (elige básico o RNNoise):
./enhance_audio_basic.sh voz_orig.wav voz_ok.wav
# o
./enhance_audio_rnnoise.sh voz_orig.wav rnnoise.model voz_ok.wav

# 4. Reemplazar audio:
./replace_audio.sh master_edit.mov voz_ok.wav final_edit.mov

# 5. Generar miniaturas y VTT:
./thumbs_vtt.sh final_edit.mov 5

# 6. Etiquetar miniaturas con tiempo:
./tiempo_thumbs.sh

# 7. (Opcional) Unir miniaturas etiquetadas en una matriz:
./thumbs_contact_sheet.sh thumbs_labeled 6
```

---

## Notas y sugerencias

- **Loudness:** Para IG/TikTok/YouTube Shorts, -14 LUFS funciona muy bien.
- **EQ:** Ajusta los parámetros según tu voz y preferencias.
- **De-esser:** Puedes añadir un de-esser simple con:  
  `-af "... , deesser=f=6000:width=2000:thres=0.2 , ..."`
- **Sin recomprimir video:** El script de reemplazo usa `-c:v copy` para no tocar la imagen.
- **Dependencias:** ffmpeg, ImageMagick (`convert`, `montage`).

---

## Exclusión de archivos procesados

Para mantener tu repositorio limpio, los archivos generados (miniaturas, WAVs, VTT, matrices, etc.) están excluidos mediante `.gitignore`.  
Si prefieres, puedes configurar los scripts para que guarden los archivos procesados fuera de esta carpeta.

---

> Todos los scripts son Bash y requieren ffmpeg instalado.  
> Recuerda dar permisos de ejecución:  
> `chmod +x script.sh`
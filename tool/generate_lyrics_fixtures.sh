#!/usr/bin/env bash
# Regenerate the lyrics fixtures under test/lyrics/.
#
# The fixtures are small generated files (see AGENTS.md): the audio is
# generated with ffmpeg and, for MP3 only, the lyrics are re-written as a
# standard ID3v2 USLT frame afterwards, because ffmpeg stores them as a
# non-standard TXXX:USLT frame.
#
# Usage:
#   bash tool/generate_lyrics_fixtures.sh

set -euo pipefail

cd "$(dirname "$0")/.."

LYRICS=$'[00:00.00]Test lyrics demo\n[00:05.00]First line of the song\n[00:10.00]Second line of the song\n[00:15.00]Third and final line'

mkdir -p test/lyrics

generate() {
  local ext="$1"
  local codec="$2"
  ffmpeg -hide_banner -loglevel error \
    -f lavfi -i "sine=frequency=440:duration=1" \
    -c:a "$codec" \
    -metadata title="Lyrics Demo" \
    -metadata artist="Demo Artist" \
    -metadata album="Demo Album" \
    -metadata lyrics="$LYRICS" \
    -y "test/lyrics/lyrics.$ext"
}

# MP3 (libmp3lame) then re-inject a standard USLT frame.
generate mp3 libmp3lame
printf '%s' "$LYRICS" > /tmp/lyrics_demo.txt
python3 tool/make_mp3_uslt.py test/lyrics/lyrics.mp3 /tmp/lyrics_demo.txt
rm -f /tmp/lyrics_demo.txt

# FLAC / M4A / OGG / Opus carry the lyrics natively (Vorbis comment or ©lyr).
generate flac flac
generate m4a aac

# OGG: `libvorbis` is not built into every ffmpeg, so use the native `vorbis`
# encoder (experimental, needs `-strict -2` and a stereo source).
rm -f test/lyrics/lyrics.ogg
ffmpeg -hide_banner -loglevel error \
  -f lavfi -i "sine=frequency=440:duration=1" \
  -ac 2 -c:a vorbis -strict -2 \
  -metadata title="Lyrics Demo" -metadata artist="Demo Artist" -metadata album="Demo Album" \
  -metadata lyrics="$LYRICS" \
  -y test/lyrics/lyrics.ogg

generate opus libopus

echo "fixtures regenerated:"
ls -lh test/lyrics/

#!/usr/bin/env bash
# Whole pipeline: music -> measurements -> hud constants -> flat pass -> lens pass.
# Run from anywhere: tools/render.sh   (-> out/unmute.mp4)
set -euo pipefail
cd "$(dirname "$0")/.."
export FF_BACKEND="${FF_BACKEND:-auto}" # auto, gpu (fail if unavailable), or cpu
case "$FF_BACKEND" in
  auto|gpu|cpu) ;;
  *) printf 'FF_BACKEND must be auto, gpu or cpu\n' >&2; exit 1 ;;
esac
command -v ffmpeg >/dev/null
command -v ffprobe >/dev/null
python=("${PYTHON:-python3}" -I)
if ! "${python[@]}" -c 'import numpy, scipy' 2>/dev/null; then
  command -v uv >/dev/null || { printf 'Install numpy/scipy for Python 3, or install uv\n' >&2; exit 1; }
  python=(uv run --no-project --with numpy --with scipy python -I)
fi
bin="${CARGO_TARGET_DIR:-target}/release"
mkdir -p out/pass
"${python[@]}" music/synth.py      # out/pass/music.wav, out/events.json, out/stems/
"${python[@]}" music/analyze.py    # out/measured.json
"${python[@]}" music/gen_hud.py    # hud/src/generated.rs
cargo build --release -p hud -p flat -p lens
"$bin"/flat render -o out/pass/flat.mp4
"$bin"/lens render -o out/unmute.mp4
ffprobe -v error -show_entries stream=codec_type,width,height,nb_frames,duration -of compact out/unmute.mp4

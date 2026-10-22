<div align="center">

# ff-unmute

**This one, you can unmute.** A camera flies over a DAW timeline in one 16-second shot, and a
tracker locks onto every beat the playhead touches.

The music is composed and synthesized in code. Every number on screen is measured from the
audio. All of it renders with [fframes](https://github.com/dmtrKovalenko/fframes).

[![fframes 1.2](https://img.shields.io/badge/fframes-1.2.0-ff5a1f)](https://github.com/dmtrKovalenko/fframes)
[![Rust 2024](https://img.shields.io/badge/rust-2024-b7410e?logo=rust)](https://www.rust-lang.org)
[![Python synth](https://img.shields.io/badge/music-numpy%20%2B%20scipy-3776ab?logo=python&logoColor=white)](music/)
[![License: MIT](https://img.shields.io/badge/license-MIT-2ea44f)](LICENSE)

<a href="https://github.com/mrsarac/ff-unmute/releases/latest/download/unmute.mp4">
  <img src="docs/media/hero.webp" width="800" alt="ff-unmute: a tilted close-up of a DAW timeline; the playhead sweeps a real waveform while tracker boxes lock onto kicks, bleeps and tokens; it ends on the whole track in one frame">
</a>

**[🔊 Full 1080p with sound](https://github.com/mrsarac/ff-unmute/releases/latest/download/unmute.mp4)** (the preview above is silent) ·
[On X](https://x.com/0xsarac/status/2108696032603463756) ·
[How it works](#how-it-works) ·
[Quick start](#quick-start)

<sub>fframes studies · <a href="https://github.com/mrsarac/ff-tracking">#1 ff-tracking</a> · <b>#2 ff-unmute</b></sub>

</div>

---

## Why this exists

[ff-tracking](https://github.com/mrsarac/ff-tracking) got a generous quote from the author of
fframes: *"what a fire … BUT DO NOT UNMUTE"*. He was right. That sound was measured and never
listened to. So this one starts from the sound. A score in code renders the track. The track
is measured. The picture is cut, lit and tracked from those measurements.

## What you are looking at

- **A real timeline.** The master waveform is drawn from the peaks of `music.wav`. The lanes
  hold the score's actual events: kick, clap and hats, a bass piano roll, chord blocks, and the
  agent's own lane of bleeps and tokens. Clips light up as the playhead passes them.
- **Locks on the beat.** Each of the 19 kicks locks a red box at the playhead on its exact frame.
  Bleeps and tokens get boxes too, labelled with what was measured: `kick 55.7 Hz`,
  `bleep 1762.6 Hz`, `token #19`.
- **A live FFT at the playhead.** fframes' own `visualize_audio_frame` reads `music.wav` and
  draws the spectrum strip next to the playhead.
- **One shot, no cuts.** The camera flies from the waveform to the kick lane, the bass and the
  agent lane, then pulls back. Palettes blend into each other over half a second.
- **An ending made of its own data.** There is no closing card. After the impact the view
  zooms out until the whole track fits the screen, so the last frame is this track's waveform,
  notes and locks. The one marker that stays bright is picked from the measurements: the
  loudest moment (`loudest -9.9 dBFS @ 4.500 s`). Another score ends on another picture.
- **Measured, not copied.** The agent's markers on the ruler (`onset 4.000 s`,
  `tempo 120.0 BPM`, `bass 54.8 Hz`, `tokens 54`, `-14.0 LUFS`) come from `music/analyze.py`.
  The analysis listens to the rendered stems, not to the score.

<img src="docs/media/flow.jpg" width="100%" alt="One frame from each of the eight bars">

## The music

16 s, 8 bars at 120 BPM in A minor. Dark, dithered and a little agentic.

| Bars | Time | What plays |
|---|---|---|
| 1–2 | 0–4 s | A pad opening from a closed filter, sparse hats |
| 3–4 | 4–8 s | Four-on-the-floor kick with sidechain pump, off-beat pulse bass |
| 5–6 | 8–12 s | Clap on 2 and 4, 16th hats, a 6-bit arp with ping-pong delay, the pad gated in 16ths, chords Dm–E |
| 7 | 12–14 s | Snare roll into 32nds, riser, the densest data layer, beat 4 left empty |
| 8 | 14–16 s | Impact with sub drop, held Am, four-bleep signature, fade |

Everything is synthesized in [`music/synth.py`](music/synth.py) with numpy and scipy. That
covers band-limited saws (polyBLEP), FM bleeps, noise claps, a stereo reverb from a synthetic
impulse response, bit crushing with TPDF dither and buffer-repeat stutters. No samples, no
third-party audio.

<img src="docs/media/music.png" width="100%" alt="Spectrogram of the track">

What `music/analyze.py` measured on the rendered track and its stems:

| Measure | Value | How |
|---|---|---|
| Tempo | 120.0 BPM | median gap between kick onsets on the kick stem |
| First kick | 4.000 s | RMS envelope rise on the kick stem |
| Kick | 55.7 Hz | FFT peak of the first kick's body |
| Bass | 54.8 Hz (A1) | FFT peak of the first bass note on the bass stem |
| Bleeps | 32, each with its Hz | strongest FFT component on the data stem |
| Tokens | 54 | transients on the token stem |
| Loudness | -14.0 LUFS, true peak -3.2 dBTP | ffmpeg `ebur128` |

## How it works

```text
music/score.py ─► music/synth.py ─► out/pass/music.wav + out/events.json + out/stems/*.wav
                                 └► music/analyze.py ─► out/measured.json
                                 └► music/gen_hud.py ─► hud/src/generated.rs  (constants, compile-time sync)

hud ──► flat   pass 1: the DAW timeline in SVG, 3840×2160 ──► out/pass/flat.mp4 ──┐ iChannel0
 │                                                                                 ▼
 └────► lens   pass 2: one SkSL shader + the camera tracker ──► out/unmute.mp4 (+ music.wav)
```

- **`hud`** is the single source of truth, with no fframes dependency. It holds the timeline
  layout (lanes, `time_x`, the playhead at x = 960), the events the tracker can lock onto, the
  camera's keyframes (Catmull-Rom over 12 keys), the palette blend and `project()`, the CPU
  copy of the shader's camera.
- **`flat`** draws the DAW the way a DAW would: ruler with bars and beats, markers, lanes,
  waveform, the FFT strip and the tracker boxes. White on black, with pure red marking a lock.
- **`lens`** films it through the same SkSL shader as ff-tracking. A kick drives a zoom punch
  and the bloom. Claps and stutters tear the rows. Then it draws a sharp camera-space tracker
  whose labels carry the measured values.

<img src="docs/media/stages.jpg" width="100%" alt="One frame through the six steps of the lens shader">

## Quick start

### Requirements

- Rust (2024 edition), ffmpeg and ffprobe on `PATH`.
- Python 3 with `numpy` and `scipy`, or [uv](https://docs.astral.sh/uv/)
  (`render.sh` uses `uv run --with numpy --with scipy` if the packages are missing).
- macOS: Apple silicon, Skia on Metal (the existing path).
- Linux: a Vulkan loader and GPU driver, plus a C/C++ toolchain, pkg-config,
  libclang, fontconfig and OpenGL development libraries for Skia. On Debian/Ubuntu:
  `sudo apt install build-essential pkg-config libclang-dev libfontconfig1-dev libgl1-mesa-dev libvulkan1 ffmpeg`.
  For NVIDIA, install your distribution's proprietary Vulkan-capable driver.
  Rust Skia normally downloads a prebuilt; a source build also needs Python and Ninja.
- README images additionally need Pillow and `img2webp`.

Linux uses Vulkan, not Metal. The default `FF_BACKEND=auto` tries the platform GPU
and reports a CPU fallback if context creation fails. To choose explicitly:

```bash
FF_BACKEND=gpu tools/render.sh  # Vulkan on Linux/Windows, Metal on macOS; no silent fallback
FF_BACKEND=cpu tools/render.sh  # no GPU context is created (also works with GPUs hidden)
```

The CPU flat pass uses fframes' tiny-skia SVG renderer. The CPU lens pass uses
fframes' `SkiaCpuCtx` raster compatibility backend, **not** tiny-skia, because
tiny-skia cannot run SkSL. The original lens shader still runs: perspective,
depth of field, palette, aberration, bloom, LED grid, tear and grain are retained.
This is slower, and SVG antialiasing/filter kernels can differ from the GPU pass.
Backend selection is printed to stderr; invalid values fail rather than choosing
a different backend. `FF_BACKEND` also works when invoking either binary directly.
`preview` still needs a GPU/window; the fallback is for offline rendering.

### Render

```bash
git clone https://github.com/mrsarac/ff-unmute && cd ff-unmute
tools/render.sh            # music → measurements → hud constants → flat → lens → out/unmute.mp4
```

It takes about 1 min 45 s on an M3 Pro, plus the first build.

```bash
python3 -I music/synth.py && python3 -I tools/audio_check.py   # change the music, read its band balance
cargo test -p hud                                              # every kick locks, focus stays in frame
target/release/lens frame 270 -o frames                        # one full-size frame
LENS_STAGE=1 target/release/lens frame 270                     # stop the shader after a step (0-3)
python3 -I tools/readme_media.py                               # rebuild the images in this README
```

## Make it yours

- **Change the music** in [`music/score.py`](music/score.py): tempo, progression, voicings,
  drum patterns. Then run `tools/render.sh`. The picture follows, because the timeline, locks,
  labels and camera all read the regenerated `hud/src/generated.rs`.
- **Change the flight** in `KEYS` in [`hud/src/lib.rs`](hud/src/lib.rs). Each key is time,
  look height, zoom, tilt, roll, offset and blur. `PALETTES` sets the color story.
- **Change the look** in [`lens/shaders/lens.sksl`](lens/shaders/lens.sksl), or start from
  [ff-tracking](https://github.com/mrsarac/ff-tracking) if you want the terminal instead of the DAW.
- **Or change the prompt.** [`docs/PROMPT.md`](docs/PROMPT.md) is the prompt that makes this
  video with Claude Code. Edit the brief and get your own version.

## Changelog

- **v1.1.0:** the ending is drawn from the data (zoom out to the whole track, last marker
  picked from the measurements) instead of an "✓ unmuted" pill. The music is bit-identical.
  The video on X is v1.0.0.
- **v1.0.0:** first release.

## Notes from the build

- An agent can't hear. Measure the music before the picture: band balance per section,
  loudness, harsh 2–5 kHz energy. A person listens before the picture work starts. The first
  draft here had almost all its energy under 120 Hz, which tells you nothing until you
  measure it.
- Measure each part on its own stem. On the full mix, bass notes read as kicks and the pad
  masks the bleeps.
- Don't let a stem change the random sequence. A second `token_click()` call shifted every
  later random number, and the approved music changed. The fix renders each click once and
  places it twice. The final track is bit-identical to the approved draft.
- fframes hands its FFT 1024 contiguous samples from each frame's start (bin k = k × 46.9 Hz at
  48 kHz), so log bands are grouped from those bins.

## Credits

- Built on [fframes](https://github.com/dmtrKovalenko/fframes) by Dmitriy Kovalenko, rendering
  with [Skia](https://skia.org), encoding with [FFmpeg](https://ffmpeg.org). The visual DNA comes
  from ff-tracking, inspired by [@mnowakdesign](https://x.com/mnowakdesign/status/2108253918086176899).
- Font: [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) (SIL OFL 1.1, see
  [`licenses/JetBrainsMono-OFL.txt`](licenses/JetBrainsMono-OFL.txt)).
- Made with Claude Code. [`docs/PROMPT.md`](docs/PROMPT.md) is the prompt, and the design is in
  [`docs/superpowers/specs/`](docs/superpowers/specs/2026-10-09-unmute-design.md).

## License

[MIT](LICENSE) © 2026 Mustafa Saraç. The font keeps its own license.

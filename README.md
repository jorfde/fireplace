<p align="center">
  <img src="assets/banner.png" alt="Fireplace — a tiny cozy focus timer for macOS" width="600" />
</p>

<p align="center">
  <strong>A tiny cozy focus timer that lives in your macOS Dock.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-black?style=flat-square" />
  <img src="https://img.shields.io/badge/swift-5.10-F05138?style=flat-square&logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/UI-pixel%20art-orange?style=flat-square" />
  <img src="https://img.shields.io/badge/dependencies-zero-green?style=flat-square" />
</p>

---

Name what you're working on. Pick how long. A pixel-art campfire lights up in your Dock and burns while you work — twinkling stars, crackling sound, the whole scene. When the fire dies down, it asks one question: *"How'd it go?"*

No dashboards. No analytics. No guilt. Just a campfire.

---

## Screenshots

<p align="center">
  <img src="assets/setup.png" alt="Setup view" width="260" />
  &nbsp;&nbsp;
  <img src="assets/focusing.png" alt="Focusing view" width="260" />
  &nbsp;&nbsp;
  <img src="assets/completion.png" alt="Completion view" width="260" />
</p>

<p align="center">
  <img src="assets/dock-icon.png" alt="Dock icon animation" width="120" />
  &nbsp;&nbsp;&nbsp;
  <img src="assets/sound-mixer.png" alt="Menu bar sound mixer" width="260" />
  &nbsp;&nbsp;&nbsp;
  <img src="assets/history.png" alt="Session history" width="260" />
</p>

> **Note:** Add your own screenshots to the `assets/` folder. The filenames above are placeholders.

---

## Why

Most timers optimize for productivity. Fireplace optimizes for *feel*.

Focus is treated as a state, not a metric. Time passes through a living object — not a countdown that demands your attention. And when your session ends, you're invited to reflect, not report.

It's closer to a desk object than a productivity tool.

---

## Quick Start

```bash
git clone https://github.com/your-username/fireplace.git
cd fireplace
swift run
```

Or open in Xcode:

```bash
open Package.swift
```

> Requires **macOS 14 (Sonoma)** or later and **Xcode 15+**.

---

## How It Works

### 1. Set up

Name your task, pick a duration (`15m` / `25m` / `45m` / `60m`), and hit **Light the fire**. Everything is pixel art — buttons, text, the whole UI.

### 2. Focus

A pixel-art campfire burns in your Dock. Stars twinkle. A progress bar counts down. Ambient sound plays if you want it. The fire visually shrinks in the last 20% — you *feel* time running out.

### 3. Reflect

The fire dies down to embers. The Dock bounces once. You're asked: **"How'd it go?"**

Tap **Finished** or **Need more time** to relight with the same task. Optionally jot one sentence about how it went.

---

## Features

### 🔥 The Campfire

- **Animated Dock icon** — 32×32 pixel grid, night sky with twinkling stars, flickering flames, floating sparks. 4 FPS for that authentic retro feel.
- **Animated transitions** — fire grows from a spark (1s), dies down with rising smoke (1.5s). No instant state snaps.
- **Visual time passage** — stars drift across the sky. Fire shrinks in the last 20%. Time is *felt*, not just read.
- **Dynamic sky** — palette shifts with the real time of day: dawn, daylight, golden hour, night.

### 🎮 Pixel Art UI

- **Full pixel art interface** — custom 5×7 bitmap font, pixel buttons, pixel borders, pixel progress bar. No system controls except text input.
- **Dark pixel palette** — charcoal background, warm orange accent, soft warm text. Inspired by Celeste.
- **Horizontal progress bar** — retro fill bar with gradient, replacing the standard circular ring.

### 🔊 Ambient Sound Mixer

- **Four procedural layers** — crackling fire, rain, wind, brown noise. All synthesized at runtime with proper DSP.
- **Menu bar popover** — click the 🔥 icon anytime to mix your soundscape. Works independently of focus sessions.
- **Proper signal processing** — Voss-McCartney pink noise, IIR band-pass filters, slow amplitude modulation, stereo decorrelation, Poisson-distributed crackle events.

### 📖 Session History

- **30-day calendar** — day numbers aligned to real weekdays. Orange intensity shows focus density. Today highlighted.
- **Session log** — grouped by day with task name, duration, ✓/✗, journal entry.
- **Weekly summary** — session count and total minutes on the completion screen.

### 🍎 macOS Integration

- **Dock + menu bar** — two entry points. Dock icon for the ritual, menu bar 🔥 for the sound mixer.
- **Right-click Dock menu** — current task, time remaining, extinguish early, quick-start presets, sound toggle.
- **Keyboard-first** — `Tab` → arrow keys → `Enter`. Full setup without touching the mouse.
- **Quit guard** — ⌘Q during a session shows a confirmation. Partial sessions saved to history.
- **Outside click dismisses** — panel hides when you click elsewhere. Standard macOS behavior.

### ✨ Details

- **"Need more time"** — on completion, pick a new duration and relight the same task. One-tap continuation.
- **Streak tracking** — consecutive-day notches on the campfire stones. Persisted in UserDefaults.
- **Micro-journaling** — optional "Any thoughts?" on completion. Entries visible in the session log.
- **Marshmallow 🍡** — type "marshmallow" as your task name. A pixel marshmallow appears by the fire, toasting.

---

## Architecture

```
Fireplace/
├── FireplaceApp.swift              App lifecycle, Dock menu, state wiring
├── AppState.swift                  @Observable state machine, streak tracker
├── SessionHistory.swift            Session persistence (UserDefaults/JSON)
│
├── Panel/
│   ├── FloatingPanel.swift         NSPanel (solid dark bg, non-activating)
│   └── PanelController.swift       Panel positioning + all view states
│
├── Views/
│   ├── SetupView.swift             Task name, pixel chips, pixel button
│   ├── SettingsView.swift          Ambient sound layer config (⌘,)
│   ├── HistoryView.swift           Calendar + grouped session log
│   ├── PixelText.swift             5×7 bitmap font renderer
│   ├── PixelUI.swift               Pixel buttons, text fields, progress bar, theme
│   └── FireplaceCanvasView.swift   16-row pixel-art canvas (panel)
│
├── DockTile/
│   ├── DockIconCanvasView.swift    32×32 pixel-art canvas (Dock icon)
│   ├── StaticCampfireIcon.swift    Static frame for About/⌘Tab icon
│   └── DockTileRenderer.swift      Frame rendering → dockTile.contentView
│
├── Timer/
│   └── FocusTimer.swift            Countdown + progress tracking
│
├── Sound/
│   └── CracklingSound.swift        Multi-layer DSP ambient engine
│
├── MenuBar/
│   └── MenuBarCompanion.swift      Status bar + ambient sound popover
│
└── Package.swift
```

### State Machine

```
         ┌──────────────────────────────────────────────────────┐
         ▼                                                      │
       idle  →  lightingUp  →  focusing  →  dyingDown  →  completed
                 (1s grow)     (burns)      (1.5s fade)    (embers)
```

| State | What happens |
|---|---|
| **Idle** | Cold campfire, drifting smoke. Setup UI shown. |
| **Lighting up** | Flames grow from a spark over 1 second. |
| **Focusing** | Full fire with sparks. Progress bar counts down. Ambient sound plays. |
| **Dying down** | Fire shrinks, smoke rises over 1.5 seconds. Sound fades out. |
| **Completed** | Embers pulse. Dock bounces. "How'd it go?" appears. |

### Sound Engine

Each ambient layer is a structured stochastic process:

| Layer | Noise | Band-pass | Modulation | Events |
|---|---|---|---|---|
| 🔥 Fire | Pink + brown | 300–3kHz | 0.08Hz breathing | Poisson crackles |
| 🌧 Rain | White | 1k–8kHz | 0.05Hz density | Tonal droplet plinks |
| 🌬 Wind | Pink (stereo) | 100–1kHz | Dual LFO swells | — |
| 🔊 Noise | Pink (Voss-McCartney) | 200–6kHz | — | — |

All audio: stereo WAV, 44.1kHz, 10s loops with smoothstep crossfade, soft tanh limiter.

### Tech Stack

| | |
|---|---|
| Language | Swift 5.10 |
| UI | SwiftUI + AppKit (`NSPanel`, `NSDockTile`, `NSStatusItem`, `NSPopover`) |
| State | `@Observable` + `withObservationTracking` |
| Rendering | SwiftUI `Canvas` + `ImageRenderer` |
| Audio | `AVAudioPlayer` with runtime-synthesized WAV |
| Font | Custom 5×7 bitmap (A-Z, 0-9, punctuation) |
| Target | macOS 14+ (Sonoma) |
| Dependencies | None |
| Size | ~2,600 lines of Swift, 16 source files |

---

## Contributing

Fireplace is intentionally small. If you'd like to contribute:

1. **Bug fixes** — always welcome
2. **New ambient layers** — add a case to `AmbientLayer` and implement the DSP generator
3. **Pixel art** — edit `FireplaceCanvasView.swift` (panel) or `DockIconCanvasView.swift` (Dock). Every pixel is a function call
4. **Bitmap font** — add glyphs to `PixelFont.glyphs` in `PixelText.swift`

Please keep the spirit: simple, cozy, no feature creep.

---

## License

[MIT](LICENSE)

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-black?style=flat-square" />
  <img src="https://img.shields.io/badge/swift-5.10-F05138?style=flat-square&logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/dependencies-zero-green?style=flat-square" />
  <img src="https://img.shields.io/badge/lines-~2k-blue?style=flat-square" />
</p>

# 🔥 Fireplace

**A tiny cozy focus timer that lives in your macOS Dock.**

You tell it what you're working on. You pick how long. A pixel-art campfire lights up in your Dock and burns while you work — twinkling stars, crackling sound, the whole scene. When the fire dies down, Fireplace asks one question: *"Did you finish?"*

No dashboards. No analytics. No guilt. Just a campfire.

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

Name your task, pick a duration (`15m` / `25m` / `45m` / `60m`), and hit **Light the fire**.

### 2. Focus

The panel hides. A pixel-art campfire burns in your Dock. Stars twinkle. A progress ring quietly counts down. Ambient sound plays if you want it.

### 3. Reflect

The fire dies down to embers. The Dock bounces once. You're asked:

> **Did you finish?**

Optionally jot one sentence about how it went. That's it. Start another, or walk away.

---

## Features

#### The Campfire

- **Animated Dock icon** — 32×32 pixel grid rendered at 1024×1024. Night sky, twinkling stars, flickering flames, floating sparks. 4 FPS for that authentic pixel-art feel.
- **Animated transitions** — Fire grows from a spark (1s). Dies down with rising smoke (1.5s). No instant state changes.
- **Visual time passage** — Stars drift across the sky as your session progresses. The fire shrinks in the last 20%. Time is *felt*, not just read.
- **Dynamic sky** — The panel campfire sky shifts with the real time of day: dawn, daylight, golden hour, night.

#### The Experience

- **Progress ring** — Circular indicator with `mm:ss` countdown. Present but not pushy.
- **Micro-journaling** — Optional one-line "How did it go?" prompt on completion. No pressure.
- **Streak tracking** — Consecutive-day notch marks appear on the campfire stones. Quiet visual memory.
- **Session history** — Past sessions saved locally (task, duration, finished, journal). Weekly summary on the completion screen.

#### Ambient Sound

- **Four procedural layers** — Crackling fire, rain, wind, white noise. All generated at runtime — zero audio files in the repo.
- **Mix and match** — Each layer independently toggleable with its own volume slider in Settings (`⌘,`).
- **Gentle fades** — Sound fades in when the fire lights and fades out when it dies.

#### macOS Integration

- **Dock + menu bar** — Two entry points. Dock icon for the ritual, menu bar 🔥 for quick access.
- **Right-click Dock menu** — Current task, time remaining, extinguish early, quick-start presets, sound toggle.
- **Keyboard-first** — `Tab` → arrow keys → `Enter`. Full setup without touching the mouse. `⌘Enter` to start from anywhere.
- **Dock bounce** — Single gentle notification when your session completes.
- **Settings** — `⌘,` opens the ambient sound mixer.

#### Easter Egg

Type **"marshmallow"** as your task name. 🍡

---

## Architecture

```
Fireplace/
├── FireplaceApp.swift              App lifecycle, Dock menu, state wiring
├── AppState.swift                  @Observable state machine, streak tracker
├── SessionHistory.swift            Session persistence (UserDefaults/JSON)
│
├── Panel/
│   ├── FloatingPanel.swift         NSPanel (HUD, floating, non-activating)
│   └── PanelController.swift       Panel positioning + all view states
│
├── Views/
│   ├── SetupView.swift             Task name, duration chips, keyboard nav
│   ├── SettingsView.swift          Ambient sound mixer (⌘,)
│   └── FireplaceCanvasView.swift   16×16 pixel-art canvas (panel)
│
├── DockTile/
│   ├── DockIconCanvasView.swift    32×32 pixel-art canvas (Dock icon)
│   └── DockTileRenderer.swift      Frame rendering → applicationIconImage
│
├── Timer/
│   └── FocusTimer.swift            Countdown + progress tracking
│
├── Sound/
│   └── CracklingSound.swift        Multi-layer procedural ambient engine
│
├── MenuBar/
│   └── MenuBarCompanion.swift      Status bar icon + panel toggle
│
└── Package.swift
```

### State Machine

```
         ┌─────────────────────────────────────────────────────┐
         ▼                                                     │
       idle  →  lightingUp  →  focusing  →  dyingDown  →  completed
                 (1s grow)     (burns)      (1.5s fade)    (embers)
```

| State | What happens |
|---|---|
| **Idle** | Cold campfire, drifting smoke wisp. Setup UI shown. |
| **Lighting up** | Flames grow from a spark over 1 second. |
| **Focusing** | Full fire with sparks. Progress ring counts down. Ambient sound plays. |
| **Dying down** | Fire shrinks, smoke rises over 1.5 seconds. Sound fades out. |
| **Completed** | Embers pulse. Dock bounces. Reflection prompt appears. |

### Dock Icon Spec

Follows [Apple's Human Interface Guidelines for app icons](https://developer.apple.com/design/human-interface-guidelines/app-icons):

| Property | Value |
|---|---|
| Canvas | 1024 × 1024 px, transparent background |
| Plate | 880 × 880 px rounded rectangle, 190px continuous corner radius, centered |
| Artwork | 32 × 32 pixel grid, nearest-neighbor scaled to fill plate |
| Animation | Identical canvas/plate/alignment every frame — only flame pixels change |

### Design Decisions

| Decision | Rationale |
|---|---|
| NSPanel (HUD) | Floating, non-activating — feels like a desk object, not a window |
| Code-generated pixel art | Zero external assets. Two canvases: 16×16 panel, 32×32 Dock |
| Procedural audio | Four ambient layers generated as WAV at runtime. No bundled files |
| 4 FPS animation | Deliberately low for authentic retro pixel-art aesthetic |
| Preset durations | Fewer choices = more ritual. No custom input needed |
| Minimal persistence | Streak + history in UserDefaults. No database, no sync |

### Tech Stack

| | |
|---|---|
| Language | Swift 5.10 |
| UI | SwiftUI + AppKit (`NSPanel`, `NSDockTile`, `NSStatusItem`) |
| State | `@Observable` + `withObservationTracking` |
| Rendering | SwiftUI `Canvas` → `ImageRenderer` → `NSImage` |
| Audio | `AVAudioPlayer` with runtime-generated WAV data |
| Target | macOS 14+ (Sonoma) |
| Dependencies | None |
| Size | ~2,000 lines of Swift, 13 source files |

---

## Contributing

Fireplace is intentionally small. If you'd like to contribute:

1. **Bug fixes** — always welcome
2. **New ambient layers** — add a case to `AmbientLayer` and implement the generator in `CracklingSound.swift`
3. **Pixel art** — edit `FireplaceCanvasView.swift` (panel) or `DockIconCanvasView.swift` (Dock). Every pixel is a function call

Please keep the spirit: simple, cozy, no feature creep.

---

## License

[MIT](LICENSE)

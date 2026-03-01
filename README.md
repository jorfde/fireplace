# 🔥 Fireplace

A tiny cozy focus timer for macOS.

Fireplace turns focused work into a small ritual. You tell it what you're working on, set a duration, and a pixel-art campfire lights up in your Dock while you work. No dashboards. No guilt.

When the fire dies down, Fireplace asks a simple question: **"Did you finish?"**

---

## Philosophy

- **Focus is a state, not a number.** A campfire burns in your Dock — that's your only signal.
- **Time passes through a living object.** Pixel-art flames replace the anxiety of a ticking clock.
- **Reflection over enforcement.** When your session ends, you're asked what happened — not judged for it.

Fireplace is closer to a desk object or a campfire than a productivity tool.

---

## What it does

1. **Lives in your Dock** — animated pixel-art campfire with night sky and twinkling stars
2. **Also in the menu bar** — 🔥 icon toggles the same panel as the Dock icon
3. **Setup is two steps:** name your task, pick a duration (15 / 25 / 45 / 60 min)
4. **During focus:** circular progress ring with countdown, task name displayed, soft crackling sound
5. **When time's up:** fire animates down to embers, Dock bounces gently, you're asked "Did you finish?"
6. **Optional micro-journal:** "How did it go?" — one sentence, no pressure
7. **Streak tracking:** consecutive-day notch marks appear on the campfire stones

---

## Screenshots

```
┌──────────────────────────┐    ┌──────────────────────────┐    ┌──────────────────────────┐
│                          │    │                          │    │                          │
│   🪵 (cold campfire)     │    │   🔥 (burning campfire)  │    │   🟠 (glowing embers)    │
│                          │    │                          │    │                          │
│  What are you working on?│    │  Your current task is    │    │    The fire has gone out  │
│  ┌──────────────────────┐│    │  "Fix login bug"         │    │    "Fix login bug"       │
│  │ Fix login bug        ││    │                          │    │                          │
│  └──────────────────────┘│    │      ╭──────╮            │    │  Did you finish?         │
│                          │    │      │12:34 │  ← ring    │    │                          │
│  [15] [25] [45] [60]    │    │      ╰──────╯            │    │  [ Yes ✓ ]  [ Not yet ]  │
│                          │    │                          │    │  How did it go? _____    │
│  [ Light the fire 🔥 ]   │    │  [Extinguish early]      │    │      Start another →     │
│                          │    │        Hide              │    │                          │
└──────────────────────────┘    └──────────────────────────┘    └──────────────────────────┘
       Setup view                    Focusing view                   Completion view
```

---

## Features

| Feature | Details |
|---|---|
| **Animated Dock icon** | 32×32 pixel grid on 880×880 plate (1024×1024 canvas), 4 FPS. Night sky with twinkling stars, campfire with logs, stones, sparks. |
| **Animated transitions** | Fire grows from a spark (1s), dies down with smoke (1.5s). No instant state snaps. |
| **Crackling sound** | Procedural audio generated at runtime. Fades in/out with the fire. Toggleable in Settings (⌘,). |
| **Progress ring** | Circular orange progress indicator with `mm:ss` countdown during focus. |
| **Menu bar companion** | 🔥 always visible. Click to toggle panel. Tooltip shows task + time remaining. |
| **Right-click Dock menu** | Current task, time left, extinguish early, quick-start presets, sound toggle. |
| **Keyboard-first** | Tab → arrow keys → Enter. Full flow without touching the mouse. |
| **Dynamic sky** | Panel campfire sky shifts by time of day: dawn, day, golden hour, night. |
| **Streak counter** | Consecutive-day notches on stones. Persisted in UserDefaults. |
| **Micro-journaling** | Optional "How did it go?" on completion. |
| **Dock bounce** | Gentle `informationalRequest` when session completes. |
| **Marshmallow 🍡** | Type "marshmallow" as your task for a toasting marshmallow Easter egg. |

---

## Architecture

```
Fireplace/
├── FireplaceApp.swift              App entry + AppDelegate + Dock menu
├── AppState.swift                  @Observable state machine + streak tracker
├── Panel/
│   ├── FloatingPanel.swift         NSPanel subclass (HUD, floating)
│   └── PanelController.swift       Panel positioning + all view states
├── Views/
│   ├── SetupView.swift             Task name + duration chips + keyboard nav
│   ├── CompletionView.swift        Reflection prompt + micro-journal
│   ├── SettingsView.swift          Sound toggle (⌘,)
│   └── FireplaceCanvasView.swift   16×16 pixel-art for the panel UI
├── DockTile/
│   ├── DockIconCanvasView.swift    32×32 pixel-art for the Dock icon
│   └── DockTileRenderer.swift      Renders frames → applicationIconImage
├── Timer/
│   └── FocusTimer.swift            Countdown with progress tracking
├── Sound/
│   └── CracklingSound.swift        Procedural crackling audio
├── MenuBar/
│   └── MenuBarCompanion.swift      Status bar icon + click handler
└── Package.swift
```

### State machine

```
idle  →  lightingUp  →  focusing  →  dyingDown  →  completed  →  idle
         (1s grow)      (fire burns)  (1.5s fade)   (embers glow)
```

- **Idle** — Cold campfire, drifting smoke. Setup UI.
- **Lighting up** — Flames grow from a spark over 1 second.
- **Focusing** — Full fire burns at 4 FPS. Progress ring counts down. Sound plays.
- **Dying down** — Fire shrinks, smoke rises over 1.5 seconds.
- **Completed** — Embers pulse. Dock bounces. Reflection prompt appears.

### Dock icon spec

- **Canvas:** 1024×1024 px, transparent background
- **Plate:** 880×880 rounded rectangle, 190px corner radius, centered
- **Artwork:** 32×32 pixel grid scaled to fill the plate
- **Animation:** Same canvas/plate/alignment every frame — only flame pixels move

### Key decisions

| Choice | Rationale |
|---|---|
| **Dock + menu bar** | Two entry points — Dock icon for the ritual, menu bar for quick access |
| **NSPanel (HUD)** | Floating, non-activating — feels like a desk object, not a window |
| **Code-generated pixel art** | No external assets, two canvases (16×16 panel, 32×32 Dock) |
| **Procedural sound** | WAV generated at runtime — zero asset files in the repo |
| **4 FPS animation** | Deliberately low frame rate for authentic pixel-art feel |
| **Preset durations** | Fewer decisions = more ritual |
| **Minimal persistence** | Only streak days in UserDefaults. Each launch is a fresh start. |

### Tech

- Swift 5.10, SwiftUI with AppKit integration
- macOS 14+ (Sonoma)
- `@Observable` + `withObservationTracking` for reactive state
- `ImageRenderer` to snapshot SwiftUI Canvas into `NSImage`
- `AVAudioPlayer` with procedurally generated WAV data
- Zero external dependencies — ~1,800 lines of Swift

---

## Run

```bash
# Build and run
swift run

# Or open in Xcode
open Package.swift
```

Requires macOS 14 (Sonoma) or later and Xcode 15+.

---

## License

MIT

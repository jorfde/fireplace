# 🔥 Fireplace

A tiny cozy focus timer for macOS.

Fireplace turns focused work into a small ritual. You tell it what you're working on, set a duration, and a pixel-art fireplace lights up in your Dock while you work. No ticking clocks. No dashboards. No guilt.

When the fire dies down, Fireplace asks a simple question: **"Did you finish?"**

---

## Philosophy

- **Focus is a state, not a number.** There's no progress bar or countdown. The fire burns; that's all you need to know.
- **Time passes through a living object.** A pixel-art fireplace in your Dock replaces the anxiety of a ticking clock.
- **Reflection over enforcement.** When your session ends, you're asked what happened — not judged for it.

Fireplace is closer to a desk object or a campfire than a productivity tool.

---

## What it does

1. **Lives in your Dock** — no menu bar icon, no floating window clutter
2. **Shows a pixel-art fireplace** that reflects your current state
3. **Setup is two steps:** name your task, pick a duration (15 / 25 / 45 / 60 min)
4. **Runs silently** — the fire burns in the Dock while you work
5. **When time's up** — the fire dims to embers and you're asked what to do next

That's it.

---

## Screenshots

```
┌──────────────────────────┐    ┌──────────────────────────┐
│                          │    │                          │
│   🪵 (dark hearth)       │    │   🔥 (glowing embers)    │
│                          │    │                          │
│  What are you working on?│    │    The fire has gone out  │
│  ┌──────────────────────┐│    │    "Fix login bug"       │
│  │ Fix login bug        ││    │                          │
│  └──────────────────────┘│    │  Did you finish?         │
│                          │    │                          │
│  [15] [25] [45] [60]    │    │  [ Yes ✓ ]  [ Not yet ]  │
│                          │    │                          │
│  [ Light the fire 🔥 ]   │    │      Start another →     │
│                          │    │                          │
└──────────────────────────┘    └──────────────────────────┘
       Setup view                    Completion view
```

---

## Architecture

```
Fireplace/
├── FireplaceApp.swift              App entry + AppDelegate
├── AppState.swift                  @Observable state machine
├── Panel/
│   ├── FloatingPanel.swift         NSPanel subclass (HUD, floating)
│   └── PanelController.swift       Show/hide/position + view routing
├── Views/
│   ├── SetupView.swift             Task name + duration chips + CTA
│   ├── CompletionView.swift        "Did you finish?" prompt
│   └── FireplaceCanvasView.swift   16×16 pixel-art via SwiftUI Canvas
├── Timer/
│   └── FocusTimer.swift            Background countdown
├── DockTile/
│   └── DockTileRenderer.swift      Renders fireplace into Dock icon
└── Package.swift
```

### State machine

```
idle  ──▶  focusing  ──▶  completed  ──▶  idle
         (fire burns)    (embers glow)
```

- **Idle** — Dark hearth, ash pixels. Panel shows setup UI.
- **Focusing** — Fire burns at 4 FPS in the Dock. Panel hides.
- **Completed** — Embers pulse. Panel reappears with the reflection prompt.

### Key decisions

| Choice | Rationale |
|---|---|
| **Dock-only** | The Dock icon *is* the app — it's always visible without stealing focus |
| **NSPanel (HUD)** | Floating, non-activating — feels like a desk object, not a window |
| **Code-generated pixel art** | No external assets, resolution-independent, ~130 lines of Canvas drawing |
| **4 FPS animation** | Deliberately low frame rate for authentic pixel-art feel |
| **Preset durations** | Fewer decisions = more ritual. No custom input needed. |
| **No persistence** | Each launch is a clean slate. Focus is ephemeral. |

### Tech

- Swift 5.10, SwiftUI with AppKit integration
- macOS 14+ (Sonoma)
- `@Observable` + `withObservationTracking` for reactive state
- `ImageRenderer` to snapshot SwiftUI Canvas into `NSDockTile`
- Zero dependencies

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

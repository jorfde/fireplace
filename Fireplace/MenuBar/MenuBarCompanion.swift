import AppKit
import SwiftUI
import Combine

@MainActor
final class MenuBarCompanion {
    private var statusItem: NSStatusItem?
    private var updateTimer: Timer?

    func show(taskName: String, timer: FocusTimer) {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        }
        statusItem?.button?.image = NSImage(systemSymbolName: "flame.fill", accessibilityDescription: "Fireplace")
        statusItem?.button?.image?.isTemplate = true
        updateTooltip(taskName: taskName, timer: timer)

        updateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTooltip(taskName: taskName, timer: timer)
            }
        }
    }

    func hide() {
        updateTimer?.invalidate()
        updateTimer = nil
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func updateTooltip(taskName: String, timer: FocusTimer) {
        let mins = Int(timer.remainingSeconds) / 60
        let secs = Int(timer.remainingSeconds) % 60
        statusItem?.button?.toolTip = "\(taskName) — \(mins):\(String(format: "%02d", secs)) left"
    }
}

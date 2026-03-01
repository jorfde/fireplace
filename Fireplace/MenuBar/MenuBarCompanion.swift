import AppKit
import SwiftUI
import Combine

@MainActor
final class MenuBarCompanion {
    private var statusItem: NSStatusItem?
    private var updateTimer: Timer?
    var onClicked: (() -> Void)?

    func show(taskName: String, timer: FocusTimer) {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem?.button?.target = self
            statusItem?.button?.action = #selector(statusItemClicked)
            statusItem?.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem?.button?.image = NSImage(systemSymbolName: "flame.fill", accessibilityDescription: "Fireplace")
        statusItem?.button?.image?.isTemplate = true
        updateTooltip(taskName: taskName, timer: timer)

        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTooltip(taskName: taskName, timer: timer)
            }
        }
    }

    func showIdle() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem?.button?.target = self
            statusItem?.button?.action = #selector(statusItemClicked)
            statusItem?.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updateTimer?.invalidate()
        updateTimer = nil
        statusItem?.button?.image = NSImage(systemSymbolName: "flame", accessibilityDescription: "Fireplace")
        statusItem?.button?.image?.isTemplate = true
        statusItem?.button?.toolTip = "Fireplace"
    }

    func hide() {
        updateTimer?.invalidate()
        updateTimer = nil
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    @objc private func statusItemClicked() {
        onClicked?()
    }

    private func updateTooltip(taskName: String, timer: FocusTimer) {
        let mins = Int(timer.remainingSeconds) / 60
        let secs = Int(timer.remainingSeconds) % 60
        statusItem?.button?.toolTip = "\(taskName) — \(mins):\(String(format: "%02d", secs)) left"
    }
}

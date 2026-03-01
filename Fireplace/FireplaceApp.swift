import SwiftUI

@main
struct FireplaceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(appState: appDelegate.appState, soundEngine: appDelegate.soundEngine)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    var panelController: PanelController?
    let focusTimer = FocusTimer()
    let dockTileRenderer = DockTileRenderer()
    let soundEngine = AmbientSoundEngine()
    let menuBarCompanion = MenuBarCompanion()
    private var observation: Any?
    private var transitionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set the app icon before becoming visible so About/⌘Tab show the campfire
        dockTileRenderer.updateState(.idle, marshmallow: false, streak: appState.streakDays)
        NSApp.setActivationPolicy(.regular)
        cleanUpMenus()
        setupDockMenu()

        focusTimer.onComplete = { [weak self] in
            self?.appState.beginDyingDown()
        }

        panelController = PanelController(appState: appState, focusTimer: focusTimer)
        panelController?.showPanel()

        menuBarCompanion.onClicked = { [weak self] in
            self?.panelController?.togglePanel()
        }
        menuBarCompanion.showIdle()

        reobserve()
    }

    private func reobserve() {
        observation = withObservationTracking {
            _ = self.appState.phase
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.handlePhaseChange()
                self?.reobserve()
            }
        }
    }

    private func handlePhaseChange() {
        switch appState.phase {
        case .idle:
            focusTimer.stop()
            soundEngine.stop()
            menuBarCompanion.showIdle()
            transitionTimer?.invalidate()
            dockTileRenderer.updateState(.idle, marshmallow: false, streak: appState.streakDays)

        case .lightingUp:
            dockTileRenderer.updateState(.lightingUp(progress: 0), marshmallow: appState.isMarshmallow, streak: appState.streakDays)
            animateTransition(duration: 1.0, from: 0, to: 1) { [weak self] progress in
                self?.dockTileRenderer.updateState(.lightingUp(progress: progress), marshmallow: self?.appState.isMarshmallow ?? false, streak: self?.appState.streakDays ?? 0)
            } completion: { [weak self] in
                self?.appState.finishLightingUp()
            }

        case .focusing(let session):
            focusTimer.start(duration: session.duration)
            if appState.soundEnabled { soundEngine.play() }
            menuBarCompanion.show(taskName: session.taskName, timer: focusTimer)
            dockTileRenderer.updateState(.burning, marshmallow: appState.isMarshmallow, streak: appState.streakDays)

        case .dyingDown:
            soundEngine.stop()
            dockTileRenderer.updateState(.dyingDown(progress: 0), marshmallow: false, streak: appState.streakDays)
            animateTransition(duration: 1.5, from: 0, to: 1) { [weak self] progress in
                self?.dockTileRenderer.updateState(.dyingDown(progress: progress), marshmallow: false, streak: self?.appState.streakDays ?? 0)
            } completion: { [weak self] in
                self?.appState.completeSession()
            }

        case .completed:
            focusTimer.stop()
            menuBarCompanion.showIdle()
            appState.recordSessionForStreak()
            dockTileRenderer.updateState(.embers, marshmallow: false, streak: appState.streakDays)
            panelController?.showPanel()
            NSApp.requestUserAttention(.informationalRequest)
        }
    }

    private func animateTransition(duration: TimeInterval, from: Double, to: Double, step: @escaping (Double) -> Void, completion: @escaping () -> Void) {
        transitionTimer?.invalidate()
        let interval: TimeInterval = 0.25
        let steps = Int(duration / interval)
        var current = 0

        transitionTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            Task { @MainActor in
                current += 1
                let progress = Double(current) / Double(steps)
                step(min(progress, 1.0))

                if current >= steps {
                    timer.invalidate()
                    self?.transitionTimer = nil
                    completion()
                }
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelController?.togglePanel()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ application: NSApplication) -> Bool {
        false
    }

    // MARK: - Dock menu

    private func setupDockMenu() {
        let menu = NSMenu()
        menu.delegate = self
        NSApp.delegate = self
    }

    @objc func dockMenuExtinguish() {
        appState.extinguishEarly()
    }

    @objc func dockMenuQuickStart15() { quickStart(minutes: 15) }
    @objc func dockMenuQuickStart25() { quickStart(minutes: 25) }
    @objc func dockMenuQuickStart45() { quickStart(minutes: 45) }
    @objc func dockMenuQuickStart60() { quickStart(minutes: 60) }
    @objc func dockMenuToggleSound() { appState.soundEnabled.toggle() }

    private func quickStart(minutes: Int) {
        appState.selectedDuration = minutes
        appState.draftTaskName = "Quick focus"
        appState.startSession()
    }

    // MARK: - Menus

    private func cleanUpMenus() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Fireplace", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Settings\u{2026}", action: #selector(showSettings), keyEquivalent: ",")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Fireplace", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    @objc private func showSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

// MARK: - Dock Menu

extension AppDelegate: NSMenuDelegate {
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()

        if let taskName = appState.currentTaskName {
            let taskItem = NSMenuItem(title: "\u{1F525} \(taskName)", action: nil, keyEquivalent: "")
            taskItem.isEnabled = false
            menu.addItem(taskItem)

            if case .focusing = appState.phase {
                let remaining = Int(focusTimer.remainingSeconds)
                let mins = remaining / 60
                let timeItem = NSMenuItem(title: "\(mins) min left", action: nil, keyEquivalent: "")
                timeItem.isEnabled = false
                menu.addItem(timeItem)
            }

            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "Extinguish early", action: #selector(dockMenuExtinguish), keyEquivalent: ""))
        } else {
            let quickMenu = NSMenuItem(title: "Quick start", action: nil, keyEquivalent: "")
            let quickSub = NSMenu()
            quickSub.addItem(NSMenuItem(title: "15 minutes", action: #selector(dockMenuQuickStart15), keyEquivalent: ""))
            quickSub.addItem(NSMenuItem(title: "25 minutes", action: #selector(dockMenuQuickStart25), keyEquivalent: ""))
            quickSub.addItem(NSMenuItem(title: "45 minutes", action: #selector(dockMenuQuickStart45), keyEquivalent: ""))
            quickSub.addItem(NSMenuItem(title: "60 minutes", action: #selector(dockMenuQuickStart60), keyEquivalent: ""))
            quickMenu.submenu = quickSub
            menu.addItem(quickMenu)
        }

        menu.addItem(.separator())
        let soundItem = NSMenuItem(
            title: appState.soundEnabled ? "Sound: On" : "Sound: Off",
            action: #selector(dockMenuToggleSound),
            keyEquivalent: ""
        )
        menu.addItem(soundItem)

        return menu
    }
}

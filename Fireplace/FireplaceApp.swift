import SwiftUI

@main
struct FireplaceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    var panelController: PanelController?
    let focusTimer = FocusTimer()
    let dockTileRenderer = DockTileRenderer()
    private var observation: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        cleanUpMenus()

        focusTimer.onComplete = { [weak self] in
            self?.appState.completeSession()
        }

        panelController = PanelController(appState: appState)
        panelController?.showPanel()
        dockTileRenderer.updateState(.idle)

        observation = withObservationTracking {
            _ = self.appState.phase
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.handlePhaseChange()
                self?.reobserve()
            }
        }
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
            dockTileRenderer.updateState(.idle)
        case .focusing(let session):
            focusTimer.start(duration: session.duration)
            dockTileRenderer.updateState(.burning)
        case .completed:
            focusTimer.stop()
            dockTileRenderer.updateState(.embers)
            panelController?.showPanel()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelController?.togglePanel()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ application: NSApplication) -> Bool {
        false
    }

    private func cleanUpMenus() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Fireplace", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }
}

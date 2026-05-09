import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    var openDashboard: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()

        UsageService.shared.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in self?.updateStatusButton(snapshot) }
            .store(in: &cancellables)

        UsageService.shared.$error
            .receive(on: RunLoop.main)
            .sink { [weak self] error in self?.updateStatusButtonError(error) }
            .store(in: &cancellables)

        UsageService.shared.$snapshot
            .receive(on: RunLoop.main)
            .sink { snapshot in
                NotificationService.shared.checkThresholds(
                    snapshot: snapshot,
                    settings: SettingsManager.shared
                )
            }
            .store(in: &cancellables)

        Task { await NotificationService.shared.requestAuthorization() }

        if SettingsManager.shared.hasCompletedOnboarding {
            UsageService.shared.startPolling()
            // Start as a menu-bar-only app; window opens on demand
            NSApp.setActivationPolicy(.accessory)
        } else {
            // First launch: show onboarding window immediately
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }

        // Revert to menu-bar-only whenever all windows are closed
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if NSApp.windows.filter({ $0.isVisible && !$0.className.contains("StatusBar") }).isEmpty {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showDashboard()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "···"
        statusItem?.button?.action = #selector(togglePopover)
        statusItem?.button?.target = self
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc func closePopover() {
        popover?.performClose(nil)
    }

    func showDashboard() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        openDashboard?()
    }

    // MARK: - Popover

    private func setupPopover() {
        let usageSvc = UsageService.shared
        let settingsMgr = SettingsManager.shared
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 320)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(openDashboard: { [weak self] in
                self?.closePopover()
                self?.showDashboard()
            })
            .environmentObject(usageSvc)
            .environmentObject(settingsMgr)
        )
        self.popover = popover
    }

    // MARK: - Status button text

    func updateStatusButton(_ snapshot: UsageSnapshot) {
        guard let button = statusItem?.button else { return }
        let settings = SettingsManager.shared

        if settings.compactDisplay {
            let fiveStr = "\(snapshot.fiveHourUtilization)%"
            let sevenStr = "\(snapshot.sevenDayUtilization)%"
            let attributed = NSMutableAttributedString()
            attributed.append(colored(fiveStr, percent: snapshot.fiveHourUtilization, settings: settings))
            attributed.append(NSAttributedString(string: " · "))
            attributed.append(colored(sevenStr, percent: snapshot.sevenDayUtilization, settings: settings))
            button.attributedTitle = attributed
        } else {
            button.title = "\(snapshot.sevenDayUtilization)%"
        }
    }

    private func colored(_ text: String, percent: Int, settings: SettingsManager) -> NSAttributedString {
        let color: NSColor
        if Double(percent) >= settings.criticalThreshold { color = .systemRed }
        else if Double(percent) >= settings.warningThreshold { color = .systemOrange }
        else { color = .labelColor }
        return NSAttributedString(string: text, attributes: [.foregroundColor: color])
    }

    private func updateStatusButtonError(_ error: AppError?) {
        guard let button = statusItem?.button else { return }
        if let error, error.isFatal {
            button.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: error.errorDescription)
            button.title = ""
        }
    }
}

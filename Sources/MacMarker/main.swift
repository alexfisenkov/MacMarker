import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var preferences: Preferences!
    private var overlay: OverlayController!
    private var input: InputController!
    private var settings: SettingsController!
    private var statusMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        preferences = Preferences()
        overlay = OverlayController()
        input = InputController(preferences: preferences, overlay: overlay)
        settings = SettingsController(preferences: preferences, input: input)
        preferences.onChange = { [weak self] in
            self?.input.preferencesChanged()
            self?.refreshStatus()
        }
        input.onStatusChanged = { [weak self] in self?.refreshStatus() }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let image = NSImage(systemSymbolName: "pencil.tip.crop.circle", accessibilityDescription: "MacMarker") {
            image.isTemplate = true
            statusItem.button?.image = image
        } else { statusItem.button?.title = "✎" }
        statusItem.button?.toolTip = "MacMarker"
        let menu = NSMenu()
        statusMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Настройки…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        let permission = NSMenuItem(title: "Проверить доступ", action: #selector(retryPermission), keyEquivalent: "")
        permission.target = self
        menu.addItem(permission)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Завершить MacMarker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        statusItem.menu = menu
        input.start()
        refreshStatus()
        if !UserDefaults.standard.bool(forKey: "hasLaunched") {
            UserDefaults.standard.set(true, forKey: "hasLaunched")
            settings.show()
            input.retryPermission(prompt: true)
        }
    }

    private func refreshStatus() {
        guard statusMenuItem != nil else { return }
        statusMenuItem.title = input.statusText
        settings.refresh()
        statusItem.button?.toolTip = "MacMarker · " + input.statusText
    }

    @objc private func showSettings() { input.failOpen(); settings.show() }
    @objc private func retryPermission() { input.retryPermission(prompt: true); settings.show() }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationWillTerminate(_ notification: Notification) { input?.failOpen() }
}

// This branch must remain before NSApplication.shared: CI needs no GUI, TCC or
// synthetic global input to exercise the production hold/fade model.
if CommandLine.arguments.contains("--self-test") {
    exit(runSelfTest() ? 0 : 1)
}

let application = NSApplication.shared
application.setActivationPolicy(.accessory)
let delegate = AppDelegate()
application.delegate = delegate
application.run()

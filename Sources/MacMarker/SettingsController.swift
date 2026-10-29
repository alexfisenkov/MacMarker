import AppKit
import ServiceManagement

final class SettingsController: NSObject, NSWindowDelegate {
    private let preferences: Preferences
    private let input: InputController
    private var window: NSWindow!
    private var colorWell: NSColorWell!
    private var opacitySlider: NSSlider!
    private var widthSlider: NSSlider!
    private var opacityLabel: NSTextField!
    private var widthLabel: NSTextField!
    private var recordButton: NSButton!
    private var loginCheckbox: NSButton!
    private var permissionLabel: NSTextField!
    private var loginLabel: NSTextField!
    private var rootStack: NSStackView!

    init(preferences: Preferences, input: InputController) {
        self.preferences = preferences
        self.input = input
        super.init()
        buildWindow()
        input.onRecordingChanged = { [weak self] _ in self?.refresh() }
    }

    func show() {
        refresh()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func refresh() {
        guard window != nil else { return }
        opacityLabel.stringValue = "\(Int((preferences.opacity * 100).rounded()))%"
        widthLabel.stringValue = "\(Int(preferences.width.rounded())) pt"
        recordButton.title = input.isRecording ? "Остановить запись (Escape)" : preferences.shortcut.displayName + " — изменить"
        permissionLabel.stringValue = input.statusText
        permissionLabel.textColor = input.isAvailable ? .secondaryLabelColor : .systemOrange
        switch SMAppService.mainApp.status {
        case .enabled:
            loginCheckbox.state = .on
            loginLabel.stringValue = "Запуск при входе включён"
        case .requiresApproval:
            loginCheckbox.state = .on
            loginLabel.stringValue = "Подтвердите в настройках macOS → Объекты входа"
        default:
            loginCheckbox.state = .off
            loginLabel.stringValue = ""
        }
        window.contentView?.layoutSubtreeIfNeeded()
        let neededHeight = max(490, rootStack.fittingSize.height + 44)
        if abs(window.contentLayoutRect.height - neededHeight) > 1 {
            window.setContentSize(NSSize(width: 450, height: neededHeight))
        }
    }

    private func label(_ text: String, size: CGFloat = 13) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: size)
        return field
    }

    private func row(_ title: String, _ controls: NSView...) -> NSStackView {
        let name = label(title)
        name.widthAnchor.constraint(equalToConstant: 100).isActive = true
        let row = NSStackView(views: [name] + controls)
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        return row
    }

    private func button(_ title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        return button
    }

    private func buildWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 450, height: 490),
                          styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "MacMarker"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        let root = NSStackView()
        rootStack = root
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 14
        root.translatesAutoresizingMaskIntoConstraints = false
        window.contentView!.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 22),
            root.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -22),
            root.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 22)
        ])
        let description = label("Удерживайте клавишу и рисуйте мышью или Pencil.\nОтпустите — пометки растворятся за 1,4 секунды.")
        description.maximumNumberOfLines = 2
        root.addArrangedSubview(description)
        colorWell = NSColorWell(frame: NSRect(x: 0, y: 0, width: 58, height: 28))
        colorWell.color = preferences.color
        colorWell.target = self
        colorWell.action = #selector(colorChanged)
        colorWell.widthAnchor.constraint(equalToConstant: 58).isActive = true
        colorWell.heightAnchor.constraint(equalToConstant: 28).isActive = true
        NSColorPanel.shared.showsAlpha = false
        root.addArrangedSubview(row("Цвет", colorWell))
        opacitySlider = NSSlider(value: preferences.opacity * 100, minValue: 0, maxValue: 100,
                                 target: self, action: #selector(opacityChanged))
        opacitySlider.widthAnchor.constraint(equalToConstant: 210).isActive = true
        opacitySlider.isContinuous = true
        opacitySlider.setAccessibilityLabel("Непрозрачность от 0 до 100 процентов")
        opacityLabel = label("")
        root.addArrangedSubview(row("Непрозрачность", opacitySlider, opacityLabel))
        widthSlider = NSSlider(value: preferences.width, minValue: 1, maxValue: 100,
                               target: self, action: #selector(widthChanged))
        widthSlider.widthAnchor.constraint(equalToConstant: 210).isActive = true
        widthSlider.isContinuous = true
        widthSlider.setAccessibilityLabel("Толщина от 1 до 100 пунктов")
        widthLabel = label("")
        root.addArrangedSubview(row("Толщина", widthSlider, widthLabel))
        recordButton = button("", action: #selector(toggleRecording))
        root.addArrangedSubview(row("Удерживать", recordButton))
        let shortcutHelp = label("Для записи нажмите клавишу с модификаторами\nили нажмите и отпустите один левый/правый модификатор.\nEscape отменяет запись и убирает текущие пометки.", size: 11)
        shortcutHelp.maximumNumberOfLines = 3
        shortcutHelp.textColor = .secondaryLabelColor
        root.addArrangedSubview(shortcutHelp)
        let separator = NSBox()
        separator.boxType = .separator
        separator.widthAnchor.constraint(equalToConstant: 400).isActive = true
        root.addArrangedSubview(separator)
        permissionLabel = label("")
        permissionLabel.maximumNumberOfLines = 2
        permissionLabel.preferredMaxLayoutWidth = 400
        root.addArrangedSubview(permissionLabel)
        let permissionButtons = NSStackView(views: [button("Разрешить доступ", action: #selector(requestPermission)),
                                                   button("Настройки macOS", action: #selector(openPrivacy))])
        permissionButtons.spacing = 10
        root.addArrangedSubview(permissionButtons)
        loginCheckbox = NSButton(checkboxWithTitle: "Запускать при входе в macOS", target: self, action: #selector(loginChanged))
        root.addArrangedSubview(loginCheckbox)
        loginLabel = label("", size: 11)
        loginLabel.textColor = .secondaryLabelColor
        root.addArrangedSubview(loginLabel)
        let footer = label("Только рисунки в памяти. Без записи экрана и отправки данных.", size: 11)
        footer.textColor = .secondaryLabelColor
        root.addArrangedSubview(footer)
        refresh()
        window.center()
    }

    @objc private func colorChanged() {
        preferences.color = colorWell.color
        refresh()
    }

    @objc private func opacityChanged() {
        preferences.opacity = opacitySlider.doubleValue.rounded() / 100
        refresh()
    }

    @objc private func widthChanged() {
        preferences.width = widthSlider.doubleValue.rounded()
        refresh()
    }

    @objc private func toggleRecording() {
        if input.isRecording { input.stopRecording() } else { input.beginRecording() }
    }

    @objc private func requestPermission() { input.retryPermission(prompt: true); refresh() }

    @objc private func openPrivacy() {
        input.stopRecording()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func loginChanged() {
        do {
            if loginCheckbox.state == .on { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            refresh()
            if SMAppService.mainApp.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
        } catch {
            refresh()
            let alert = NSAlert()
            alert.messageText = "Не удалось изменить запуск при входе"
            alert.informativeText = "Установите MacMarker в «Программы» и повторите. " + error.localizedDescription
            alert.beginSheetModal(for: window)
        }
    }

    func windowWillClose(_ notification: Notification) { input.stopRecording() }
    func windowDidResignKey(_ notification: Notification) { input.stopRecording() }
}

import Cocoa

class PortRowView: NSView {

    let portInfo: PortInfo
    let onKill: () -> Void

    var trackingArea: NSTrackingArea?
    var isHovered = false
    var hoverBackground: NSView!
    var killButton: NSButton!

    init(portInfo: PortInfo, onKill: @escaping () -> Void) {
        self.portInfo = portInfo
        self.onKill = onKill
        super.init(frame: NSRect(x: 0, y: 0, width: 340, height: 58))
        setupView()
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        wantsLayer = true

        // Hover background (invisible by default)
        hoverBackground = NSView(frame: NSRect(x: 8, y: 0, width: 324, height: 58))
        hoverBackground.wantsLayer = true
        hoverBackground.layer?.cornerRadius = 8
        hoverBackground.layer?.backgroundColor = NSColor.clear.cgColor
        addSubview(hoverBackground)

        // Port badge
        let portBadge = NSView(frame: NSRect(x: 16, y: 17, width: 58, height: 24))
        portBadge.wantsLayer = true
        portBadge.layer?.backgroundColor = portInfo.category.color.withAlphaComponent(0.12).cgColor
        portBadge.layer?.cornerRadius = 6

        let portLabel = NSTextField(labelWithString: ":\(portInfo.port)")
        portLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        portLabel.textColor = portInfo.category.color
        portLabel.alignment = .center
        portLabel.isBezeled = false
        portLabel.isEditable = false
        portLabel.drawsBackground = false
        portLabel.frame = NSRect(x: 0, y: 4, width: 58, height: 16)
        portBadge.addSubview(portLabel)

        addSubview(portBadge)

        // Process name
        let processLabel = NSTextField(labelWithString: portInfo.process)
        processLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        processLabel.textColor = .labelColor
        processLabel.isBezeled = false
        processLabel.isEditable = false
        processLabel.drawsBackground = false
        processLabel.frame = NSRect(x: 84, y: 27, width: 180, height: 16)
        addSubview(processLabel)

        // Command path (truncated)
        let truncatedPath = truncatePath(portInfo.command)
        let pathLabel = NSTextField(labelWithString: truncatedPath)
        pathLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        pathLabel.textColor = .tertiaryLabelColor
        pathLabel.isBezeled = false
        pathLabel.isEditable = false
        pathLabel.drawsBackground = false
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.frame = NSRect(x: 84, y: 13, width: 220, height: 12)
        pathLabel.toolTip = portInfo.command
        addSubview(pathLabel)

        // PID badge
        let pidBadge = NSView(frame: NSRect(x: 276, y: 28, width: 48, height: 16))
        pidBadge.wantsLayer = true
        pidBadge.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.06).cgColor
        pidBadge.layer?.cornerRadius = 4

        let pidLabel = NSTextField(labelWithString: "\(portInfo.pid)")
        pidLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        pidLabel.textColor = .secondaryLabelColor
        pidLabel.alignment = .center
        pidLabel.isBezeled = false
        pidLabel.isEditable = false
        pidLabel.drawsBackground = false
        pidLabel.frame = NSRect(x: 0, y: 1, width: 48, height: 14)
        pidBadge.addSubview(pidLabel)

        addSubview(pidBadge)

        // Kill button (invisible by default)
        killButton = NSButton(frame: NSRect(x: 296, y: 15, width: 28, height: 28))
        killButton.isBordered = false
        killButton.bezelStyle = .regularSquare
        let killConfig = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        killButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Kill process")?
            .withSymbolConfiguration(killConfig)
        killButton.contentTintColor = NSColor.systemRed.withAlphaComponent(0.8)
        killButton.target = self
        killButton.action = #selector(killClicked)
        killButton.toolTip = "Kill \(portInfo.process) on port \(portInfo.port)"
        killButton.alphaValue = 0
        addSubview(killButton)

        // Separator
        let separator = NSBox(frame: NSRect(x: 84, y: 0, width: 240, height: 1))
        separator.boxType = .separator
        separator.fillColor = .separatorColor.withAlphaComponent(0.2)
        addSubview(separator)
    }

    func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInActiveApp]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingArea {
            removeTrackingArea(area)
        }
        setupTrackingArea()
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            hoverBackground.animator().layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.06).cgColor
            killButton.animator().alphaValue = 1
        }
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            hoverBackground.animator().layer?.backgroundColor = NSColor.clear.cgColor
            killButton.animator().alphaValue = 0
        }
    }

    @objc func killClicked() {
        onKill()
    }

    // MARK: - Path Truncation

    func truncatePath(_ path: String) -> String {
        let maxLength = 50
        if path.count <= maxLength {
            return path
        }

        // Try to preserve the filename
        let components = path.split(separator: "/")
        if let filename = components.last {
            let prefixLength = (maxLength - filename.count - 4) / 2
            if prefixLength > 0 {
                let prefix = path.prefix(prefixLength)
                return "\(prefix)…/\(filename)"
            }
        }

        // Fallback: truncate in the middle
        let prefixLength = maxLength / 2 - 1
        let suffixLength = maxLength / 2 - 2
        let prefix = path.prefix(prefixLength)
        let suffix = path.suffix(suffixLength)
        return "\(prefix)…\(suffix)"
    }
}

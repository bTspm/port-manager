import Cocoa

class SimplePortListViewController: NSViewController {

    weak var appDelegate: AppDelegate?
    var ports: [PortInfo] = []

    var scrollView: NSScrollView!
    var stackView: NSStackView!
    var headerView: NSView!
    var countLabel: NSTextField!

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 420))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeader()
        setupScrollView()

        if let delegate = appDelegate {
            updatePorts(delegate.ports)
        }
    }

    func setupHeader() {
        headerView = NSView(frame: NSRect(x: 0, y: view.bounds.height - 50, width: 340, height: 50))
        headerView.autoresizingMask = [.width, .minYMargin]
        view.addSubview(headerView)

        // Title
        let titleLabel = NSTextField(labelWithString: "Port Manager")
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.frame = NSRect(x: 16, y: 16, width: 150, height: 22)
        headerView.addSubview(titleLabel)

        // Port count
        countLabel = NSTextField(labelWithString: "0 ports")
        countLabel.font = .systemFont(ofSize: 12, weight: .medium)
        countLabel.textColor = .secondaryLabelColor
        countLabel.alignment = .right
        countLabel.frame = NSRect(x: 170, y: 18, width: 80, height: 16)
        headerView.addSubview(countLabel)

        // Refresh button
        let refreshButton = NSButton(frame: NSRect(x: 262, y: 13, width: 28, height: 28))
        refreshButton.isBordered = false
        refreshButton.bezelStyle = .regularSquare
        let refreshConfig = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        refreshButton.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh")?
            .withSymbolConfiguration(refreshConfig)
        refreshButton.contentTintColor = .secondaryLabelColor
        refreshButton.target = self
        refreshButton.action = #selector(refresh)
        headerView.addSubview(refreshButton)

        // Quit button
        let quitButton = NSButton(frame: NSRect(x: 296, y: 13, width: 28, height: 28))
        quitButton.isBordered = false
        quitButton.bezelStyle = .regularSquare
        let quitConfig = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        quitButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Quit")?
            .withSymbolConfiguration(quitConfig)
        quitButton.contentTintColor = .secondaryLabelColor
        quitButton.target = self
        quitButton.action = #selector(quit)
        headerView.addSubview(quitButton)

        // Separator
        let separator = NSBox(frame: NSRect(x: 16, y: 0, width: 308, height: 1))
        separator.boxType = .separator
        separator.fillColor = .separatorColor.withAlphaComponent(0.3)
        headerView.addSubview(separator)
    }

    func setupScrollView() {
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 340, height: 370))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        view.addSubview(scrollView)

        stackView = NSStackView(frame: NSRect(x: 0, y: 0, width: 340, height: 370))
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 4
        stackView.edgeInsets = NSEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        scrollView.documentView = stackView
    }

    func updatePorts(_ newPorts: [PortInfo]) {
        ports = newPorts
        countLabel.stringValue = "\(ports.count) port\(ports.count == 1 ? "" : "s")"
        rebuildList()
    }

    func rebuildList() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for portInfo in ports {
            // Create simple row with text
            let row = NSTextField(labelWithString: ":\(portInfo.port) - \(portInfo.process) (PID: \(portInfo.pid))")
            row.font = .systemFont(ofSize: 12)
            row.textColor = portInfo.category.color
            row.isBezeled = false
            row.isEditable = false
            row.drawsBackground = false
            row.lineBreakMode = .byTruncatingTail

            stackView.addArrangedSubview(row)
        }

        let contentHeight = CGFloat(ports.count * 20 + 16)
        stackView.frame.size.height = max(contentHeight, 370)
    }

    @objc func refresh() {
        appDelegate?.refreshPorts()
        if let ports = appDelegate?.ports {
            updatePorts(ports)
        }
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

import Cocoa

class PortListViewController: NSViewController {

    weak var appDelegate: AppDelegate?
    var ports: [PortInfo] = []

    // UI Components
    var scrollView: NSScrollView!
    var stackView: NSStackView!
    var headerView: NSView!
    var countLabel: NSTextField!
    var emptyStateView: NSView!

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
        setupEmptyState()

        // Load initial data
        if let delegate = appDelegate {
            updatePorts(delegate.ports)
        }
    }

    // MARK: - Setup

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
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.edgeInsets = NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        scrollView.documentView = stackView
    }

    func setupEmptyState() {
        emptyStateView = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 370))
        emptyStateView.isHidden = true

        // Icon
        let iconConfig = NSImage.SymbolConfiguration(pointSize: 40, weight: .light)
        let iconImage = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "No ports")?
            .withSymbolConfiguration(iconConfig)
        let iconView = NSImageView(image: iconImage ?? NSImage())
        iconView.contentTintColor = NSColor(red: 0.30, green: 0.72, blue: 0.42, alpha: 1.0)  // Green
        iconView.frame = NSRect(x: 150, y: 220, width: 40, height: 40)
        emptyStateView.addSubview(iconView)

        // Title
        let titleLabel = NSTextField(labelWithString: "No ports in use")
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.alignment = .center
        titleLabel.isBezeled = false
        titleLabel.isEditable = false
        titleLabel.drawsBackground = false
        titleLabel.frame = NSRect(x: 70, y: 185, width: 200, height: 20)
        emptyStateView.addSubview(titleLabel)

        // Subtitle
        let subtitleLabel = NSTextField(labelWithString: "All clear! No applications are\nlistening on any ports.")
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .tertiaryLabelColor
        subtitleLabel.alignment = .center
        subtitleLabel.isBezeled = false
        subtitleLabel.isEditable = false
        subtitleLabel.drawsBackground = false
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.maximumNumberOfLines = 2
        subtitleLabel.frame = NSRect(x: 50, y: 145, width: 240, height: 36)
        emptyStateView.addSubview(subtitleLabel)

        view.addSubview(emptyStateView)
    }

    // MARK: - Update Methods

    func updatePorts(_ newPorts: [PortInfo]) {
        ports = newPorts
        countLabel.stringValue = "\(ports.count) port\(ports.count == 1 ? "" : "s")"

        if ports.isEmpty {
            emptyStateView.isHidden = false
            scrollView.isHidden = true
        } else {
            emptyStateView.isHidden = true
            scrollView.isHidden = false
            rebuildList()
        }
    }

    func rebuildList() {
        // Remove all existing views
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Group ports by category
        var categorizedPorts: [PortCategory: [PortInfo]] = [:]
        for port in ports {
            categorizedPorts[port.category, default: []].append(port)
        }

        // Add category sections in order
        for category in PortCategory.allCases {
            guard let portsInCategory = categorizedPorts[category], !portsInCategory.isEmpty else {
                continue
            }

            // Add category header
            let headerView = CategoryHeaderView(category: category, count: portsInCategory.count)
            headerView.translatesAutoresizingMaskIntoConstraints = false
            headerView.widthAnchor.constraint(equalToConstant: 340).isActive = true
            headerView.heightAnchor.constraint(equalToConstant: 32).isActive = true
            stackView.addArrangedSubview(headerView)

            // Add port rows
            for portInfo in portsInCategory {
                let rowView = PortRowView(portInfo: portInfo) { [weak self] in
                    self?.showKillConfirmation(for: portInfo)
                }
                rowView.translatesAutoresizingMaskIntoConstraints = false
                rowView.widthAnchor.constraint(equalToConstant: 340).isActive = true
                rowView.heightAnchor.constraint(equalToConstant: 58).isActive = true
                stackView.addArrangedSubview(rowView)
            }
        }

        // Calculate and update stack view height
        let categoryCount = categorizedPorts.count
        let totalRows = ports.count
        let contentHeight = CGFloat(categoryCount * 32 + totalRows * 58 + 16) // headers + rows + padding
        stackView.frame.size.height = max(contentHeight, 370)
    }

    // MARK: - Actions

    @objc func refresh() {
        appDelegate?.refreshPorts()
        if let ports = appDelegate?.ports {
            updatePorts(ports)
        }
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }

    func showKillConfirmation(for portInfo: PortInfo) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Kill \(portInfo.process)?"
        alert.informativeText = "This will terminate the process on port \(portInfo.port) (PID \(portInfo.pid)).\n\nPath: \(portInfo.command)"
        alert.addButton(withTitle: "Kill Process")
        alert.addButton(withTitle: "Cancel")

        if let button = alert.buttons.first {
            button.hasDestructiveAction = true
        }

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            appDelegate?.killProcess(portInfo) { success in
                if !success {
                    self.showErrorAlert()
                }
            }
        }
    }

    func showErrorAlert() {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Failed to kill process"
        alert.informativeText = "The process could not be terminated. It may require elevated privileges."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

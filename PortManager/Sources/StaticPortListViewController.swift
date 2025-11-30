import Cocoa

// Animated button with hover effect
class HoverButton: NSButton {
    var hoverColor: NSColor?
    var normalColor: NSColor?
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let existingArea = trackingArea {
            removeTrackingArea(existingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInKeyWindow]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        if let area = trackingArea {
            addTrackingArea(area)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            if let hover = hoverColor {
                self.animator().contentTintColor = hover
            }
            self.animator().alphaValue = 1.0
        })
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            if let normal = normalColor {
                self.animator().contentTintColor = normal
            }
            self.animator().alphaValue = 0.8
        })
    }
}

// Animated row background with hover effect
class HoverBox: NSBox {
    var hoverFillColor: NSColor = NSColor.controlAccentColor.withAlphaComponent(0.05)
    var normalFillColor: NSColor = .clear
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let existingArea = trackingArea {
            removeTrackingArea(existingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        if let area = trackingArea {
            addTrackingArea(area)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.allowsImplicitAnimation = true
            self.fillColor = hoverFillColor
        })
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.allowsImplicitAnimation = true
            self.fillColor = normalFillColor
        })
    }
}

class StaticPortListViewController: NSViewController, NSTextFieldDelegate {

    let portsSnapshot: [PortInfo]
    weak var appDelegate: AppDelegate?
    var searchField: NSTextField!
    var filteredPorts: [PortInfo] = []
    var isFiltering = false
    var scrollView: NSScrollView!
    var countLabel: NSTextField!
    var selectedPortNumbers: Set<Int> = []  // Track selected port numbers (not indices)
    var killSelectedButton: NSButton!
    var savedScrollPosition: NSPoint?  // Save scroll position for auto-refresh

    init(ports: [PortInfo], selectedPorts: Set<Int> = [], scrollPosition: NSPoint? = nil) {
        self.portsSnapshot = ports
        self.filteredPorts = ports
        self.selectedPortNumbers = selectedPorts
        self.savedScrollPosition = scrollPosition
        super.init(nibName: nil, bundle: nil)
    }

    var currentScrollPosition: NSPoint {
        return scrollView?.contentView.bounds.origin ?? .zero
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 560))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Native header bar
        let headerBar = NSBox(frame: NSRect(x: 0, y: 506, width: 460, height: 54))
        headerBar.boxType = .custom
        headerBar.fillColor = NSColor.windowBackgroundColor
        view.addSubview(headerBar)

        // Title - native style
        let titleLabel = NSTextField(labelWithString: "Ports")
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.frame = NSRect(x: 16, y: 530, width: 100, height: 16)
        titleLabel.isBezeled = false
        titleLabel.isEditable = false
        titleLabel.drawsBackground = false
        view.addSubview(titleLabel)

        // Refresh button (refresh icon) - animated
        let refreshButton = NSButton(frame: NSRect(x: 394, y: 528, width: 22, height: 22))
        refreshButton.isBordered = false
        refreshButton.bezelStyle = .regularSquare
        refreshButton.title = ""
        refreshButton.wantsLayer = true
        let refreshConfig = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        refreshButton.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh")?
            .withSymbolConfiguration(refreshConfig)
        refreshButton.contentTintColor = .secondaryLabelColor
        refreshButton.target = self
        refreshButton.action = #selector(refreshPorts(_:))
        refreshButton.toolTip = "Refresh (⌘R)"
        view.addSubview(refreshButton)

        // Preferences button (gear icon) - top right
        let prefsButton = NSButton(frame: NSRect(x: 422, y: 528, width: 22, height: 22))
        prefsButton.isBordered = false
        prefsButton.bezelStyle = .regularSquare
        prefsButton.title = ""
        let prefsConfig = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        prefsButton.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "Preferences")?
            .withSymbolConfiguration(prefsConfig)
        prefsButton.contentTintColor = .secondaryLabelColor
        prefsButton.target = self
        prefsButton.action = #selector(openPreferences(_:))
        prefsButton.toolTip = "Preferences (⌘,)"
        view.addSubview(prefsButton)

        // Count label - native style, positioned before icons
        let countText = isFiltering ? "\(filteredPorts.count)/\(portsSnapshot.count)" : "\(portsSnapshot.count)"
        countLabel = NSTextField(labelWithString: countText)
        countLabel.font = .systemFont(ofSize: 11, weight: .regular)
        countLabel.textColor = .secondaryLabelColor
        countLabel.frame = NSRect(x: 320, y: 532, width: 65, height: 14)
        countLabel.alignment = .right
        countLabel.isBezeled = false
        countLabel.isEditable = false
        countLabel.drawsBackground = false
        view.addSubview(countLabel)

        // Kill Selected button - native style
        killSelectedButton = NSButton(frame: NSRect(x: 146, y: 527, width: 110, height: 22))
        killSelectedButton.title = selectedPortNumbers.isEmpty ? "Kill Selected" : "Kill \(selectedPortNumbers.count)"
        killSelectedButton.bezelStyle = .rounded
        killSelectedButton.font = .systemFont(ofSize: 11)
        killSelectedButton.contentTintColor = .controlAccentColor
        killSelectedButton.target = self
        killSelectedButton.action = #selector(killSelectedPorts(_:))
        killSelectedButton.isHidden = selectedPortNumbers.isEmpty
        view.addSubview(killSelectedButton)

        // Search field - native NSSearchField style
        let searchContainer = NSBox(frame: NSRect(x: 16, y: 460, width: 428, height: 32))
        searchContainer.boxType = .custom
        searchContainer.fillColor = NSColor.controlBackgroundColor
        searchContainer.cornerRadius = 6
        searchContainer.wantsLayer = true
        searchContainer.layer?.borderWidth = 0.5
        searchContainer.layer?.borderColor = NSColor.separatorColor.cgColor
        view.addSubview(searchContainer)

        // Search icon - native style
        let searchIcon = NSImageView(frame: NSRect(x: 26, y: 468, width: 14, height: 14))
        let iconConfig = NSImage.SymbolConfiguration(pointSize: 11, weight: .regular)
        searchIcon.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "Search")?
            .withSymbolConfiguration(iconConfig)
        searchIcon.contentTintColor = .secondaryLabelColor
        view.addSubview(searchIcon)

        // Search field - native
        searchField = NSTextField(frame: NSRect(x: 46, y: 465, width: 386, height: 20))
        searchField.placeholderString = "Filter"
        searchField.font = .systemFont(ofSize: 13)
        searchField.delegate = self
        searchField.focusRingType = .none
        searchField.isBordered = false
        searchField.backgroundColor = .clear
        view.addSubview(searchField)

        // Separator - native
        let separator = NSBox(frame: NSRect(x: 0, y: 452, width: 460, height: 1))
        separator.boxType = .separator
        view.addSubview(separator)

        // Scroll view - native
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 460, height: 452))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        view.addSubview(scrollView)

        buildScrollViewContent()

        // Restore scroll position if we have one saved (from auto-refresh)
        if let savedPosition = savedScrollPosition {
            DispatchQueue.main.async {
                self.scrollView.contentView.scroll(to: savedPosition)
            }
        }
    }

    // MARK: - Keyboard Shortcuts
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(view)
    }

    override var acceptsFirstResponder: Bool { return true }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Cmd+F - Focus search
        if flags == .command && event.charactersIgnoringModifiers == "f" {
            view.window?.makeFirstResponder(searchField)
            return
        }

        // Cmd+R - Refresh
        if flags == .command && event.charactersIgnoringModifiers == "r" {
            appDelegate?.refreshPorts()
            return
        }

        // Cmd+K - Kill selected
        if flags == .command && event.charactersIgnoringModifiers == "k" {
            if !selectedPortNumbers.isEmpty {
                killSelectedPorts(self)
            }
            return
        }

        // Cmd+A - Select all
        if flags == .command && event.charactersIgnoringModifiers == "a" {
            selectAllPorts()
            return
        }

        // Escape - Clear search/selection
        if event.keyCode == 53 { // Escape key
            if !searchField.stringValue.isEmpty {
                searchField.stringValue = ""
                controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: searchField))
            } else if !selectedPortNumbers.isEmpty {
                clearSelection()
            }
            return
        }

        super.keyDown(with: event)
    }

    func selectAllPorts() {
        let portsToSelect = isFiltering ? filteredPorts : portsSnapshot
        selectedPortNumbers = Set(portsToSelect.map { $0.port })
        refreshView(preserveScroll: true)
    }

    func clearSelection() {
        selectedPortNumbers.removeAll()
        refreshView(preserveScroll: true)
    }

    @objc func openPreferences(_ sender: Any) {
        appDelegate?.showPreferences()
    }

    @objc func refreshPorts(_ sender: Any) {
        // Animate refresh button
        if let button = sender as? NSButton {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
                rotation.fromValue = 0
                rotation.toValue = Double.pi * 2
                rotation.duration = 0.5
                button.layer?.add(rotation, forKey: "rotationAnimation")
            })
        }

        appDelegate?.refreshPorts()
    }

    func buildScrollViewContent() {
        class FlippedView: NSView {
            override var isFlipped: Bool { return true }
        }

        // Animate content changes
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        })

        let portsToDisplay = filteredPorts

        // Calculate total height
        var yPos: CGFloat = 0
        let rowHeight: CGFloat = 44
        let headerHeight: CGFloat = 24
        let sectionSpacing: CGFloat = 8

        // Group by category or favorites
        var favoritesList: [PortInfo] = []
        var categorizedPorts: [PortCategory: [PortInfo]] = [:]

        let favorites = UserDefaults.standard.array(forKey: "FavoritePorts") as? [Int] ?? []

        for port in portsToDisplay {
            if favorites.contains(port.port) {
                favoritesList.append(port)
            } else {
                if categorizedPorts[port.category] == nil {
                    categorizedPorts[port.category] = []
                }
                categorizedPorts[port.category]?.append(port)
            }
        }

        // Calculate height
        if !favoritesList.isEmpty {
            yPos += headerHeight + CGFloat(favoritesList.count) * rowHeight + sectionSpacing
        }

        let categoryOrder: [PortCategory] = [.web, .database, .cache, .system, .other]
        for category in categoryOrder {
            if let ports = categorizedPorts[category], !ports.isEmpty {
                yPos += headerHeight + CGFloat(ports.count) * rowHeight + sectionSpacing
            }
        }

        let documentView = FlippedView(frame: NSRect(x: 0, y: 0, width: 444, height: max(yPos + 16, 452)))
        documentView.wantsLayer = true

        yPos = 12

        var allPortsWithIndex: [(port: PortInfo, index: Int)] = []
        var currentIndex = 0

        // FAVORITES section
        if !favoritesList.isEmpty {
            createCategoryHeader(title: "FAVORITES", icon: "star.fill", yPos: yPos, documentView: documentView, color: .systemYellow)
            yPos += headerHeight

            for port in favoritesList {
                createPortRow(port: port, index: currentIndex, yPos: yPos, documentView: documentView, isFavorite: true)
                allPortsWithIndex.append((port, currentIndex))
                currentIndex += 1
                yPos += rowHeight
            }

            yPos += sectionSpacing
        }

        // Category sections
        for category in categoryOrder {
            guard let ports = categorizedPorts[category], !ports.isEmpty else { continue }

            let (categoryName, icon, color) = getCategoryInfo(category)
            createCategoryHeader(title: categoryName, icon: icon, yPos: yPos, documentView: documentView, color: color)
            yPos += headerHeight

            for port in ports {
                createPortRow(port: port, index: currentIndex, yPos: yPos, documentView: documentView, isFavorite: false)
                allPortsWithIndex.append((port, currentIndex))
                currentIndex += 1
                yPos += rowHeight
            }

            yPos += sectionSpacing
        }

        // Empty state - native
        if filteredPorts.isEmpty && isFiltering {
            let noResultsLabel = NSTextField(labelWithString: "No Results")
            noResultsLabel.font = .systemFont(ofSize: 13, weight: .regular)
            noResultsLabel.textColor = .secondaryLabelColor
            noResultsLabel.alignment = .center
            noResultsLabel.frame = NSRect(x: 0, y: 200, width: 444, height: 16)
            noResultsLabel.isBezeled = false
            noResultsLabel.isEditable = false
            noResultsLabel.drawsBackground = false
            documentView.addSubview(noResultsLabel)
        }

        // Fade in animation for document view
        documentView.alphaValue = 0
        documentView.animator().alphaValue = 1

        scrollView.documentView = documentView
        // Scroll position is now handled in refreshView()
    }

    func getCategoryInfo(_ category: PortCategory) -> (name: String, icon: String, color: NSColor) {
        switch category {
        case .web:
            return ("WEB & DEV", "globe", .systemBlue)
        case .database:
            return ("DATABASES", "cylinder.fill", .systemPurple)
        case .cache:
            return ("CACHE & QUEUES", "bolt.fill", .systemOrange)
        case .system:
            return ("SYSTEM", "gearshape.fill", .systemGray)
        case .other:
            return ("OTHER", "folder.fill", .systemGreen)
        }
    }

    func createCategoryHeader(title: String, icon: String, yPos: CGFloat, documentView: NSView, color: NSColor) {
        // Category icon with color
        let iconView = NSImageView(frame: NSRect(x: 18, y: yPos + 4, width: 12, height: 12))
        let iconConfig = NSImage.SymbolConfiguration(pointSize: 9, weight: .semibold)
        iconView.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?
            .withSymbolConfiguration(iconConfig)
        iconView.contentTintColor = color
        documentView.addSubview(iconView)

        // Native macOS header with better styling
        let headerLabel = NSTextField(labelWithString: title.uppercased())
        headerLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        headerLabel.textColor = .secondaryLabelColor
        headerLabel.frame = NSRect(x: 36, y: yPos + 4, width: 400, height: 14)
        headerLabel.isBezeled = false
        headerLabel.isEditable = false
        headerLabel.drawsBackground = false
        documentView.addSubview(headerLabel)
    }

    func createPortRow(port: PortInfo, index: Int, yPos: CGFloat, documentView: NSView, isFavorite: Bool) {
        let favorites = UserDefaults.standard.array(forKey: "FavoritePorts") as? [Int] ?? []
        let isFavorited = favorites.contains(port.port)

        // Row background - animated hover effect
        let rowBackground = HoverBox(frame: NSRect(x: 8, y: yPos + 1, width: 444, height: 43))
        rowBackground.boxType = .custom
        rowBackground.borderWidth = 0
        rowBackground.cornerRadius = 6
        let isSelected = selectedPortNumbers.contains(port.port)
        rowBackground.fillColor = isSelected ?
            NSColor.controlAccentColor.withAlphaComponent(0.1) : .clear
        rowBackground.normalFillColor = isSelected ?
            NSColor.controlAccentColor.withAlphaComponent(0.1) : .clear
        rowBackground.hoverFillColor = isSelected ?
            NSColor.controlAccentColor.withAlphaComponent(0.15) :
            NSColor.controlAccentColor.withAlphaComponent(0.05)
        documentView.addSubview(rowBackground)

        // Status indicator dot - color coded by category
        let statusDot = NSView(frame: NSRect(x: 20, y: yPos + 19, width: 8, height: 8))
        statusDot.wantsLayer = true
        statusDot.layer?.cornerRadius = 4
        statusDot.layer?.backgroundColor = getCategoryColor(for: port.category).cgColor
        documentView.addSubview(statusDot)

        // Port number - native table style
        let portLabel = NSTextField(labelWithString: ":\(port.port)")
        portLabel.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        portLabel.textColor = .labelColor
        portLabel.frame = NSRect(x: 36, y: yPos + 16, width: 60, height: 16)
        portLabel.isBezeled = false
        portLabel.isEditable = false
        portLabel.drawsBackground = false
        documentView.addSubview(portLabel)

        // Process name
        let processLabel = NSTextField(labelWithString: port.process)
        processLabel.font = .systemFont(ofSize: 13, weight: .medium)
        processLabel.textColor = .labelColor
        processLabel.frame = NSRect(x: 102, y: yPos + 16, width: 80, height: 16)
        processLabel.isBezeled = false
        processLabel.isEditable = false
        processLabel.drawsBackground = false
        documentView.addSubview(processLabel)

        // PID
        let pidLabel = NSTextField(labelWithString: "\(port.pid)")
        pidLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        pidLabel.textColor = .secondaryLabelColor
        pidLabel.frame = NSRect(x: 188, y: yPos + 17, width: 50, height: 14)
        pidLabel.isBezeled = false
        pidLabel.isEditable = false
        pidLabel.drawsBackground = false
        documentView.addSubview(pidLabel)

        // Framework badge - native style with visual badge
        if let framework = port.framework {
            let frameworkBadge = NSBox(frame: NSRect(x: 102, y: yPos + 3, width: 0, height: 16))
            frameworkBadge.boxType = .custom
            frameworkBadge.borderWidth = 0
            frameworkBadge.cornerRadius = 3
            frameworkBadge.fillColor = getCategoryColor(for: port.category).withAlphaComponent(0.15)

            let frameworkLabel = NSTextField(labelWithString: " \(framework) ")
            frameworkLabel.font = .systemFont(ofSize: 10, weight: .medium)
            frameworkLabel.textColor = getCategoryColor(for: port.category)
            frameworkLabel.isBezeled = false
            frameworkLabel.isEditable = false
            frameworkLabel.drawsBackground = false
            frameworkLabel.sizeToFit()

            frameworkBadge.frame = NSRect(x: 102, y: yPos + 3, width: min(frameworkLabel.frame.width, 100), height: 14)
            frameworkLabel.frame = NSRect(x: 102, y: yPos + 4, width: min(frameworkLabel.frame.width, 100), height: 12)
            frameworkLabel.lineBreakMode = .byTruncatingTail

            documentView.addSubview(frameworkBadge)
            documentView.addSubview(frameworkLabel)
        }

        // User
        let userLabel = NSTextField(labelWithString: port.user)
        userLabel.font = .systemFont(ofSize: 11, weight: .regular)
        userLabel.textColor = .tertiaryLabelColor
        userLabel.frame = NSRect(x: 244, y: yPos + 17, width: 60, height: 12)
        userLabel.isBezeled = false
        userLabel.isEditable = false
        userLabel.drawsBackground = false
        documentView.addSubview(userLabel)

        // Docker indicator - enhanced visual badge
        if let container = port.dockerContainer {
            let dockerBadge = NSBox(frame: NSRect(x: 310, y: yPos + 14, width: 24, height: 18))
            dockerBadge.boxType = .custom
            dockerBadge.borderWidth = 0
            dockerBadge.cornerRadius = 4
            dockerBadge.fillColor = NSColor.systemBlue.withAlphaComponent(0.15)
            documentView.addSubview(dockerBadge)

            let dockerLabel = NSTextField(labelWithString: "🐳")
            dockerLabel.font = .systemFont(ofSize: 12)
            dockerLabel.frame = NSRect(x: 314, y: yPos + 15, width: 16, height: 16)
            dockerLabel.isBezeled = false
            dockerLabel.isEditable = false
            dockerLabel.drawsBackground = false
            dockerLabel.toolTip = "Docker: \(container)"
            documentView.addSubview(dockerLabel)
        }

        // Star button - animated with hover
        let starButton = HoverButton(frame: NSRect(x: 354, y: yPos + 13, width: 20, height: 20))
        starButton.isBordered = false
        starButton.bezelStyle = .regularSquare
        starButton.title = ""
        let starConfig = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        let starIcon = isFavorited ? "star.fill" : "star"
        starButton.image = NSImage(systemSymbolName: starIcon, accessibilityDescription: "Favorite")?
            .withSymbolConfiguration(starConfig)
        starButton.contentTintColor = isFavorited ? .systemYellow : .tertiaryLabelColor
        starButton.normalColor = isFavorited ? .systemYellow : .tertiaryLabelColor
        starButton.hoverColor = .systemYellow
        starButton.alphaValue = isFavorited ? 1.0 : 0.5
        starButton.tag = index
        starButton.target = self
        starButton.action = #selector(toggleFavorite(_:))
        starButton.toolTip = isFavorited ? "Unpin" : "Pin"
        documentView.addSubview(starButton)

        // Kill button - animated with hover
        let killButton = HoverButton(frame: NSRect(x: 380, y: yPos + 13, width: 20, height: 20))
        killButton.isBordered = false
        killButton.bezelStyle = .regularSquare
        killButton.title = ""
        let killConfig = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        killButton.image = NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: "Kill")?
            .withSymbolConfiguration(killConfig)
        killButton.contentTintColor = .systemRed
        killButton.normalColor = .systemRed
        killButton.hoverColor = .systemRed.blended(withFraction: 0.3, of: .white) ?? .systemRed
        killButton.alphaValue = 0.5
        killButton.tag = index
        killButton.target = self
        killButton.action = #selector(portClicked(_:))
        killButton.toolTip = "Kill"
        documentView.addSubview(killButton)

        // Checkbox - native
        let checkbox = NSButton(frame: NSRect(x: 408, y: yPos + 14, width: 18, height: 18))
        checkbox.setButtonType(.switch)
        checkbox.title = ""
        checkbox.state = selectedPortNumbers.contains(port.port) ? .on : .off
        checkbox.tag = index
        checkbox.target = self
        checkbox.action = #selector(togglePortSelection(_:))
        documentView.addSubview(checkbox)

        // Separator line - native (subtle)
        let separator = NSBox(frame: NSRect(x: 16, y: yPos, width: 428, height: 1))
        separator.boxType = .separator
        separator.alphaValue = 0.3
        documentView.addSubview(separator)

        // Make row clickable for context menu
        let clickArea = NSButton(frame: NSRect(x: 8, y: yPos, width: 340, height: 44))
        clickArea.isBordered = false
        clickArea.bezelStyle = .regularSquare
        clickArea.title = ""
        clickArea.tag = index
        clickArea.target = self
        clickArea.action = #selector(portClicked(_:))
        documentView.addSubview(clickArea)

        // Tooltip with full details
        let tooltipText = """
        Port: \(port.port)
        PID: \(port.pid)
        User: \(port.user)
        Command: \(port.command)
        """
        clickArea.toolTip = tooltipText
        portLabel.toolTip = tooltipText

        // Right-click menu
        let menu = NSMenu()

        if isFavorited {
            menu.addItem(withTitle: "Unpin from Favorites", action: #selector(unpinFavorite(_:)), keyEquivalent: "")
        } else {
            menu.addItem(withTitle: "Pin to Favorites", action: #selector(pinFavorite(_:)), keyEquivalent: "")
        }
        menu.addItem(NSMenuItem.separator())

        menu.addItem(withTitle: "Copy Port Number", action: #selector(copyPort(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Copy PID", action: #selector(copyPID(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Copy Process Name", action: #selector(copyProcess(_:)), keyEquivalent: "")

        if port.dockerContainer != nil {
            menu.addItem(withTitle: "Copy Container Name", action: #selector(copyContainer(_:)), keyEquivalent: "")
        }

        menu.addItem(withTitle: "Copy Kill Command", action: #selector(copyKillCommand(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())

        // Framework-specific quick actions
        if let quickActions = getFrameworkQuickActions(for: port) {
            for action in quickActions {
                let menuItem = menu.addItem(withTitle: action.title, action: #selector(executeQuickAction(_:)), keyEquivalent: "")
                menuItem.representedObject = (port: port, action: action)
            }
            menu.addItem(NSMenuItem.separator())
        }

        // Custom commands
        let customCommands = getCustomCommands()
        if !customCommands.isEmpty {
            for command in customCommands {
                let menuItem = menu.addItem(withTitle: command.name, action: #selector(executeCustomCommand(_:)), keyEquivalent: "")
                menuItem.representedObject = (port: port, command: command)
            }
            menu.addItem(NSMenuItem.separator())
        }

        // Add "New Custom Command" option
        menu.addItem(withTitle: "➕ New Custom Command...", action: #selector(createCustomCommand(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())

        // Docker controls if this is a Docker container
        if port.dockerContainer != nil {
            menu.addItem(withTitle: "Stop Container", action: #selector(stopDockerContainer(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "Restart Container", action: #selector(restartDockerContainer(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "View Logs", action: #selector(viewDockerLogs(_:)), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
        }

        menu.addItem(withTitle: "Kill Process", action: #selector(portClicked(_:)), keyEquivalent: "")

        for item in menu.items {
            item.representedObject = port
            item.target = self
        }

        clickArea.menu = menu
    }

    func getCategoryColor(for category: PortCategory) -> NSColor {
        switch category {
        case .web: return .systemBlue
        case .database: return .systemPurple
        case .cache: return .systemOrange
        case .system: return .systemGray
        case .other: return .systemGreen
        }
    }

    func refreshView(preserveScroll: Bool = false) {
        // Save current scroll position
        let scrollPosition = scrollView.contentView.bounds.origin

        // Animate the transition
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            buildScrollViewContent()

            let countText = isFiltering ? "\(filteredPorts.count)/\(portsSnapshot.count)" : "\(portsSnapshot.count)"
            countLabel.animator().stringValue = countText

            // Restore scroll position if needed
            if preserveScroll {
                scrollView.contentView.animator().setBoundsOrigin(scrollPosition)
            } else {
                scrollView.contentView.animator().setBoundsOrigin(NSPoint.zero)
            }
        })
    }

    // MARK: - Search
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField, textField == searchField else { return }
        filterPorts(searchText: textField.stringValue)
    }

    func filterPorts(searchText: String) {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            filteredPorts = portsSnapshot
            isFiltering = false
        } else {
            isFiltering = true
            let searchLower = trimmed.lowercased()

            filteredPorts = portsSnapshot.filter { port in
                String(port.port).contains(searchLower) ||
                port.process.lowercased().contains(searchLower) ||
                (port.framework?.lowercased().contains(searchLower) ?? false) ||
                port.category.rawValue.lowercased().contains(searchLower) ||
                (port.dockerContainer?.lowercased().contains(searchLower) ?? false)
            }
        }

        // Clear selection when filter changes
        selectedPortNumbers.removeAll()
        killSelectedButton.isHidden = true

        // Update AppDelegate's selection tracking
        appDelegate?.selectedPortNumbers.removeAll()

        // Preserve scroll position during search
        refreshView(preserveScroll: !trimmed.isEmpty)
    }

    // MARK: - Actions
    @objc func toggleFavorite(_ sender: NSButton) {
        let index = sender.tag
        guard index < filteredPorts.count else { return }
        let port = filteredPorts[index]

        var favorites = UserDefaults.standard.array(forKey: "FavoritePorts") as? [Int] ?? []
        if favorites.contains(port.port) {
            favorites.removeAll { $0 == port.port }
        } else {
            favorites.append(port.port)
        }
        UserDefaults.standard.set(favorites, forKey: "FavoritePorts")
        refreshView(preserveScroll: true)
    }

    @objc func togglePortSelection(_ sender: NSButton) {
        let index = sender.tag
        guard index < filteredPorts.count else { return }
        let portNumber = filteredPorts[index].port

        if sender.state == .on {
            selectedPortNumbers.insert(portNumber)
        } else {
            selectedPortNumbers.remove(portNumber)
        }

        // Animate Kill Selected button visibility
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            if selectedPortNumbers.isEmpty {
                killSelectedButton.animator().alphaValue = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.killSelectedButton.isHidden = true
                }
            } else {
                if killSelectedButton.isHidden {
                    killSelectedButton.alphaValue = 0
                    killSelectedButton.isHidden = false
                }
                killSelectedButton.animator().alphaValue = 1
                killSelectedButton.title = "Kill \(selectedPortNumbers.count) Selected"
            }
        })

        // Update AppDelegate's selection tracking
        appDelegate?.selectedPortNumbers = selectedPortNumbers
    }

    @objc func killSelectedPorts(_ sender: Any) {
        guard !selectedPortNumbers.isEmpty else { return }

        let selectedPortsList = portsSnapshot.filter { port in
            selectedPortNumbers.contains(port.port)
        }.sorted { $0.port < $1.port }

        let alert = NSAlert()
        alert.messageText = "Kill \(selectedPortsList.count) Processes?"
        let portNumbers = selectedPortsList.map { ":\($0.port)" }.joined(separator: ", ")
        alert.informativeText = "This will terminate the following processes:\n\(portNumbers)\n\nAre you sure?"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Kill All")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            var successCount = 0
            var failureCount = 0

            for port in selectedPortsList {
                let task = Process()
                task.launchPath = "/bin/kill"
                task.arguments = ["-9", "\(port.pid)"]

                do {
                    try task.run()
                    task.waitUntilExit()
                    if task.terminationStatus == 0 {
                        successCount += 1
                    } else {
                        failureCount += 1
                    }
                } catch {
                    failureCount += 1
                }
            }

            // Clear selection
            selectedPortNumbers.removeAll()
            killSelectedButton.isHidden = true

            // Update AppDelegate's selection tracking
            appDelegate?.selectedPortNumbers.removeAll()

            // Show result
            let resultAlert = NSAlert()
            if failureCount == 0 {
                resultAlert.messageText = "Success"
                resultAlert.informativeText = "Successfully killed \(successCount) process(es)."
                resultAlert.alertStyle = .informational
            } else {
                resultAlert.messageText = "Partial Success"
                resultAlert.informativeText = "Killed \(successCount) process(es).\nFailed to kill \(failureCount) process(es)."
                resultAlert.alertStyle = .warning
            }
            resultAlert.addButton(withTitle: "OK")
            resultAlert.runModal()

            // Refresh port list
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.appDelegate?.refreshPorts()
            }
        }
    }

    @objc func showInfo(_ sender: NSButton) {
        let index = sender.tag
        guard index < filteredPorts.count else { return }
        let port = filteredPorts[index]

        let alert = NSAlert()
        alert.messageText = "Port \(port.port) Details"
        alert.informativeText = """
        Process: \(port.process)
        PID: \(port.pid)
        User: \(port.user)
        Category: \(port.category.rawValue)
        \(port.framework != nil ? "Framework: \(port.framework!)" : "")
        \(port.dockerContainer != nil ? "Container: \(port.dockerContainer!)" : "")

        Command:
        \(port.command)
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func portClicked(_ sender: NSButton) {
        let index = sender.tag
        guard index < filteredPorts.count else { return }
        let port = filteredPorts[index]

        let alert = NSAlert()
        alert.messageText = "Kill Process?"
        alert.informativeText = "This will terminate the process '\(port.process)' (PID: \(port.pid)) on port \(port.port)."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Kill")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            let task = Process()
            task.launchPath = "/bin/kill"
            task.arguments = ["-9", "\(port.pid)"]

            do {
                try task.run()
                task.waitUntilExit()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.appDelegate?.refreshPorts()
                }
            } catch {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Failed to Kill Process"
                errorAlert.informativeText = "Error: \(error.localizedDescription)"
                errorAlert.alertStyle = .critical
                errorAlert.runModal()
            }
        }
    }

    @objc func pinFavorite(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? PortInfo else { return }
        var favorites = UserDefaults.standard.array(forKey: "FavoritePorts") as? [Int] ?? []
        if !favorites.contains(port.port) {
            favorites.append(port.port)
            UserDefaults.standard.set(favorites, forKey: "FavoritePorts")
            refreshView()
        }
    }

    @objc func unpinFavorite(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? PortInfo else { return }
        var favorites = UserDefaults.standard.array(forKey: "FavoritePorts") as? [Int] ?? []
        favorites.removeAll { $0 == port.port }
        UserDefaults.standard.set(favorites, forKey: "FavoritePorts")
        refreshView()
    }

    @objc func copyPort(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? PortInfo else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("\(port.port)", forType: .string)
    }

    @objc func copyPID(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? PortInfo else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("\(port.pid)", forType: .string)
    }

    @objc func copyProcess(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? PortInfo else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(port.process, forType: .string)
    }

    @objc func copyContainer(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? PortInfo else { return }
        if let container = port.dockerContainer {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(container, forType: .string)
        }
    }

    @objc func copyKillCommand(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? PortInfo else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("kill -9 \(port.pid)", forType: .string)
    }


    // MARK: - Custom Commands
    struct CustomCommand: Codable {
        let name: String
        let template: String
        let openInTerminal: Bool

        static let storageKey = "CustomCommands"
    }

    func getCustomCommands() -> [CustomCommand] {
        guard let data = UserDefaults.standard.data(forKey: CustomCommand.storageKey),
              let commands = try? JSONDecoder().decode([CustomCommand].self, from: data) else {
            // Return default commands if none saved
            return [
                CustomCommand(name: "🔍 Check Port", template: "lsof -i :{port}", openInTerminal: true),
                CustomCommand(name: "🌐 cURL Health Check", template: "curl http://localhost:{port}/health", openInTerminal: true)
            ]
        }
        return commands
    }

    func saveCustomCommands(_ commands: [CustomCommand]) {
        if let data = try? JSONEncoder().encode(commands) {
            UserDefaults.standard.set(data, forKey: CustomCommand.storageKey)
        }
    }

    func expandTemplate(_ template: String, port: PortInfo) -> String {
        return template
            .replacingOccurrences(of: "{port}", with: "\(port.port)")
            .replacingOccurrences(of: "{pid}", with: "\(port.pid)")
            .replacingOccurrences(of: "{process}", with: port.process)
            .replacingOccurrences(of: "{user}", with: port.user)
            .replacingOccurrences(of: "{command}", with: port.command)
    }

    @objc func executeCustomCommand(_ sender: NSMenuItem) {
        guard let tuple = sender.representedObject as? (port: PortInfo, command: CustomCommand) else { return }
        let port = tuple.port
        let command = tuple.command

        let expandedCommand = expandTemplate(command.template, port: port)

        if command.openInTerminal {
            let script = """
            tell application "Terminal"
                activate
                do script "\(expandedCommand)"
            end tell
            """

            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)

                if let error = error {
                    let alert = NSAlert()
                    alert.messageText = "Failed to Execute Command"
                    alert.informativeText = "Could not open Terminal: \(error)"
                    alert.alertStyle = .critical
                    alert.runModal()
                }
            }
        } else {
            // Execute in background and show result
            let task = Process()
            task.launchPath = "/bin/sh"
            task.arguments = ["-c", expandedCommand]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                let alert = NSAlert()
                alert.messageText = "Command Output"
                alert.informativeText = output.isEmpty ? "Command completed successfully (no output)" : output
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            } catch {
                let alert = NSAlert()
                alert.messageText = "Command Failed"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.runModal()
            }
        }
    }

    @objc func createCustomCommand(_ sender: NSMenuItem) {
        guard sender.representedObject is PortInfo else { return }

        // Create a dialog to add new custom command
        let alert = NSAlert()
        alert.messageText = "New Custom Command"
        alert.informativeText = "Create a custom command template.\n\nAvailable variables:\n{port} - Port number\n{pid} - Process ID\n{process} - Process name\n{user} - User\n{command} - Full command path"
        alert.alertStyle = .informational

        // Name field
        let nameField = NSTextField(frame: NSRect(x: 0, y: 60, width: 300, height: 24))
        nameField.placeholderString = "Command name (e.g., 'Check Port')"
        nameField.stringValue = ""

        // Template field
        let templateField = NSTextField(frame: NSRect(x: 0, y: 30, width: 300, height: 24))
        templateField.placeholderString = "Command template (e.g., 'lsof -i :{port}')"
        templateField.stringValue = ""

        // Checkbox for terminal
        let terminalCheckbox = NSButton(checkboxWithTitle: "Open in Terminal", target: nil, action: nil)
        terminalCheckbox.frame = NSRect(x: 0, y: 0, width: 300, height: 24)
        terminalCheckbox.state = .on

        let stackView = NSStackView(views: [nameField, templateField, terminalCheckbox])
        stackView.orientation = .vertical
        stackView.spacing = 10
        stackView.frame = NSRect(x: 0, y: 0, width: 300, height: 90)

        alert.accessoryView = stackView
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            let name = nameField.stringValue.trimmingCharacters(in: .whitespaces)
            let template = templateField.stringValue.trimmingCharacters(in: .whitespaces)

            guard !name.isEmpty && !template.isEmpty else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Invalid Input"
                errorAlert.informativeText = "Both name and template are required."
                errorAlert.alertStyle = .warning
                errorAlert.runModal()
                return
            }

            var commands = getCustomCommands()
            let newCommand = CustomCommand(
                name: name,
                template: template,
                openInTerminal: terminalCheckbox.state == .on
            )
            commands.append(newCommand)
            saveCustomCommands(commands)

            let successAlert = NSAlert()
            successAlert.messageText = "Command Created"
            successAlert.informativeText = "'\(name)' has been added to the context menu."
            successAlert.alertStyle = .informational
            successAlert.runModal()
        }
    }

    // MARK: - Framework Quick Actions
    struct QuickAction {
        let title: String
        let type: ActionType

        enum ActionType {
            case openBrowser(path: String)
            case openTerminalCommand(command: String)
            case copyURL(path: String)
        }
    }

    func getFrameworkQuickActions(for port: PortInfo) -> [QuickAction]? {
        guard let framework = port.framework?.lowercased() else {
            // Add generic web server actions
            if port.category == .web {
                return [
                    QuickAction(title: "🌐 Open in Browser", type: .openBrowser(path: "/")),
                    QuickAction(title: "📋 Copy URL", type: .copyURL(path: "/"))
                ]
            }
            return nil
        }

        var actions: [QuickAction] = []

        // Web Frameworks
        if framework.contains("next") || framework.contains("react") || framework.contains("vite") {
            actions = [
                QuickAction(title: "🌐 Open in Browser", type: .openBrowser(path: "/")),
                QuickAction(title: "📋 Copy URL", type: .copyURL(path: "/"))
            ]
        } else if framework.contains("django") {
            actions = [
                QuickAction(title: "🌐 Open Site", type: .openBrowser(path: "/")),
                QuickAction(title: "⚙️ Open Admin", type: .openBrowser(path: "/admin")),
                QuickAction(title: "📋 Copy URL", type: .copyURL(path: "/"))
            ]
        } else if framework.contains("rails") {
            actions = [
                QuickAction(title: "🌐 Open Site", type: .openBrowser(path: "/")),
                QuickAction(title: "📋 Copy URL", type: .copyURL(path: "/"))
            ]
        } else if framework.contains("flask") || framework.contains("fastapi") {
            actions = [
                QuickAction(title: "🌐 Open Site", type: .openBrowser(path: "/")),
                QuickAction(title: "📄 Open Docs", type: .openBrowser(path: "/docs")),
                QuickAction(title: "📋 Copy URL", type: .copyURL(path: "/"))
            ]
        }
        // Databases
        else if framework.contains("postgresql") || framework.contains("postgres") {
            actions = [
                QuickAction(title: "💻 Open psql", type: .openTerminalCommand(command: "psql -h localhost -p \(port.port) -U postgres"))
            ]
        } else if framework.contains("mysql") {
            actions = [
                QuickAction(title: "💻 Open MySQL CLI", type: .openTerminalCommand(command: "mysql -h localhost -P \(port.port) -u root -p"))
            ]
        } else if framework.contains("mongodb") {
            actions = [
                QuickAction(title: "💻 Open Mongo Shell", type: .openTerminalCommand(command: "mongosh --port \(port.port)"))
            ]
        } else if framework.contains("redis") {
            actions = [
                QuickAction(title: "💻 Open Redis CLI", type: .openTerminalCommand(command: "redis-cli -p \(port.port)"))
            ]
        }

        return actions.isEmpty ? nil : actions
    }

    @objc func executeQuickAction(_ sender: NSMenuItem) {
        guard let tuple = sender.representedObject as? (port: PortInfo, action: QuickAction) else { return }
        let port = tuple.port
        let action = tuple.action

        switch action.type {
        case .openBrowser(let path):
            let urlString = "http://localhost:\(port.port)\(path)"
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }

        case .copyURL(let path):
            let urlString = "http://localhost:\(port.port)\(path)"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(urlString, forType: .string)

            // Brief confirmation
            let alert = NSAlert()
            alert.messageText = "URL Copied"
            alert.informativeText = "Copied '\(urlString)' to clipboard."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()

        case .openTerminalCommand(let command):
            let script = """
            tell application "Terminal"
                activate
                do script "\(command)"
            end tell
            """

            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)

                if let error = error {
                    let alert = NSAlert()
                    alert.messageText = "Failed to Execute Command"
                    alert.informativeText = "Could not open Terminal: \(error)"
                    alert.alertStyle = .critical
                    alert.runModal()
                }
            }
        }
    }

    // MARK: - Docker Control
    func getDockerStatusIcon(status: String?) -> String {
        guard let status = status?.lowercased() else { return "🐳" }

        if status.contains("up") {
            return "🟢"
        } else if status.contains("exited") || status.contains("dead") {
            return "⚫️"
        } else if status.contains("paused") {
            return "⏸"
        } else if status.contains("restarting") {
            return "🔄"
        }

        return "🐳"
    }

    func getDockerStatusColor(status: String?) -> NSColor {
        guard let status = status?.lowercased() else { return .systemTeal }

        if status.contains("up") {
            return .systemGreen
        } else if status.contains("exited") || status.contains("dead") {
            return .systemGray
        } else if status.contains("restarting") {
            return .systemOrange
        }

        return .systemTeal
    }

    @objc func stopDockerContainer(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? PortInfo,
              let containerName = port.dockerContainer else { return }

        let alert = NSAlert()
        alert.messageText = "Stop Docker Container?"
        alert.informativeText = "This will stop the container '\(containerName)'."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Stop")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            let task = Process()
            task.launchPath = "/usr/local/bin/docker"
            task.arguments = ["stop", containerName]

            do {
                try task.run()
                task.waitUntilExit()

                let resultAlert = NSAlert()
                if task.terminationStatus == 0 {
                    resultAlert.messageText = "Container Stopped"
                    resultAlert.informativeText = "Successfully stopped '\(containerName)'."
                    resultAlert.alertStyle = .informational
                } else {
                    resultAlert.messageText = "Stop Failed"
                    resultAlert.informativeText = "Could not stop container. Check Docker Desktop is running."
                    resultAlert.alertStyle = .warning
                }
                resultAlert.addButton(withTitle: "OK")
                resultAlert.runModal()

                // Refresh port list after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.appDelegate?.refreshPorts()
                }
            } catch {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Failed to Stop Container"
                errorAlert.informativeText = error.localizedDescription
                errorAlert.alertStyle = .critical
                errorAlert.runModal()
            }
        }
    }

    @objc func restartDockerContainer(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? PortInfo,
              let containerName = port.dockerContainer else { return }

        let task = Process()
        task.launchPath = "/usr/local/bin/docker"
        task.arguments = ["restart", containerName]

        do {
            try task.run()
            task.waitUntilExit()

            let alert = NSAlert()
            if task.terminationStatus == 0 {
                alert.messageText = "Container Restarted"
                alert.informativeText = "Successfully restarted '\(containerName)'."
                alert.alertStyle = .informational
            } else {
                alert.messageText = "Restart Failed"
                alert.informativeText = "Could not restart container. Check Docker Desktop is running."
                alert.alertStyle = .warning
            }
            alert.addButton(withTitle: "OK")
            alert.runModal()

            // Refresh port list after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.appDelegate?.refreshPorts()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to Restart Container"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    @objc func viewDockerLogs(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? PortInfo,
              let containerName = port.dockerContainer else { return }

        // Open Terminal and run docker logs
        let script = """
        tell application "Terminal"
            activate
            do script "docker logs -f \(containerName); echo '\\nPress any key to close...'; read -n 1; exit"
        end tell
        """

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)

            if let error = error {
                let alert = NSAlert()
                alert.messageText = "Failed to Open Logs"
                alert.informativeText = "Could not open Terminal: \(error)"
                alert.alertStyle = .critical
                alert.runModal()
            }
        }
    }
}

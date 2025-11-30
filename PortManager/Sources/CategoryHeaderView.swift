import Cocoa

class CategoryHeaderView: NSView {

    let category: PortCategory
    let count: Int

    init(category: PortCategory, count: Int) {
        self.category = category
        self.count = count
        super.init(frame: NSRect(x: 0, y: 0, width: 340, height: 32))
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        wantsLayer = true

        // Background with slight tint
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.06).cgColor

        // Icon
        let iconConfig = NSImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        let iconImage = NSImage(systemSymbolName: category.icon, accessibilityDescription: category.rawValue)?
            .withSymbolConfiguration(iconConfig)
        let iconView = NSImageView(image: iconImage ?? NSImage())
        iconView.contentTintColor = category.color
        iconView.frame = NSRect(x: 16, y: 11, width: 10, height: 10)
        addSubview(iconView)

        // Category label
        let label = NSTextField(labelWithString: category.rawValue)
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .secondaryLabelColor
        label.frame = NSRect(x: 32, y: 9, width: 200, height: 14)
        addSubview(label)

        // Count badge
        let countBadge = NSView(frame: NSRect(x: 296, y: 8, width: 28, height: 16))
        countBadge.wantsLayer = true
        countBadge.layer?.backgroundColor = category.color.withAlphaComponent(0.15).cgColor
        countBadge.layer?.cornerRadius = 8

        let countLabel = NSTextField(labelWithString: "\(count)")
        countLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .semibold)
        countLabel.textColor = category.color
        countLabel.alignment = .center
        countLabel.frame = NSRect(x: 0, y: 1, width: 28, height: 14)
        countBadge.addSubview(countLabel)

        addSubview(countBadge)
    }
}

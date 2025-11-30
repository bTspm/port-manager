import Cocoa

class MinimalPortListViewController: NSViewController {

    weak var appDelegate: AppDelegate?

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

        // Just show port count
        let label = NSTextField(labelWithString: "Ports: \(appDelegate?.ports.count ?? 0)")
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .labelColor
        label.alignment = .center
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.frame = NSRect(x: 50, y: 200, width: 240, height: 22)
        view.addSubview(label)

        // List ports as simple text
        var yPos: CGFloat = 160
        for port in (appDelegate?.ports ?? []).prefix(5) {
            let portLabel = NSTextField(labelWithString: ":\(port.port) - \(port.process)")
            portLabel.font = .systemFont(ofSize: 12)
            portLabel.textColor = .labelColor
            portLabel.isBezeled = false
            portLabel.isEditable = false
            portLabel.drawsBackground = false
            portLabel.frame = NSRect(x: 50, y: yPos, width: 240, height: 16)
            view.addSubview(portLabel)
            yPos -= 20
        }
    }
}

import Cocoa

class SimpleTestViewController: NSViewController {

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 420))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Just a simple label to test
        let label = NSTextField(labelWithString: "✅ Port Manager Works!")
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .labelColor
        label.alignment = .center
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.frame = NSRect(x: 50, y: 200, width: 240, height: 30)
        view.addSubview(label)

        let subtitle = NSTextField(labelWithString: "Click the X button to quit")
        subtitle.font = .systemFont(ofSize: 12, weight: .regular)
        subtitle.textColor = .secondaryLabelColor
        subtitle.alignment = .center
        subtitle.isBezeled = false
        subtitle.isEditable = false
        subtitle.drawsBackground = false
        subtitle.frame = NSRect(x: 50, y: 170, width: 240, height: 20)
        view.addSubview(subtitle)

        // Simple quit button
        let quitButton = NSButton(title: "Quit App", target: nil, action: #selector(quit))
        quitButton.frame = NSRect(x: 120, y: 120, width: 100, height: 32)
        quitButton.target = self
        view.addSubview(quitButton)
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

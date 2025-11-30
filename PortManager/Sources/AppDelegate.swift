import Cocoa

// MARK: - Port Category Definition
enum PortCategory: String, CaseIterable {
    case web = "WEB & DEV SERVERS"
    case database = "DATABASES"
    case cache = "CACHE & QUEUES"
    case system = "SYSTEM"
    case other = "OTHER"

    var icon: String {
        switch self {
        case .web: return "globe"
        case .database: return "cylinder"
        case .cache: return "bolt.fill"
        case .system: return "gearshape.fill"
        case .other: return "shippingbox.fill"
        }
    }

    var color: NSColor {
        switch self {
        case .web:
            return NSColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1.0)  // #59C7FA
        case .database:
            return NSColor(red: 0.69, green: 0.55, blue: 0.98, alpha: 1.0)  // #B08DF8
        case .cache:
            return NSColor(red: 0.98, green: 0.75, blue: 0.35, alpha: 1.0)  // #F9BF59
        case .system:
            return NSColor(red: 0.60, green: 0.60, blue: 0.65, alpha: 1.0)  // #9999A5
        case .other:
            return NSColor(red: 0.55, green: 0.78, blue: 0.55, alpha: 1.0)  // #8DC78D
        }
    }

    var sortOrder: Int {
        switch self {
        case .web: return 0
        case .database: return 1
        case .cache: return 2
        case .system: return 3
        case .other: return 4
        }
    }

    static func categorize(port: Int, process: String) -> PortCategory {
        let processLower = process.lowercased()

        // Web & Dev Servers
        let webProcesses = ["node", "python", "python3", "ruby", "php", "java", "go",
                           "nginx", "apache", "httpd", "uvicorn", "gunicorn", "puma",
                           "rails", "next", "vite", "webpack", "esbuild", "deno", "bun",
                           "caddy", "traefik"]
        let webPorts = [80, 443, 8080, 9090] +
                      Array(3000...3999) + Array(4000...4999) +
                      Array(5000...5999) + Array(8000...8999)

        if webProcesses.contains(where: { processLower.contains($0) }) || webPorts.contains(port) {
            return .web
        }

        // Databases
        let dbProcesses = ["postgres", "mysql", "mysqld", "mongod", "mongodb",
                          "clickhouse", "elasticsearch", "cockroach", "mariadb",
                          "sqlite", "couchdb"]
        let dbPorts = [5432, 3306, 27017, 27018, 5984, 9200, 9300, 26257, 8123, 9440]

        if dbProcesses.contains(where: { processLower.contains($0) }) || dbPorts.contains(port) {
            return .database
        }

        // Cache & Queues
        let cacheProcesses = ["redis", "memcached", "rabbitmq", "kafka", "nats",
                             "mosquitto", "activemq", "zeromq"]
        let cachePorts = [6379, 11211, 5672, 15672, 9092, 4222, 1883, 61616]

        if cacheProcesses.contains(where: { processLower.contains($0) }) || cachePorts.contains(port) {
            return .cache
        }

        // System
        let systemProcesses = ["launchd", "sshd", "cupsd", "rapportd", "airplayxpc",
                              "controlce", "sharingd", "screensharing", "remoted",
                              "avahi", "mdns", "bluetoothd", "configd"]
        let systemPorts = [22, 53, 67, 68, 123, 137, 138, 139, 445, 548, 631, 5353]

        if systemProcesses.contains(where: { processLower.contains($0) }) || systemPorts.contains(port) {
            return .system
        }

        return .other
    }
}

// MARK: - Port Info Model
struct PortInfo {
    let port: Int
    let pid: Int
    let process: String
    let command: String
    let user: String
    let category: PortCategory
    let framework: String?
    let dockerContainer: String?
    let dockerContainerID: String?
    let dockerContainerStatus: String?
    let isFavorite: Bool
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var ports: [PortInfo] = []
    var refreshTimer: Timer?
    var eventMonitor: Any?
    var favoritePorts: Set<Int> = []
    var selectedPortNumbers: Set<Int> = []  // Persist selections across view refreshes

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        loadFavorites()
        setupMenuBar()
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        refreshPorts()
        startAutoRefresh()
    }

    // MARK: - Favorites Management

    func loadFavorites() {
        if let saved = UserDefaults.standard.array(forKey: "FavoritePorts") as? [Int] {
            favoritePorts = Set(saved)
        }
    }

    func saveFavorites() {
        UserDefaults.standard.set(Array(favoritePorts), forKey: "FavoritePorts")
    }

    func toggleFavorite(port: Int) {
        if favoritePorts.contains(port) {
            favoritePorts.remove(port)
        } else {
            favoritePorts.insert(port)
        }
        saveFavorites()
        refreshPorts()
        updatePortListViewController()
    }

    func isFavorite(port: Int) -> Bool {
        return favoritePorts.contains(port)
    }

    // MARK: - Menu Bar Setup

    func setupMenuBar() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(NSMenuItem(title: "About Port Manager", action: #selector(showAbout), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Refresh", action: #selector(manualRefresh), keyEquivalent: "r"))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Port Manager", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        NSApplication.shared.mainMenu = mainMenu
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Port Manager"
        alert.informativeText = "A menu bar app to view and manage TCP ports.\n\nVersion 1.0\n\nFeatures:\n• View all listening TCP ports\n• Categorize ports by type\n• Kill processes with one click\n• Framework detection\n• Right-click to copy port info"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func manualRefresh() {
        refreshPorts()
        if popover.isShown {
            updatePortListViewController()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        refreshTimer?.invalidate()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Setup

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Network icon
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let image = NSImage(systemSymbolName: "network", accessibilityDescription: "Port Manager")
            button.image = image?.withSymbolConfiguration(config)
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    func setupPopover() {
        popover = NSPopover()
        // Create with empty ports initially
        popover.contentViewController = SimpleTestViewController()
        popover.behavior = .transient
        popover.animates = true
    }

    func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if self?.popover.isShown == true {
                self?.closePopover()
            }
        }
    }

    // MARK: - Popover Control

    @objc func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    func openPopover() {
        guard let button = statusItem.button else { return }

        // Refresh ports
        refreshPorts()

        // Create a fresh view controller with current ports and selections
        let viewController = StaticPortListViewController(ports: ports, selectedPorts: selectedPortNumbers)
        viewController.appDelegate = self
        popover.contentViewController = viewController

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func closePopover() {
        popover.performClose(nil)
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.refreshPorts()
            if self?.popover.isShown == true {
                self?.updatePortListViewController()
            }
        }
    }

    // MARK: - Port Detection

    func refreshPorts() {
        ports = getListeningPorts()
    }

    func getListeningPorts() -> [PortInfo] {
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-i", "-P", "-n", "-sTCP:LISTEN"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        var portDict: [Int: PortInfo] = [:]
        let lines = output.components(separatedBy: .newlines)

        for line in lines.dropFirst() {  // Skip header
            let parts = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard parts.count >= 9 else { continue }

            let processName = parts[0]
            guard let pid = Int(parts[1]) else { continue }
            let user = parts[2]
            let nameField = parts[8]

            // Extract port from format like "*:3000" or "127.0.0.1:3000" or "[::1]:3000"
            guard let colonIndex = nameField.lastIndex(of: ":"),
                  let port = Int(nameField[nameField.index(after: colonIndex)...]) else {
                continue
            }

            // Skip if we already have this port (deduplicate)
            if portDict[port] != nil { continue }

            let command = getCommandPath(pid: pid)
            let category = PortCategory.categorize(port: port, process: processName)
            let framework = detectFramework(command: command, process: processName)
            let dockerInfo = detectDockerContainer(pid: pid, command: command)
            let isFav = isFavorite(port: port)

            let portInfo = PortInfo(
                port: port,
                pid: pid,
                process: processName,
                command: command,
                user: user,
                category: category,
                framework: framework,
                dockerContainer: dockerInfo?.name,
                dockerContainerID: dockerInfo?.id,
                dockerContainerStatus: dockerInfo?.status,
                isFavorite: isFav
            )

            portDict[port] = portInfo
        }

        // Sort: favorites first, then by category, then by port number
        return portDict.values.sorted { a, b in
            // Favorites always come first
            if a.isFavorite != b.isFavorite {
                return a.isFavorite
            }
            // Then sort by category
            if a.category.sortOrder != b.category.sortOrder {
                return a.category.sortOrder < b.category.sortOrder
            }
            // Finally by port number
            return a.port < b.port
        }
    }

    func getCommandPath(pid: Int) -> String {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-p", String(pid), "-o", "command="]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return ""
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let command = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return command
    }

    func detectDockerContainer(pid: Int, command: String) -> (name: String?, id: String?, status: String?)? {
        // Check if this is docker-proxy (Docker port forwarding)
        if command.contains("docker-proxy") {
            // Extract container ID from docker-proxy command
            var containerID: String? = nil
            if let idRange = command.range(of: "-container-id ([a-f0-9]+)", options: .regularExpression) {
                let idMatch = String(command[idRange])
                if let id = idMatch.components(separatedBy: " ").last {
                    containerID = String(id.prefix(12))  // Short ID
                }
            }

            // Try to get container info from docker ps (including stopped containers)
            let task = Process()
            task.launchPath = "/bin/sh"
            // Use docker ps -a to include stopped containers
            task.arguments = ["-c", "docker ps -a --format '{{.Names}}|{{.ID}}|{{.Status}}' --filter id=\(containerID ?? "") 2>/dev/null | head -1"]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !output.isEmpty {
                    let parts = output.components(separatedBy: "|")
                    if parts.count >= 3 {
                        let name = parts[0]
                        let id = parts[1]
                        let status = parts[2]
                        return (name: name, id: id, status: status)
                    }
                }
            } catch {
                return nil
            }
        }

        return nil
    }

    func detectFramework(command: String, process: String) -> String? {
        let commandLower = command.lowercased()
        let processLower = process.lowercased()

        // Web Frameworks & Tools
        if commandLower.contains("next") || commandLower.contains("next dev") || commandLower.contains(".next") {
            return "Next.js"
        }
        if commandLower.contains("vite") {
            return "Vite"
        }
        if commandLower.contains("webpack") || commandLower.contains("webpack-dev-server") {
            return "Webpack"
        }
        if commandLower.contains("django") || commandLower.contains("manage.py") {
            return "Django"
        }
        if commandLower.contains("flask") {
            return "Flask"
        }
        if commandLower.contains("fastapi") || commandLower.contains("uvicorn") {
            return "FastAPI"
        }
        if commandLower.contains("rails") || commandLower.contains("puma") && processLower.contains("ruby") {
            return "Rails"
        }
        if commandLower.contains("express") && processLower.contains("node") {
            return "Express"
        }
        if commandLower.contains("react-scripts") {
            return "Create React App"
        }
        if commandLower.contains("nuxt") {
            return "Nuxt.js"
        }
        if commandLower.contains("gatsby") {
            return "Gatsby"
        }
        if commandLower.contains("remix") {
            return "Remix"
        }
        if commandLower.contains("svelte") || commandLower.contains("sveltekit") {
            return "SvelteKit"
        }
        if commandLower.contains("astro") {
            return "Astro"
        }

        // Backend Frameworks
        if commandLower.contains("spring") || commandLower.contains("spring-boot") {
            return "Spring Boot"
        }
        if commandLower.contains("laravel") {
            return "Laravel"
        }
        if commandLower.contains("symfony") {
            return "Symfony"
        }
        if commandLower.contains("gin") && processLower.contains("go") {
            return "Gin"
        }
        if commandLower.contains("echo") && processLower.contains("go") {
            return "Echo"
        }

        // Databases
        if processLower == "postgres" || processLower == "postgresql" {
            return "PostgreSQL"
        }
        if processLower == "mysql" || processLower == "mysqld" {
            return "MySQL"
        }
        if processLower == "mongod" || processLower == "mongodb" {
            return "MongoDB"
        }
        if processLower == "redis-server" || processLower == "redis" {
            return "Redis"
        }

        // Web Servers
        if processLower == "nginx" {
            return "Nginx"
        }
        if processLower == "apache" || processLower == "httpd" {
            return "Apache"
        }

        // Other tools
        if commandLower.contains("docker") {
            return "Docker"
        }
        if commandLower.contains("jupyter") {
            return "Jupyter"
        }
        if commandLower.contains("streamlit") {
            return "Streamlit"
        }

        return nil
    }

    // MARK: - Process Management

    func killProcess(_ portInfo: PortInfo, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.launchPath = "/bin/kill"
            task.arguments = ["-9", String(portInfo.pid)]

            do {
                try task.run()
                task.waitUntilExit()

                let success = task.terminationStatus == 0

                DispatchQueue.main.async {
                    if success {
                        // Refresh after short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.refreshPorts()
                            self.updatePortListViewController()
                        }
                    }
                    completion(success)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    func updatePortListViewController() {
        // For StaticPortListViewController, we need to recreate it with fresh data
        if popover.isShown {
            // Save current selections from existing view controller
            if let currentVC = popover.contentViewController as? StaticPortListViewController {
                selectedPortNumbers = currentVC.selectedPortNumbers
            }

            let viewController = StaticPortListViewController(ports: ports, selectedPorts: selectedPortNumbers)
            viewController.appDelegate = self
            popover.contentViewController = viewController
        }
    }
}

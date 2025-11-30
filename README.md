# Port Manager for macOS

A native macOS menu bar application for monitoring and managing TCP ports on your system.

## Features

- **Native macOS Design** - Clean, authentic macOS interface following Apple's Human Interface Guidelines
- **Smart Categorization** - Automatically groups ports into Web, Database, Cache, System, and Other categories
- **Quick Actions** - Kill processes, favorite ports, batch operations, custom commands
- **Keyboard Shortcuts** - ⌘K (kill), ⌘R (refresh), ⌘F (search), ⌘A (select all), ESC (clear)
- **Preferences** - Customize refresh interval, auto-refresh, and launch at login
- **Framework Detection** - Automatically detects Node.js, Python, Ruby, Go, Rust, and more
- **Docker Integration** - Shows Docker container names and allows container control
- **Search & Filter** - Quickly find ports by number, process name, or framework
- **Auto-Refresh** - Configurable refresh interval (default 2 seconds)
- **Performance Optimized** - Batch process scanning for faster updates
- **Menu Bar Only** - No Dock icon, stays out of your way
- **Dark Mode** - Full support for both light and dark appearance

## Quick Start

### Build and Run

```bash
# Clone or navigate to the project directory
cd port-manager

# Build and run
./build.sh --run
```

The app will appear in your menu bar with a network icon.

### Build Only

```bash
./build.sh
```

Then launch manually:
```bash
open PortManager.app
```

## Usage

1. Click the network icon in your menu bar
2. View all active TCP ports organized by category
3. Search/filter ports using the search field
4. Right-click any port for additional actions:
   - Kill Process
   - Copy Port Number / PID / Kill Command
   - Pin to Favorites
   - Docker controls (if applicable)
   - Framework-specific actions
   - Custom commands

### Batch Operations

- Click the checkbox on any port row to select it
- Select multiple ports
- Click "Kill Selected" to terminate all selected processes at once

### Favorites

- Click the star icon to pin frequently used ports to the top
- Favorited ports appear in a dedicated "Favorites" section

### Keyboard Shortcuts

- **⌘F** - Focus search field
- **⌘R** - Refresh ports manually
- **⌘K** - Kill selected ports
- **⌘A** - Select all ports
- **⌘,** - Open preferences
- **ESC** - Clear search or selection

## Categories

Ports are automatically categorized:

- **FAVORITES** - Your pinned ports
- **WEB & DEV SERVERS** - HTTP servers, dev servers (Node, Python, Ruby, etc.)
- **DATABASES** - PostgreSQL, MySQL, MongoDB, etc.
- **CACHE & QUEUES** - Redis, Memcached, RabbitMQ, Kafka
- **SYSTEM** - SSH, system services
- **OTHER** - Everything else

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode Command Line Tools (for building)

Install Command Line Tools if needed:
```bash
xcode-select --install
```

## Project Structure

```
port-manager/
├── PortManager/
│   ├── Sources/
│   │   ├── main.swift                           # Entry point
│   │   ├── AppDelegate.swift                    # Main app logic & port detection
│   │   ├── StaticPortListViewController.swift   # Main UI controller
│   │   └── PreferencesWindowController.swift    # Preferences window
│   └── Info.plist                               # App configuration
├── PortManager.app/                             # Built app (after build)
├── build.sh                                     # Build script
├── run-debug.sh                                 # Debug script
├── run-and-log.sh                               # Logging script
├── test-run.sh                                  # Test script
├── README.md                                    # This file
└── CHANGELOG.md                                 # Version history
```

## How It Works

Port Manager uses native macOS commands:

1. **Port Detection**: Runs `lsof -i -P -n -sTCP:LISTEN` to find listening TCP ports
2. **Process Info**: Uses `ps` to get full command details
3. **Docker Detection**: Checks if processes are running in Docker containers
4. **Framework Detection**: Analyzes command paths to identify frameworks
5. **Categorization**: Intelligently categorizes based on process name and port ranges

## Preferences

Access preferences via the menu bar: **Port Manager → Preferences...** or press **⌘,**

**Available Settings:**

- **Refresh Interval** - How often to scan for ports (0.5 - 60 seconds, default: 2)
- **Auto-Refresh** - Enable/disable automatic port scanning
- **Launch at Login** - Start Port Manager when you log in

## Customization

### Change Menu Bar Icon

Edit `AppDelegate.swift` and change the SF Symbol:
```swift
statusItem.button?.image = NSImage(systemSymbolName: "network", ...)
```

### Add Custom Commands

Right-click any port → **Add Custom Command** to create your own port-specific actions.

## Troubleshooting

### "App can't be opened because it is from an unidentified developer"

Right-click the app → **Open** → **Open** again in the dialog.

Or: System Settings → Privacy & Security → **Open Anyway**

### No Ports Showing

Start a test server:
```bash
python3 -m http.server 8000
```

The port should appear within 2 seconds.

### Can't Kill System Processes

Some processes require elevated privileges:
```bash
sudo kill -9 <PID>
```

### Build Errors

Ensure Xcode Command Line Tools are installed:
```bash
xcode-select --install
```

## Development

Pure Swift/AppKit application with zero external dependencies.

**Technologies:**
- AppKit for native macOS UI
- NSStatusItem for menu bar integration
- Swift for all logic
- Native shell command execution

**Architecture:**
- `AppDelegate` - Core app logic, port detection, categorization
- `StaticPortListViewController` - Main popover UI
- `PortInfo` - Port data model
- Custom commands stored in UserDefaults

## License

MIT License - Feel free to use, modify, and distribute.

## Version

**Current:** v1.7.0

See [CHANGELOG.md](CHANGELOG.md) for detailed version history and release notes.

---

**Made with Swift & AppKit**

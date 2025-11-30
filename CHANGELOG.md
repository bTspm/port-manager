# Changelog

All notable changes to Port Manager will be documented in this file.

## [1.5.0] - 2024-11-30

### Added
- ✨ Keyboard shortcuts for common actions
  - ⌘F - Focus search field
  - ⌘R - Refresh ports manually
  - ⌘K - Kill selected ports
  - ⌘A - Select all ports
  - ⌘, - Open preferences
  - ESC - Clear search or selection
- ⚙️ Preferences window
  - Customizable refresh interval (0.5-60 seconds)
  - Auto-refresh toggle
  - Launch at login option
- 🔄 Refresh button in UI header
- ⚙️ Preferences button (gear icon) in UI header

### Changed
- ⚡ Performance improvements with batch process scanning
  - Single `ps` call for all PIDs instead of one per process
  - Significantly faster port detection
- 🎨 Improved UI layout with better spacing
- 📝 Better error handling for process execution

### Removed
- 🧹 Cleaned up legacy view controllers
  - Removed 6 unused view controller files
  - Streamlined from 9 Swift files to 4
  - Reduced codebase by 44%

## [1.4.1] - Previous

### Features
- Native macOS design following Human Interface Guidelines
- Smart categorization (Web, Database, Cache, System, Other)
- Framework detection (Node.js, Python, Ruby, Go, Rust, etc.)
- Docker integration with container management
- Search and filter functionality
- Favorites system
- Batch operations
- Custom commands
- Right-click context menu
- Dark mode support

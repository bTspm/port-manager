# Changelog

All notable changes to Port Manager will be documented in this file.

## [1.7.0] - 2024-11-30

### Added
- 📋 Quick Copy Actions
  - One-click copy buttons for Port, PID, and Process name
  - Copy buttons appear on row hover with smooth fade-in animation (150ms)
  - Visual checkmark feedback when copied (green checkmark for 0.8s)
  - CopyButton component with animated icon transitions
  - No need for right-click menu to copy common values
  - Copy icons positioned next to each field for quick access
- 🔀 Sorting Options
  - Clickable column headers for PORT, PROCESS, PID, and USER
  - Visual sort indicators (▲ ▼) show active column and direction
  - Toggle ascending/descending by clicking same header
  - Persistent sort preferences saved in UserDefaults
  - Sorting maintained during search and filtering
  - Active sort column highlighted with darker color
  - Column header bar with subtle background
  - Support for sorting by port number, process name, PID, framework, and user

### Changed
- 🎯 Adjusted scroll view height to accommodate column headers (452px → 428px)
- 🖱️ Improved row interaction by using NSView for context menu instead of NSButton
- 📏 Optimized label widths for better spacing with copy buttons

### Fixed
- 🐛 Copy buttons now receive clicks properly
  - Changed clickArea from NSButton to NSView to prevent click interception
  - Removed overlapping button action that triggered "kill process" dialog
  - Right-click context menu still works correctly on rows

## [1.6.0] - 2024-11-30

### Added
- 🎨 Visual status indicators
  - Color-coded status dots on each port row by category (blue for web, purple for database, orange for cache, gray for system, green for other)
  - Highlighted backgrounds for selected ports with subtle hover effects
  - Framework badges with category-themed colors and rounded styling
  - Enhanced Docker badges with blue background and visual styling
  - Colored category icons in section headers with SF Symbols
  - Refined separator opacity for better visual hierarchy
- ✨ Smooth animations and transitions
  - Fade-in transitions when port list updates (200ms)
  - Hover effects on star and kill buttons that brighten on mouse over
  - Animated row backgrounds with mouse tracking (HoverBox component)
  - Refresh button rotation animation on click (360° spin)
  - Smooth fade-in/out for "Kill Selected" button visibility
  - Animated scrolling and view transitions (250ms easeInEaseOut)
- 🔧 Custom interactive components
  - HoverButton - animated buttons with hover state changes
  - HoverBox - animated row backgrounds with mouse enter/exit tracking

### Changed
- 🎯 Improved visual polish with native macOS UI patterns
- 🔄 Enhanced button and row interactivity with smooth animations
- 📊 Better visual feedback for user interactions

### Fixed
- 🐛 Scroll position now preserved during auto-refresh
  - Saves current scroll position before recreating view controller
  - Restores scroll position after auto-refresh completes
  - No more jumping to top when list refreshes with selections
- ⚠️ Replaced deprecated borderType with borderWidth property

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

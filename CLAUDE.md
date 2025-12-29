# QuickMic - Project Guide

## Project Overview

QuickMic is a macOS menubar utility for quick microphone input switching and audio/dictation service reset. Designed to solve dictation issues that occur after docking/undocking laptops.

**Architecture:** Single-file Swift app (`QuickMic.swift`) - intentionally simple and self-contained.

## Development Workflow

### Building
```bash
./build.sh
```
Creates `build/QuickMic.app`

### Testing
```bash
pkill -x QuickMic          # Kill running instance
./build.sh                  # Rebuild
open build/QuickMic.app     # Launch for testing
```

### Installing Locally
```bash
cp -r build/QuickMic.app /Applications/
```

## Release Process

1. **Make changes** and test thoroughly
2. **Commit and push** to main branch
3. **Create and push version tag:**
   ```bash
   git tag -a v1.x.x -m "Description of changes"
   git push origin v1.x.x
   ```
4. **GitHub Actions automatically:**
   - Builds the app on macOS runner
   - Creates GitHub Release
   - Attaches `QuickMic.app.zip` for download

Users download ready-to-use `.app` from Releases page - no building required.

## Technical Decisions

### macOS Version Support
- **Minimum:** macOS 11.0 (Big Sur)
- **Auto-start feature:** macOS 13.0+ only
  - Uses modern `SMAppService` API
  - Legacy `LSSharedFileList` APIs are deprecated and problematic
  - Graceful degradation: feature disabled on older macOS with notification

### Core Technologies
- **CoreAudio:** For enumerating and switching audio input devices
- **ServiceManagement:** For Login Items (auto-start) on macOS 13+
- **UserNotifications:** For user feedback (modern API, not deprecated NSUserNotification)

### Why Single File?
- Keeps project simple and maintainable
- Easy to understand entire codebase at once
- No need for complex project structure for this scope
- Follows self-documenting code principles

## Common Modifications

### Adding Menu Items
Add items in `setupMenu()` method. Use separators for logical grouping:
```swift
menu.addItem(NSMenuItem.separator())
menu.addItem(NSMenuItem(title: "New Feature", action: #selector(newAction), keyEquivalent: "n"))
```

### Adding Features
1. Add action method with `@objc` attribute
2. Add menu item in `setupMenu()`
3. Implement feature logic
4. Add notifications for user feedback
5. Update README.md

### Changing Icon
Update the SF Symbol in `applicationDidFinishLaunching`:
```swift
button.image = NSImage(systemSymbolName: "mic.fill", ...)
```

## Code Style

- Follow Martin Fowler self-documenting code principles (per global CLAUDE.md)
- Keep methods focused and readable
- Use clear, descriptive names
- Avoid over-engineering - this is intentionally simple

## Testing Checklist

Before releasing a new version, verify:
- [ ] Microphone switching works (test with multiple devices)
- [ ] Nuclear reset works (requires password, resets services)
- [ ] Auto-start toggle works (check System Settings → Login Items)
- [ ] First-launch prompt appears (reset UserDefaults to test)
- [ ] Notifications display correctly
- [ ] Menu refreshes properly (checkmarks update)
- [ ] App builds without warnings
- [ ] README updated if new features added

## Future Enhancement Ideas

- Keyboard shortcut for microphone switching
- Remember last selected device per dock state
- Audio device connect/disconnect notifications
- Custom icon per menu state
- Preferences window (if needed)

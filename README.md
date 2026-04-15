# Lock-In

<p align="center">
  <img src="Lock-In/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" alt="Context Switcher app icon" width="140" height="140">
</p>

**Focus Modes on steroids**

Context Switcher is a native macOS menu bar app for building reusable focus setups. A mode can launch your work apps, close distractions, open URLs, start a timer, and give you a clean way to move between different contexts during the day.

## Version 1.1

This release focuses on a calmer, more minimal interface and faster mode setup.

- New: duplicate an existing mode from the menu bar row menu
- Cleaner menu bar popover with compact rows and fewer always-visible controls
- Lighter mode editor with simpler surfaces and reduced visual noise
- App discovery warning cleaned up for newer Swift toolchains

## Highlights

- Native macOS menu bar experience built with SwiftUI and AppKit
- First-run onboarding flow for creating and customizing starter modes
- Installed-app picker instead of manual bundle ID entry
- Duplicate modes for faster setup
- Mode activation with app launch, app quit, URL open, timer, and notification support
- Reset flow that reopens onboarding from the menu bar
- Minimal dark interface for onboarding, mode editing, and quick switching

## Tech Stack

- Swift 5
- SwiftUI
- AppKit
- Xcode
- macOS 14+

## Project Structure

```text
Lock-In/
├── Config/
│   └── Info.plist
├── Lock-In/
│   ├── ActivationReport.swift
│   ├── AppCatalog.swift
│   ├── ContextSwitcher.entitlements
│   ├── ContextSwitcherApp.swift
│   ├── EditModeView.swift
│   ├── MenuBarView.swift
│   ├── Mode.swift
│   ├── ModeActivator.swift
│   ├── ModeStore.swift
│   ├── NotificationService.swift
│   └── OnboardingView.swift
├── Lock-In.xcodeproj
└── Lock-InTests/
```

## Build and Run

### Xcode

1. Open `Lock-In.xcodeproj` in Xcode.
2. Select the `Lock-In` scheme.
3. Choose `My Mac` as the run destination.
4. Build and run the app.

### Command Line

```bash
xcodebuild \
  -scheme Lock-In \
  -project Lock-In.xcodeproj \
  -configuration Debug \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## macOS Permissions

Context Switcher may request:

- Notifications permission for timer completion alerts
- Automation permission for quitting other apps on your behalf

If quitting apps does not work, open:

`System Settings > Privacy & Security > Automation`

## Current Features

- Create, edit, delete, and activate saved modes
- Launch selected installed apps
- Quit selected apps
- Open URLs in the default browser
- Start a timer per mode
- Show activation feedback in the menu bar UI
- Reopen onboarding after resetting settings

## GitHub

Repository: [https://github.com/zxather19/Lock-In](https://github.com/zxather19/Lock-In)

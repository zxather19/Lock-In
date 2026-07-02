# Lock-In

<p align="center">
  <img src="Lock-In/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" alt="Lock-In app icon" width="144" height="144">
</p>

<p align="center">
  <strong>Focus Modes on steroids</strong>
</p>

Lock-In is a native macOS menu bar app that saves workspace modes for different contexts. A mode can launch apps, close distractions, open URLs, start a timer, respond to a global shortcut, and optionally run on a schedule.

## Highlights

- Native menu bar experience built with SwiftUI and AppKit
- Installed-app picker, no manual bundle IDs required
- Global shortcuts for one-tap mode activation
- Time-and-weekday scheduling
- Session history in the menu bar
- File-backed local persistence in `Application Support`

## Build Requirements

- macOS 14 or later
- Xcode 16 or later
- Swift 5

## Build

```bash
xcodebuild \
  -scheme Lock-In \
  -project Lock-In.xcodeproj \
  -configuration Debug \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Test

```bash
xcodebuild \
  -scheme Lock-In \
  -project Lock-In.xcodeproj \
  -configuration Debug \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:Lock-InTests \
  test
```

## Permissions

Lock-In may request:

- Notifications for timer and schedule events
- Automation for quitting other apps
- Login Items if the user enables launch at startup

## Project Structure

```text
Lock-In/
├── .github/workflows/build.yml
├── Config/Info.plist
├── CONTRIBUTING.md
├── Lock-In/
│   ├── AppCatalog.swift
│   ├── AppLaunchService.swift
│   ├── AppQuitService.swift
│   ├── EditModeView.swift
│   ├── LockInApp.swift
│   ├── MenuBarView.swift
│   ├── Mode.swift
│   ├── ModeActivator.swift
│   ├── ModeStore.swift
│   ├── ModeTemplate.swift
│   ├── Schedule.swift
│   ├── ScheduleService.swift
│   ├── SessionStore.swift
│   ├── ShortcutService.swift
│   ├── TimerService.swift
│   └── URLOpenService.swift
└── Lock-InTests/
```

## Repository

[zxather19/Lock-In](https://github.com/zxather19/Lock-In)

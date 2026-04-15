# Lock-In

<p align="center">
  <img src="Lock-In/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" alt="Lock-In app icon" width="144" height="144">
</p>

<p align="center">
  <strong>Focus Modes in steroids</strong>
</p>

Lock-In is a native macOS menu bar app for switching your whole workspace into a saved context. A mode can launch apps, close distractions, open URLs, start a timer, and play an optional cue so you can move from deep work to class to break mode without rebuilding your setup by hand.

## Version 2.0

Version 2.0 is a visual and usability release focused on making every window feel polished, minimal, and consistent.

- New shared dark glass design system across onboarding, menu bar, edit mode, help, and app picker windows
- Cleaner menu bar popover with compact mode rows, visible Change action, duplicate support, reset, startup toggle, and activation feedback
- Redesigned mode editor with calmer sections, pastel accents, app cards, and clearer save/cancel actions
- Redesigned installed-app picker so users choose apps visually instead of entering bundle IDs
- Redesigned help window with beta checklist, permission guidance, and startup notes
- Updated onboarding flow with the same v2 aesthetic and smoother progressive animation

## Download

Download the latest macOS build from the GitHub Releases page:

[https://github.com/zxather19/Lock-In/releases](https://github.com/zxather19/Lock-In/releases)

The release build is currently unsigned. On first launch, macOS may require you to open it from `System Settings > Privacy & Security` or right-click the app and choose `Open`.

## Features

- Create, edit, delete, duplicate, and activate saved modes
- Launch selected installed apps
- Quit selected distraction apps
- Open URLs in the default browser
- Start a timer per mode and receive a notification when it ends
- Play a sound when a mode activates
- Run at login from the menu bar toggle
- Reset settings and reopen onboarding
- First-run onboarding with visual app selection

## Screens

- Menu bar popover for fast mode switching
- Onboarding window for first-run setup
- Mode editor for app, URL, timer, color, and sound customization
- Installed-app picker for selecting apps without bundle IDs
- Help window for permissions and beta-testing checks

## Build Requirements

- macOS 14 or later
- Xcode
- Swift 5

## Build and Run

### Xcode

1. Open `Lock-In.xcodeproj`.
2. Select the `Lock-In` scheme.
3. Choose `My Mac` as the destination.
4. Build and run.

### Command Line

```bash
xcodebuild \
  -project Lock-In.xcodeproj \
  -target Lock-In \
  -configuration Debug \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

### Release Build

```bash
xcodebuild \
  -project Lock-In.xcodeproj \
  -target Lock-In \
  -configuration Release \
  CONFIGURATION_BUILD_DIR="$PWD/.build/Release-2.0" \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## macOS Permissions

Lock-In may request these permissions during real use:

- Notifications: used for timer completion alerts
- Automation: used when a mode quits another app
- Login Items: used if you enable Open at login

If quitting apps does not work, open `System Settings > Privacy & Security > Automation` and allow Lock-In to control the relevant apps.

## Project Structure

```text
Lock-In/
├── Config/
│   └── Info.plist
├── Lock-In/
│   ├── AppCatalog.swift
│   ├── ContextSwitcherApp.swift
│   ├── EditModeView.swift
│   ├── LaunchAtLoginManager.swift
│   ├── LockInDesign.swift
│   ├── MenuBarView.swift
│   ├── Mode.swift
│   ├── ModeActivator.swift
│   ├── ModeStore.swift
│   ├── NotificationService.swift
│   └── OnboardingView.swift
├── Lock-InTests/
├── Lock-InUITests/
└── Lock-In.xcodeproj
```

## Beta Testing Checklist

- Create a new mode from the menu bar plus button
- Change an existing mode from the visible Change action
- Duplicate a mode from the row menu
- Launch a mode that opens apps and URLs
- Launch a mode that quits at least one app after Automation permission is granted
- Confirm timer notifications appear
- Toggle Open at login and verify the setting persists
- Reset settings and confirm onboarding opens again

## Repository

[https://github.com/zxather19/Lock-In](https://github.com/zxather19/Lock-In)

# Meimoire

Meimoire is a native macOS app for keeping private everyday information in one calm local workspace: accounts, passwords, inspirations, notes, and useful URLs.

The app is French-first, Mac-first, and built with SwiftUI, SwiftData, Apple Keychain, and LocalAuthentication.

![Meimoire logo](Assets/Logo/meimoire-logo.png)

## Features

- **Accounts and passwords**: save service name, username, URL, notes, category, and secret.
- **Keychain-only secrets**: passwords are stored in Apple Keychain; SwiftData stores only a stable secret reference.
- **Local unlock**: reveal and copy password actions require Touch ID or the macOS password fallback.
- **Account categories**: Travail, Social, E-mail, Banque, Achats, Développement, Cloud, Abonnements, Jeux, Autres.
- **Collapsible account groups**: account lists can be expanded or folded by category.
- **Username copy**: copy usernames from account rows with quick feedback.
- **Inspiration workspace**: write Markdown documents with a native editor, live preview, outline, templates, search, stats, and autosave.
- **URL library**: store links with notes, tags, search, and browser opening.
- **Built-in skins**: Meimoire Ink, Meimoire Paper, Mint Vault, and Coral Notes.
- **Local-first search**: search across titles, usernames, URLs, notes, tags, and account category names.

## Screens

Meimoire uses a three-pane macOS layout:

- Sidebar: all items, item types, account categories, and tags.
- List: searchable items or collapsible account category groups.
- Detail: account security panel, URL details, or the inspiration document workspace.

## Installation

Download the latest `Meimoire.dmg` from the GitHub Releases page, open it, and drag `Meimoire.app` into Applications.

Because this MVP is not distributed through the Mac App Store, macOS Gatekeeper may ask you to confirm before opening it.

## Development

Requirements:

- macOS 14+
- Xcode 16+ or a complete Xcode toolchain
- Swift Package Manager

Run tests:

```bash
swift test
```

Run the app:

```bash
swift run Meimoire
```

If the active developer directory points to Command Line Tools while full Xcode is installed at `/Applications/Dev/Xcode.app`, use:

```bash
DEVELOPER_DIR=/Applications/Dev/Xcode.app/Contents/Developer swift test
DEVELOPER_DIR=/Applications/Dev/Xcode.app/Contents/Developer swift run Meimoire
```

## Packaging

Build the release app and create a DMG:

```bash
Scripts/package-dmg.sh
```

Verify the generated image:

```bash
hdiutil verify dist/Meimoire.dmg
```

Generated artifact:

```text
dist/Meimoire.dmg
```

## Privacy And Security

- Password values are never saved in SwiftData.
- Password values are not logged or used in UI previews.
- Account metadata, inspirations, URLs, tags, and timestamps are stored locally with SwiftData.
- Password reveal and copy actions require local authentication.
- Synchronizable Keychain storage depends on Apple signing and iCloud Keychain capabilities. Without those capabilities, the app continues to work with the local Keychain.

## Current Scope

Included in this MVP:

- Native macOS app
- Local account/password storage
- Inspiration document writing
- URL storage
- Built-in skins
- DMG packaging

Not included yet:

- Safari autofill integration
- Browser extensions
- Shared vaults
- iPhone/iPad clients
- Real `.docx` editing
- Custom skin import/export

## License

No license has been selected yet. Add a license before public redistribution if this repository will be open source.

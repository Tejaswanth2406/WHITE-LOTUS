# White Lotus

White Lotus is a cross-platform personal command ecosystem built around a local-first, offline-capable workflow. The first milestone focuses on a polished Windows desktop shell with a working local Vault and clear separation between UI, domain logic, and future cloud integrations.

## Repository structure

- `app/white-lotus` — Flutter desktop application
- `docs/` — architecture and product decision records
- `linux-os/` — future Linux environment integration boundary

## Local setup

1. Install Flutter and ensure `flutter` is on PATH.
2. From the repo root, run:

```bash
cd app/white-lotus
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

## Current milestone

The app includes:

- Liquid-glass dashboard with organized file, image, voice, notes, map, and
  quick-action widgets; the dashboard focuses on workspace content rather than
  clock or weather cards
- A local Screenshots gallery for importing and keeping image screenshots
- A local file workspace with folders, image and text previews, rename, and
  recoverable Trash; import images, audio, common documents, or any file.
  The Images view uses a spring-animated reel backed by locally stored image
  bytes
- The Home vault, screenshots, audio, and offline-map panels reflect actual
  local storage instead of sample content; the Files navigation opens the
  same working file manager as Vault
- Offline Maps support for importing raster MBTiles region packages and placing
  multiple pins
- Black, burgundy, and navy blue appearance choices in Settings
- A curved, scrollable OptionWheel for selecting the liquid-glass colorway
- An ElasticSlider control for adjusting contrast on custom wallpapers
- An optional GridMotion collage of screenshots imported into local storage;
  the motion view uses local image bytes and does not fetch remote content
- A Settings wallpaper picker for images saved on the device, including
  downloaded images
- Local-first architecture boundary for future sync and cloud services
- Preview screens for features that still need real service integrations

Image wallpapers are applied for the current app session. Persistent wallpaper
storage and an in-app browser download flow are not implemented yet.
On desktop/mobile, screenshots and offline map packages are saved in the app's
local support directory; screenshots are not encrypted or synced. In the web
preview, imported screenshots and workspace files last only for the current
session. Workspace files are stored separately from the user's original files;
imports are copied into the app's local support directory. Moving items to
Trash preserves them for restore until they are permanently deleted. Image
files and common text formats can be previewed in the app. Audio files can be
imported and organized locally; voice recording and in-app audio playback are
not included yet. Vault files are app-local but are not password-encrypted yet.
Offline maps must be obtained from a provider that permits offline use. The
current map viewer supports raster MBTiles (PNG, JPG, or WebP) in desktop/mobile
builds; vector MBTiles and the web preview are not supported.

## Design principles

- No cloud dependency in the domain layer
- Offline function must work without network access
- Local storage and file operations remain explicit and testable
- Sync is treated as an abstraction, not a fake implementation

# Papuy

A simple, dependency-free video and music player for Android.

- Library from MediaStore with folders, search, sorting, favorites and continue watching
- Media3 player on a Flutter texture: gestures, speed, A-B repeat, sleep timer, audio and subtitle tracks, external .srt, aspect ratios, screenshots
- Floating window (picture in picture), background playback, network streams (http, https, rtsp, HLS, DASH)
- Music: songs, albums and artists from MediaStore, album art, queue, shuffle, repeat, speed, sleep timer, mini player, notification controls, keeps playing with the screen off
- Visualizer: live spectrum bars on the now playing screen (computed natively from the decoded audio, no extra permission), can be turned off in Settings
- Notification: media-session controls with seek bar, previous, play/pause, next, shuffle and repeat
- Playlists: create, import from .m3u/.m3u8, rename, delete, reorder, add from any track; favorites, recently played, most played, recently added, sort options, restore last queue
- Languages: English, Persian (RTL), Japanese, Russian
- Opens videos and audio from other apps through "Open with"

## Run

```
flutter pub get
flutter run
```

The main manifest keeps a launcher entry on `MainActivity` because `flutter run` reads it to know which activity to start. The debug, profile and release manifests remove that entry when merging, so the installed app only shows the theme-switching icon.

## Release

```
bash scripts/bump_version.sh 1.1.0
git commit -am "Release 1.1.0" && git push
```

Installed copies find the new version through the `VERSION` file on `main`.

## Structure

```
lib/library/     videos, watch history, favorites, LibraryController
lib/player/      PlayerController, track and subtitle models
lib/platform/    channel wrappers: player, media, window, system
android/.../     PlayerChannel, MediaChannel, WindowChannel, PlaybackService
```

## Icons and fonts

The launcher and logo PNGs are generated from `assets/icons/icon_mocha.svg` and `icon_latte.svg`.

See the flutter-base README for the structure and the conventions this project follows.

## Quick play

Videos and audio opened from other apps play in a small floating window over the current app, without opening the full UI. "Open app" hands the playback over to the full app. The window can be turned off in Settings > Quick play. Android has no setting for choosing a default video player, so pick Papuy in the system "Open with" dialog and tap Always.

## CI

`.github/workflows/release.yml` checks that `VERSION`, `pubspec.yaml` and `app_info.dart` agree, runs `flutter analyze`, builds universal and per-ABI APKs, signs them, and publishes a GitHub release named `v<VERSION>` on every push to `main`. Add the secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD` to the repository.

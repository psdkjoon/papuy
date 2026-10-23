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

The app is Android only.

## Launcher icons and accent

There is one launcher icon per accent and theme (12 accents x Mocha and Latte), switched by `LauncherIcon.kt` from the accent and theme chosen in Settings. With "Sync theme" on, the accent and theme are shared with other apps built from the same template on the same phone.

## Home screen widgets

Four widgets: square, bar, wide and a button-only one. They show the current song, album art and the play, previous and next buttons. Pressing play on a Bluetooth device starts the song that was playing before, even if the app was closed.

## Playlists

Create, import from .m3u/.m3u8, export to Downloads or share as .m3u8, rename, delete and reorder.

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

## Quick play

Videos and audio opened from other apps play in a small floating window over the current app, without opening the full UI. "Open app" hands the playback over to the full app. The window can be turned off in Settings > Quick play. Android has no setting for choosing a default video player, so pick Papuy in the system "Open with" dialog and tap Always.

## CI

`.github/workflows/release.yml` checks that `VERSION`, `pubspec.yaml` and `app_info.dart` agree, runs `flutter analyze`, builds universal and per-ABI APKs, signs them, and publishes a GitHub release named `v<VERSION>` on every push to `main`. Add the secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD` to the repository.

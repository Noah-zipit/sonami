<p align="center">
  <img src="assets/sonami-icon-master.webp" width="128" alt="Sonami logo" />
</p>

<h1 align="center">Sonami</h1>

<p align="center"><em>Free, no-ads manga & manhwa reader for Android.</em></p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/Release-v1.1.0-FF6B35" alt="Release" />
</p>

**Sonami** is the native Android client for [Sonami Dex](https://sonami-dex-proto.vercel.app) — a free manga/manhwa reading experience with library tracking, reading stats, and zero ads. Chapter content is served through the Sonami Dex backend; cover art loads from MangaDex's CDN.

## ✨ Features

- **Browse & search** — discover manga, manhwa, and comics with full search
- **Reader** — clean chapter reading with progress autosave and resume
- **Library** — shelves to track what you're reading
- **Reading stats** — your habits, visualised
- **Detail pages** — full title info with cover art
- **About** — everything about the project in-app

## 📲 Install

Grab the APK from the [**latest release**](https://github.com/Noah-zipit/sonami/releases/latest):

| APK | For |
|---|---|
| `sonami-release-arm64.apk` | Most modern phones (recommended) |
| `sonami-universal.apk` | All architectures (larger download) |

Enable *Install unknown apps* for your browser when prompted, then open the APK.

Prefer the web? The full web app lives at [sonami-dex-proto.vercel.app](https://sonami-dex-proto.vercel.app).

## 🛠 Build from source

```bash
flutter pub get
flutter analyze
flutter build apk --split-per-abi   # per-architecture APKs in build/app/outputs/flutter-apk/
```

Requires Flutter 3.47+.

---

Built by [Ashar Qaisar](https://github.com/Noah-zipit). Please support the scanlation groups and official releases of the series you love.

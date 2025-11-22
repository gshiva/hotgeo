# 🗺️ HotGeo - Daily Geography Challenge Game

> A beautiful daily geography guessing game with Indiana Jones vibes.
> Open source, cross-platform (Web, Android, iOS), and built with Flutter.

[![Play Now](https://img.shields.io/badge/Play-Web-blue?style=for-the-badge)](https://hotgeo-2025.web.app)
[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

![HotGeo Preview](assets/preview.png)
*Find mystery locations on a vintage map with hot/cold hints*

---

## 🎮 How to Play

1. **Each day, discover a new mystery location**
2. **Tap anywhere on the map** to make a guess
3. **Get hot/cold feedback** based on distance (🔥 = close, ❄️ = far)
4. **After 3 attempts**, receive directional hints (⬆️ North, ↗️ Northeast, etc.)
5. **Find the location in 6 attempts or less!**

---

## ✨ Features

- 🌍 **Daily geography challenges** - New location every day
- 🔥 **Hot/cold feedback system** - Temperature-based distance hints
- 🧭 **Progressive directional hints** - Get compass directions after 3 tries
- 📤 **Share results** - Emoji grid like Wordle
- 📊 **Track your streak** - Sign in to sync across devices
- 🎨 **Beautiful Indiana Jones aesthetic** - Vintage maps and parchment design
- 🌐 **Cross-platform** - Play on web, Android, or iOS
- 🔓 **100% Open Source** - MIT License, contribute freely

---

## 🚀 Play Now

- 🌐 **Web:** [hotgeo.web.app](https://hotgeo-2025.web.app) *(No install needed!)*
- 🤖 **Android:** Coming soon to Google Play
- 🍎 **iOS:** Coming soon to App Store

---

## 🛠️ Built With

- **[Flutter](https://flutter.dev)** - Cross-platform UI framework
- **[flutter_map](https://pub.dev/packages/flutter_map)** - Interactive maps powered by OpenStreetMap
- **[Firebase](https://firebase.google.com)** - Authentication & cloud sync
- **[OpenStreetMap](https://www.openstreetmap.org)** - Free map tiles

---

## 💻 Development Setup

### Prerequisites
- Flutter 3.24+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Dart 3.5+
- Chrome (for web development)
- Android Studio / Xcode (for mobile)

### Quick Start

```bash
# Clone repository
git clone https://github.com/yourusername/hotgeo.git
cd hotgeo

# Install dependencies
flutter pub get

# Run on Web (fastest for development)
flutter run -d chrome

# Run on Android
flutter run

# Run on iOS (macOS only)
flutter run
```

### Build for Production

```bash
# Web
flutter build web --release

# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

---

## 🤝 Contributing

We love contributions! HotGeo is open source and welcomes developers of all skill levels.

### Ways to Contribute

- 🐛 **[Report bugs](https://github.com/yourusername/hotgeo/issues/new?template=bug_report.md)**
- 💡 **[Suggest features](https://github.com/yourusername/hotgeo/issues/new?template=feature_request.md)**
- 🌍 **[Add challenges](docs/ADDING_CHALLENGES.md)** - Submit interesting locations
- 🌐 **[Translate](docs/CONTRIBUTING.md#translations)** - Add your language
- 💻 **[Code](https://github.com/yourusername/hotgeo/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)** - Pick up a good first issue

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for detailed guidelines.

---

## 🗺️ Project Structure

```
hotgeo/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models (GameState, Challenge, etc.)
│   ├── services/              # Business logic (Auth, Sync, Distance calc)
│   ├── screens/               # UI screens (Game, Results, Settings)
│   ├── widgets/               # Reusable UI components
│   └── theme/                 # Colors, fonts, styles
├── web/                       # Web-specific files
├── android/                   # Android platform files
├── ios/                       # iOS platform files
├── test/                      # Unit & widget tests
└── docs/                      # Documentation
```

---

## 📜 License

MIT License - Copyright (c) 2025 HotGeo Contributors

See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- **OpenStreetMap contributors** - For free, open map data
- **Flutter community** - For amazing framework and packages
- **All contributors** - Thank you for making HotGeo better!

---

## 📈 Roadmap

- [x] Web prototype with core gameplay
- [x] Hot/cold feedback system
- [x] Daily challenges
- [ ] Firebase authentication
- [ ] Cloud sync across devices
- [ ] Android app (Google Play)
- [ ] iOS app (App Store)
- [ ] Achievement badges
- [ ] Leaderboards
- [ ] Custom challenge creator
- [ ] Multiple difficulty modes
- [ ] Internationalization (i18n)

---

## 💬 Community

- **Discussions:** [GitHub Discussions](https://github.com/yourusername/hotgeo/discussions)
- **Issues:** [GitHub Issues](https://github.com/yourusername/hotgeo/issues)
- **Twitter:** [@HotGeoGame](https://twitter.com/HotGeoGame) *(coming soon)*

---

## ⭐ Star History

If you like HotGeo, give us a star! ⭐

[![Star History Chart](https://api.star-history.com/svg?repos=yourusername/hotgeo&type=Date)](https://star-history.com/#yourusername/hotgeo&Date)

---

**Made with ❤️ by geography lovers, for geography lovers**

**Play daily at [hotgeo.web.app](https://hotgeo-2025.web.app)** 🗺️🔥

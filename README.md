# 🗺️ HotGeo - Quick Geography Challenge Game

> A fast-paced geography guessing game perfect for quick breaks and "stimming" while coding.
> Unlimited play, instant restarts, with Indiana Jones vibes. Open source and built with Flutter.

[![Play Now](https://img.shields.io/badge/Play-Web-blue?style=for-the-badge)](https://hotgeo-2025.web.app)
[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

![HotGeo Preview](assets/preview.png)
*Find mystery locations on a vintage map with hot/cold hints*

---

## 🎮 How to Play

1. **Get a random mystery location** - New challenge every round
2. **Tap anywhere on the map** to make a guess
3. **Get hot/cold feedback** based on distance (🔥 = close, ❄️ = far)
4. **Find the location in 6 attempts or less!**
5. **Hit "Play Again"** for instant next challenge - unlimited rounds!

---

## ✨ Features

- ⚡ **Unlimited instant play** - Perfect for quick breaks, waiting for builds, or "stimming"
- 🔄 **Instant restarts** - Hit "Play Again" for immediate next challenge
- 🔥 **Hot/cold feedback system** - Temperature-based distance hints
- 🎯 **Varied difficulty levels** - Easy, medium, and hard locations mixed randomly
- 📤 **Share results** - Emoji grid like Wordle with native mobile share sheet
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

### System Requirements

- **macOS:** 10.15 (Catalina) or later
- **Windows:** Windows 10 or later (64-bit)
- **Linux:** Ubuntu 20.04+ or equivalent
- **Disk Space:** 2.8 GB (not including IDE/tools)
- **RAM:** 4 GB minimum, 8 GB recommended

### Step 1: Install Flutter

#### macOS

**Option A: Homebrew (Recommended)**
```bash
# Install Flutter via Homebrew
brew install --cask flutter

# Add Flutter to PATH (if not auto-added)
echo 'export PATH="$PATH:/opt/homebrew/Caskroom/flutter/latest/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

**Option B: Manual Installation**
```bash
# Download Flutter SDK
cd ~/development
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.24.0-stable.zip
unzip flutter_macos_3.24.0-stable.zip

# Add to PATH
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

#### Windows

```powershell
# Using Chocolatey
choco install flutter

# Or download manually from:
# https://docs.flutter.dev/get-started/install/windows
```

#### Linux

```bash
# Download and extract Flutter
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
tar xf flutter_linux_3.24.0-stable.tar.xz

# Add to PATH
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Step 2: Verify Installation

```bash
# Check Flutter installation
flutter doctor

# You should see output like:
# ✓ Flutter (Channel stable, 3.24.0)
# ✓ Chrome - for web development
# ...
```

**Resolve any issues shown by `flutter doctor`:**

- **Chrome not found?** [Install Chrome](https://www.google.com/chrome/)
- **Android toolchain missing?** [Install Android Studio](https://developer.android.com/studio)
- **Xcode missing? (macOS only)** Install from Mac App Store

### Step 3: Clone Repository

```bash
# Clone HotGeo repository
git clone https://github.com/gshiva/hotgeo.git
cd hotgeo
```

### Step 4: Install Dependencies

```bash
# Install all Flutter packages
flutter pub get

# Verify no issues
flutter pub outdated
```

### Step 5: Run the App

#### Web (Fastest for Development)

```bash
# Run in Chrome
flutter run -d chrome

# Or specify port
flutter run -d chrome --web-port=3000

# Open browser to: http://localhost:3000
```

#### Android

```bash
# Connect Android device via USB or start emulator
flutter devices

# Run on connected device
flutter run

# Or specify device
flutter run -d <device-id>
```

#### iOS (macOS only)

```bash
# Open iOS simulator
open -a Simulator

# Run on simulator
flutter run

# Or run on physical device
flutter run -d <device-id>
```

### Hot Reload

Flutter supports **hot reload** for instant code updates:

- **Press `r`** in terminal to hot reload
- **Press `R`** in terminal to hot restart
- **Press `q`** to quit

### Recommended IDEs

**VS Code (Recommended)**
```bash
# Install VS Code
brew install --cask visual-studio-code

# Install Flutter extension
code --install-extension Dart-Code.flutter
```

**Android Studio**
- Download from [developer.android.com](https://developer.android.com/studio)
- Install Flutter/Dart plugins

### Build for Production

```bash
# Web (optimized build)
flutter build web --release --web-renderer canvaskit

# Output: build/web/

# Android APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk

# iOS (macOS only)
flutter build ios --release

# Output: build/ios/iphoneos/Runner.app
```

### Troubleshooting

#### "flutter: command not found"
```bash
# Verify Flutter is in PATH
echo $PATH | grep flutter

# If not found, add to ~/.zshrc or ~/.bashrc:
export PATH="$PATH:[PATH_TO_FLUTTER_DIRECTORY]/flutter/bin"

# Then reload:
source ~/.zshrc
```

#### "Chrome not found"
```bash
# macOS
brew install --cask google-chrome

# Or download from google.com/chrome
```

#### "No connected devices"
```bash
# List available devices
flutter devices

# For web, ensure Chrome is installed
# For Android, enable USB debugging on device
# For iOS, trust computer on device
```

#### Dependency conflicts
```bash
# Clean and reinstall
flutter clean
flutter pub get

# Clear pub cache if needed
flutter pub cache repair
```

### Development Workflow

1. **Make changes** to code in `lib/`
2. **Save file** - hot reload triggers automatically
3. **Test** in browser/device
4. **Commit changes** with clear messages
5. **Push** to your fork
6. **Create PR** to main repository

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/distance_calculator_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Additional Resources

- **Flutter Docs:** [docs.flutter.dev](https://docs.flutter.dev)
- **flutter_map Docs:** [docs.fleaflet.dev](https://docs.fleaflet.dev)
- **Firebase Setup:** [firebase.google.com/docs/flutter](https://firebase.google.com/docs/flutter)
- **HotGeo Full Dev Plan:** [HOTGEO_DEVELOPMENT_PLAN.md](HOTGEO_DEVELOPMENT_PLAN.md)
- **2-Hour Sprint Plan:** [2_HOUR_WEB_PROTOTYPE_PLAN.md](2_HOUR_WEB_PROTOTYPE_PLAN.md)

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
- [x] Unlimited play mode
- [x] Web Share API integration
- [ ] Leaderboards (global & friends)
- [ ] Personal best tracking
- [ ] Achievement badges
- [ ] Session stats (rounds played, success rate)
- [ ] Android app (Google Play)
- [ ] iOS app (App Store)
- [ ] Custom challenge creator
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

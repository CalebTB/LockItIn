# LockItIn - Privacy-First Group Calendar App

A cross-platform mobile app (iOS & Android) for group event planning with privacy-first availability sharing.

## 🚀 Quick Start

### Prerequisites
- ✅ Flutter SDK 3.10.3+
- ✅ Android Studio (for Android development)
- ✅ Xcode (for iOS development - Mac only)
- ✅ Supabase account (free tier)

### Setup (5 minutes)

**1. Install dependencies:**
```bash
cd application/lockitin_app
flutter pub get
```

**2. Configure Supabase:**

Create a free Supabase project at [app.supabase.com](https://app.supabase.com/)

Then update your credentials in:
```dart
// lib/core/config/supabase_config.dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
```

📖 See `SUPABASE_SETUP.md` for detailed instructions.

**3. Run the app:**
```bash
flutter run
```

Select your Android emulator or iOS simulator.

---

## 📁 Project Structure

```
lib/
├── core/           # Infrastructure (config, network, storage)
├── data/           # Data layer (models, repositories)
├── domain/         # Business logic layer
└── presentation/   # UI layer (screens, widgets, providers)
```

📖 See `PROJECT_STRUCTURE.md` for complete details.

---

## 🛠️ Development Roadmap

Development follows GitHub issues in this repository.

### Sprint 1: Authentication & Calendar (2 weeks)
- Days 1-2: Project setup, authentication
- Days 3-7: Calendar view, native calendar sync
- Days 8-14: Event CRUD, privacy settings

### Sprint 2: Groups & Shadow Calendar (2 weeks)
- Days 15-16: Friend system
- Days 17-21: Groups
- Days 22-28: Shadow calendar, availability heatmap

### Sprint 3: Event Proposals & Voting (2 weeks)
- Days 29-35: Event proposals, voting system
- Days 36-42: Real-time updates, notifications

**Target Launch:** April 30, 2026

---

## 🏗️ Tech Stack

### Frontend (Cross-Platform)
- **Flutter 3.16+** - UI framework
- **Dart 3.0+** - Programming language
- **Provider** - State management
- **Material & Cupertino** - Platform-native widgets

### Backend
- **Supabase** - PostgreSQL database, auth, real-time
- **Row Level Security (RLS)** - Privacy enforcement at DB level

### Platform Integration
- **iOS**: EventKit (calendar access via platform channels)
- **Android**: CalendarContract (calendar access via platform channels)
- **Push Notifications**: FCM (Android) + APNs (iOS)

---

## 🔐 Core Features

### 1. Shadow Calendar System
Users control what groups see:
- **Private**: Hidden from all groups
- **Shared with Name**: Groups see event title & time
- **Busy Only**: Groups see "busy" block without details

### 2. Group Availability Heatmap
Visual calendar showing when group members are free (without revealing private event details).

### 3. Real-Time Event Proposals & Voting
- Propose multiple time options
- Group members vote (Yes/No/Maybe)
- Auto-create event when voting concludes

### 4. Smart Time Suggestions
Algorithm suggests optimal meeting times based on group availability.

---

## 📱 Platform Support

- **iOS**: 13.0+
- **Android**: 8.0+ (API 26+)

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/providers/auth_provider_test.dart
```

---

## 🚀 Building for Release

### Android
```bash
flutter build apk --release              # APK file
flutter build appbundle --release        # Google Play bundle
```

### iOS (requires Mac)
```bash
flutter build ios --release
flutter build ipa --release              # For TestFlight/App Store
```

---

## 📖 Documentation

- **[SUPABASE_SETUP.md](SUPABASE_SETUP.md)** - Step-by-step Supabase configuration
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Complete project structure
- **[FLUTTER_SUPABASE_INTEGRATION_GUIDE.md](../../../FLUTTER_SUPABASE_INTEGRATION_GUIDE.md)** - Integration patterns
- **[GitHub Issues](https://github.com/CalebTB/LockItIn/issues)** - Development tasks

---

## 🐛 Troubleshooting

### "Failed to initialize Supabase"
- ✅ Check `lib/core/config/supabase_config.dart` has correct credentials
- ✅ Verify Supabase project is active
- ✅ Check internet connection

### Flutter build errors
```bash
flutter clean
flutter pub get
flutter run
```

### Android emulator issues
- ✅ Ensure emulator has internet access
- ✅ Try restarting the emulator
- ✅ Check Android SDK is installed

---

## 📝 Development Workflow

1. **Pick an issue** from GitHub (start with #2 for Day 1)
2. **Create a branch**: `git checkout -b day-1-setup`
3. **Build the feature** following the issue checklist
4. **Test thoroughly** on Android emulator
5. **Commit**: `git commit -m "Day 1: Set up MVVM architecture"`
6. **Push**: `git push origin day-1-setup`

---

## 🎯 Current Status

**Phase**: Pre-development (Planning complete, starting implementation)
**Next**: Sprint 1, Day 1 - Set up MVVM architecture and Supabase connection
**Due**: April 30, 2026

---

## 📞 Support

Questions? Check:
1. `SUPABASE_SETUP.md` for configuration help
2. Flutter console logs for detailed errors
3. Supabase dashboard for backend status

---

## 🎉 Let's Build!

You're all set to start development. Follow the GitHub issues in order, starting with:

**Issue #2**: Day 1 - Set up MVVM architecture and Supabase connection

Good luck! 🚀

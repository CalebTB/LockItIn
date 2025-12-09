# LockItIn Flutter Project Structure

## Current Structure (Clean Architecture)

```
lockitin_app/
├── lib/
│   ├── main.dart                              # App entry point
│   │
│   ├── core/                                  # Core infrastructure
│   │   ├── config/
│   │   │   └── supabase_config.dart          # ⚠️ CONFIGURE THIS FIRST
│   │   ├── constants/
│   │   │   └── app_constants.dart            # App-wide constants
│   │   ├── network/
│   │   │   └── supabase_client.dart          # Supabase singleton
│   │   ├── storage/
│   │   │   └── secure_storage.dart           # Encrypted storage
│   │   └── utils/
│   │       └── logger.dart                   # Debug logging
│   │
│   ├── data/                                  # Data layer
│   │   ├── models/
│   │   │   ├── user_model.dart               # User data model
│   │   │   └── event_model.dart              # Event data model
│   │   ├── repositories/
│   │   │   └── auth_repository.dart          # Auth data operations
│   │   └── datasources/                      # (will add API clients here)
│   │
│   ├── domain/                                # Business logic layer
│   │   ├── entities/                         # (pure domain models)
│   │   ├── repositories/                     # (repository interfaces)
│   │   └── usecases/                         # (business logic)
│   │
│   └── presentation/                          # UI layer
│       ├── providers/
│       │   └── auth_provider.dart            # Auth state management
│       ├── screens/
│       │   ├── splash_screen.dart            # Initial loading screen
│       │   ├── home_screen.dart              # Main app screen (placeholder)
│       │   ├── auth/
│       │   │   └── login_screen.dart         # Login UI (placeholder)
│       │   ├── calendar/                     # (Sprint 1)
│       │   ├── groups/                       # (Sprint 2)
│       │   ├── profile/                      # (Sprint 1)
│       │   └── inbox/                        # (Sprint 3)
│       └── widgets/
│           └── common/                       # (shared UI components)
│
├── android/                                   # Android-specific code
├── ios/                                       # iOS-specific code
├── pubspec.yaml                               # Dependencies & config
├── SUPABASE_SETUP.md                          # Setup instructions
└── PROJECT_STRUCTURE.md                       # This file
```

---

## Key Files & What They Do

### 🔧 Configuration (Start Here!)

| File | Purpose | Action Required |
|------|---------|-----------------|
| `core/config/supabase_config.dart` | Supabase credentials | ⚠️ **MUST UPDATE** with your URL & API key |
| `pubspec.yaml` | Flutter dependencies | ✅ Already configured |

### 🏗️ Core Infrastructure

| File | Purpose |
|------|---------|
| `core/network/supabase_client.dart` | Singleton Supabase client manager |
| `core/storage/secure_storage.dart` | Encrypted storage for tokens |
| `core/utils/logger.dart` | Debug logging with colored output |
| `core/constants/app_constants.dart` | App-wide constants |

### 📊 Data Layer

| File | Purpose |
|------|---------|
| `data/models/user_model.dart` | User data model with JSON serialization |
| `data/models/event_model.dart` | Event model with privacy settings |
| `data/repositories/auth_repository.dart` | Authentication operations (signup, login, logout) |

### 🎨 Presentation Layer

| File | Purpose |
|------|---------|
| `main.dart` | App entry point, initializes Supabase |
| `presentation/providers/auth_provider.dart` | Auth state management with Provider |
| `presentation/screens/splash_screen.dart` | Loading screen, checks auth state |
| `presentation/screens/home_screen.dart` | Main app screen (placeholder) |
| `presentation/screens/auth/login_screen.dart` | Login UI (placeholder - built in Day 3) |

---

## Dependencies Installed

### Production
- ✅ `provider` - State management
- ✅ `supabase_flutter` - Backend SDK
- ✅ `flutter_secure_storage` - Encrypted storage
- ✅ `intl` - Date formatting
- ✅ `table_calendar` - Calendar widget
- ✅ `http` - HTTP client
- ✅ `uuid` - Unique ID generation
- ✅ `equatable` - Value equality

### Development
- ✅ `flutter_lints` - Code quality
- ✅ `mockito` - Testing mocks
- ✅ `build_runner` - Code generation

---

## Next Steps

### 1. Configure Supabase (5 minutes)
```bash
# Open this file and add your credentials:
lib/core/config/supabase_config.dart
```

See `SUPABASE_SETUP.md` for detailed instructions.

### 2. Install Dependencies
```bash
cd application/lockitin_app
flutter pub get
```

### 3. Run the App
```bash
flutter run
```

Select your Android emulator when prompted.

### 4. Start Building!
Once the app runs successfully, you're ready to start **Sprint 1, Day 1** (GitHub Issue #2).

---

## Architecture Pattern: Clean Architecture

This project uses **Clean Architecture** with 3 layers:

```
Presentation Layer (UI)
    ↓ uses
Domain Layer (Business Logic)
    ↓ uses
Data Layer (Repositories, Models, APIs)
```

### Benefits:
- ✅ **Testable**: Each layer can be tested independently
- ✅ **Maintainable**: Clear separation of concerns
- ✅ **Scalable**: Easy to add new features
- ✅ **Platform-agnostic**: Business logic independent of UI framework

### Example Flow:
```
LoginScreen (UI)
    → AuthProvider (State Management)
        → AuthRepository (Data)
            → Supabase Client (API)
```

---

## State Management: Provider Pattern

We use **Provider** for state management:

```dart
// 1. Create a ChangeNotifier
class AuthProvider extends ChangeNotifier {
  User? _user;

  Future<void> login() async {
    _user = await authRepository.login();
    notifyListeners(); // Updates UI
  }
}

// 2. Provide it in main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
  ],
  child: MaterialApp(...),
)

// 3. Consume in UI
final authProvider = context.watch<AuthProvider>();
Text('User: ${authProvider.user?.name}');
```

---

## Folder Naming Conventions

- `snake_case` for file names: `auth_provider.dart`
- `PascalCase` for class names: `AuthProvider`
- `camelCase` for variables: `currentUser`
- `SCREAMING_SNAKE_CASE` for constants: `SUPABASE_URL`

---

## Ready to Build? 🚀

1. ✅ Project structure created
2. ⏳ Configure Supabase credentials
3. ⏳ Run `flutter pub get`
4. ⏳ Test the app
5. ⏳ Start Sprint 1!

See `SUPABASE_SETUP.md` for next steps.

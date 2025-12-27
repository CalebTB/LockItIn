import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/supabase_client.dart';
import 'core/utils/logger.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/calendar_provider.dart';
import 'presentation/providers/device_calendar_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    Logger.info('Initializing Supabase...', 'Main');
    await SupabaseClientManager.initialize();
    Logger.success('Supabase initialized successfully', 'Main');
  } catch (e) {
    Logger.error('Failed to initialize Supabase', e);
    // Continue anyway - will show error in UI
  }

  runApp(const LockItInApp());
}

class LockItInApp extends StatelessWidget {
  const LockItInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Settings Provider (load settings on app start)
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),

        // Authentication Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Device Calendar Provider (platform channels)
        ChangeNotifierProvider(create: (_) => DeviceCalendarProvider()),

        // Calendar Provider (calendar state, events, navigation)
        ChangeNotifierProvider(create: (_) => CalendarProvider()),

        // Add more providers here as you build features:
        // ChangeNotifierProvider(create: (_) => GroupsProvider()),
        // etc.
      ],
      child: MaterialApp(
        title: 'LockItIn',
        debugShowCheckedModeBanner: false,

        // Centralized Theme - Now managed in app_theme.dart
        // To change colors, edit lib/core/theme/app_colors.dart
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,

        // Use system theme mode
        themeMode: ThemeMode.system,

        // Initial route
        home: const SplashScreen(),
      ),
    );
  }
}

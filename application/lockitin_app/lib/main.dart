import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/supabase_client.dart';
import 'core/utils/logger.dart';
import 'presentation/providers/auth_provider.dart';
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
        // Authentication Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Add more providers here as you build features:
        // ChangeNotifierProvider(create: (_) => CalendarProvider()),
        // ChangeNotifierProvider(create: (_) => GroupsProvider()),
        // etc.
      ],
      child: MaterialApp(
        title: 'LockItIn',
        debugShowCheckedModeBanner: false,

        // Theme
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF), // iOS Blue
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'SF Pro', // Will use system font on iOS
        ),

        // Dark Theme
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0A84FF), // iOS Blue (Dark Mode)
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'SF Pro',
        ),

        // Use system theme mode
        themeMode: ThemeMode.system,

        // Initial route
        home: const SplashScreen(),
      ),
    );
  }
}

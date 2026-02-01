import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/network/supabase_client.dart';
import 'core/utils/logger.dart';
import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'data/repositories/supabase_calendar_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/calendar_provider.dart';
import 'presentation/providers/device_calendar_provider.dart';
import 'presentation/providers/friend_provider.dart';
import 'presentation/providers/group_calendar_provider.dart';
import 'presentation/providers/group_provider.dart';
import 'presentation/providers/personal_calendar_provider.dart';
import 'presentation/providers/proposal_provider.dart';
import 'presentation/providers/rsvp_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    Logger.info('Main', 'Initializing Supabase...');
    await SupabaseClientManager.initialize();
    Logger.success('Main', 'Supabase initialized successfully');
  } catch (e) {
    Logger.error('Main', 'Failed to initialize Supabase', e);
    // Continue anyway - will show error in UI
  }

  // Setup dependency injection
  try {
    Logger.info('Main', 'Setting up dependencies...');
    await setupDependencies();
    Logger.success('Main', 'Dependencies configured successfully');
  } catch (e) {
    Logger.error('Main', 'Failed to setup dependencies', e);
  }

  runApp(const LockItInApp());
}

class LockItInApp extends StatelessWidget {
  const LockItInApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create shared calendar repository instance
    final calendarRepository = SupabaseCalendarRepository(
      Supabase.instance.client,
    );

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

        // Personal Calendar Provider (new architecture - repository pattern)
        ChangeNotifierProvider(
          create: (_) => PersonalCalendarProvider(calendarRepository),
        ),

        // Group Calendar Provider (new architecture - repository pattern)
        ChangeNotifierProvider(
          create: (_) => GroupCalendarProvider(calendarRepository),
        ),

        // Friend Provider (friend system state management)
        ChangeNotifierProvider(create: (_) => FriendProvider()),

        // Group Provider (group system state management)
        ChangeNotifierProvider(create: (_) => GroupProvider()),

        // Proposal Provider (proposal list & voting state management)
        ChangeNotifierProvider(create: (_) => ProposalProvider()),

        // RSVP Provider (RSVP state management)
        ChangeNotifierProvider(create: (_) => RSVPProvider()),
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

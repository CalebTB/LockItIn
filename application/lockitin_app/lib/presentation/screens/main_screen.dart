import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/friend_provider.dart';
import 'card_calendar_screen.dart';
import 'profile_screen.dart';

/// Main navigation screen with bottom tab bar
/// Uses IndexedStack to preserve tab state across navigation
/// Platform-adaptive: CupertinoTabBar on iOS, NavigationBar on Android
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Tab content screens - using IndexedStack to preserve state
  final List<Widget> _screens = [
    const _CalendarTab(),
    const _GroupsTab(),
    const _InboxTab(),
    const _ProfileTab(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Platform.isIOS;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: isIOS
          ? _buildCupertinoTabBar(context)
          : _buildMaterialNavigationBar(context),
    );
  }

  /// iOS-style tab bar using CupertinoTabBar
  Widget _buildCupertinoTabBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CupertinoTabBar(
      currentIndex: _currentIndex,
      onTap: _onTabSelected,
      activeColor: colorScheme.primary,
      inactiveColor: colorScheme.onSurface.withValues(alpha: 0.5),
      backgroundColor: colorScheme.surface,
      border: Border(
        top: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      items: _buildTabItems(context),
    );
  }

  /// Android-style navigation bar using Material 3 NavigationBar
  Widget _buildMaterialNavigationBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabSelected,
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today_rounded),
          label: 'Calendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(Icons.group_rounded),
          label: 'Groups',
        ),
        // Inbox with badge for pending notifications
        Selector<FriendProvider, int>(
          selector: (_, provider) => provider.pendingRequests.length,
          builder: (context, pendingCount, _) {
            return NavigationDestination(
              icon: Badge(
                isLabelVisible: pendingCount > 0,
                label: Text('$pendingCount'),
                child: Icon(Icons.inbox_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: pendingCount > 0,
                label: Text('$pendingCount'),
                child: Icon(Icons.inbox_rounded),
              ),
              label: 'Inbox',
            );
          },
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }

  /// Build tab items for CupertinoTabBar (iOS)
  List<BottomNavigationBarItem> _buildTabItems(BuildContext context) {
    return [
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.calendar),
        activeIcon: Icon(CupertinoIcons.calendar_today),
        label: 'Calendar',
      ),
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.person_2),
        activeIcon: Icon(CupertinoIcons.person_2_fill),
        label: 'Groups',
      ),
      // Inbox with badge
      BottomNavigationBarItem(
        icon: Selector<FriendProvider, int>(
          selector: (_, provider) => provider.pendingRequests.length,
          builder: (context, pendingCount, _) {
            return Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(CupertinoIcons.tray),
            );
          },
        ),
        activeIcon: Selector<FriendProvider, int>(
          selector: (_, provider) => provider.pendingRequests.length,
          builder: (context, pendingCount, _) {
            return Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(CupertinoIcons.tray_fill),
            );
          },
        ),
        label: 'Inbox',
      ),
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.person),
        activeIcon: Icon(CupertinoIcons.person_fill),
        label: 'Profile',
      ),
    ];
  }
}

/// Calendar tab - wraps CardCalendarScreen
/// Removes AppBar since MainScreen handles navigation
class _CalendarTab extends StatelessWidget {
  const _CalendarTab();

  @override
  Widget build(BuildContext context) {
    return const CardCalendarScreen();
  }
}

/// Groups tab - placeholder for #167
/// Will show list of groups with quick access to group details
class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Groups'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: appColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'Groups',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your groups will appear here',
              style: TextStyle(
                fontSize: 16,
                color: appColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Coming in #167',
              style: TextStyle(
                fontSize: 12,
                color: appColors.textDisabled,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inbox tab - placeholder for #167
/// Will show notifications, friend requests, event invites
class _InboxTab extends StatelessWidget {
  const _InboxTab();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final friendProvider = context.watch<FriendProvider>();
    final pendingCount = friendProvider.pendingRequests.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Inbox'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: appColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'Inbox',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (pendingCount > 0)
              Text(
                '$pendingCount pending friend request${pendingCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Text(
                'No new notifications',
                style: TextStyle(
                  fontSize: 16,
                  color: appColors.textMuted,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Coming in #167',
              style: TextStyle(
                fontSize: 12,
                color: appColors.textDisabled,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile tab - wraps ProfileScreen
/// Removes AppBar navigation since tab bar handles it
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}

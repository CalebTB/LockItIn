import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import 'card_calendar_screen.dart';
import 'profile_screen.dart';
import 'tabs/groups_tab.dart';
import 'tabs/inbox_tab.dart';

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
    const CardCalendarScreen(),
    const GroupsTab(),
    const InboxTab(),
    const ProfileScreen(),
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

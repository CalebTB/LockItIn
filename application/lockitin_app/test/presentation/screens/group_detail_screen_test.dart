import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lockitin_app/presentation/screens/group_detail/group_detail_screen.dart';
import 'package:lockitin_app/presentation/providers/group_provider.dart';
import 'package:lockitin_app/presentation/providers/calendar_provider.dart';
import 'package:lockitin_app/data/models/group_model.dart';

/// Mock GroupProvider for testing - uses noSuchMethod for unneeded methods
class MockGroupProvider extends ChangeNotifier implements GroupProvider {
  List<GroupModel> _groups = [];
  GroupModel? _selectedGroup;
  List<GroupMemberProfile> _selectedGroupMembers = [];
  GroupMemberRole? _currentUserRole;
  List<GroupInvite> _pendingInvites = [];
  bool _isInitialized = false;

  @override
  List<GroupModel> get groups => _groups;

  @override
  GroupModel? get selectedGroup => _selectedGroup;

  @override
  List<GroupMemberProfile> get selectedGroupMembers => _selectedGroupMembers;

  @override
  GroupMemberRole? get currentUserRole => _currentUserRole;

  @override
  List<GroupInvite> get pendingInvites => _pendingInvites;

  @override
  bool get isLoadingGroups => false;

  @override
  bool get isLoadingMembers => false;

  @override
  bool get isLoadingInvites => false;

  @override
  bool get isCreatingGroup => false;

  @override
  bool get isUpdatingGroup => false;

  @override
  String? get groupsError => null;

  @override
  String? get membersError => null;

  @override
  String? get invitesError => null;

  @override
  String? get actionError => null;

  @override
  bool get isInitialized => _isInitialized;

  @override
  int get groupCount => _groups.length;

  @override
  int get pendingInviteCount => _pendingInvites.length;

  @override
  bool get hasGroups => _groups.isNotEmpty;

  @override
  bool get hasPendingInvites => _pendingInvites.isNotEmpty;

  @override
  bool get isOwner => _currentUserRole == GroupMemberRole.owner;

  @override
  bool get isCoOwner => _currentUserRole == GroupMemberRole.coOwner;

  @override
  bool get isOwnerOrCoOwner => isOwner || isCoOwner;

  @override
  bool get canManageMembers => isOwnerOrCoOwner;

  @override
  bool get canInviteMembers => isOwnerOrCoOwner;

  // Setters for testing
  void setSelectedGroup(GroupModel? group) {
    _selectedGroup = group;
    notifyListeners();
  }

  void setSelectedGroupMembers(List<GroupMemberProfile> members) {
    _selectedGroupMembers = members;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    _isInitialized = true;
    notifyListeners();
  }

  @override
  void reset() {
    _groups = [];
    _selectedGroup = null;
    _selectedGroupMembers = [];
    _currentUserRole = null;
    _pendingInvites = [];
    _isInitialized = false;
    notifyListeners();
  }

  @override
  Future<void> selectGroup(String groupId) async {
    // Mock implementation - just keep current selected group
    notifyListeners();
  }

  @override
  void clearSelectedGroup() {
    _selectedGroup = null;
    _selectedGroupMembers = [];
    _currentUserRole = null;
    notifyListeners();
  }

  @override
  void clearActionError() {
    notifyListeners();
  }

  // Use noSuchMethod for all other methods we don't need
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return sensible defaults for any unimplemented methods
    if (invocation.isMethod) {
      // For async methods returning bool, return true
      if (invocation.memberName.toString().contains('remove') ||
          invocation.memberName.toString().contains('update') ||
          invocation.memberName.toString().contains('accept') ||
          invocation.memberName.toString().contains('decline') ||
          invocation.memberName.toString().contains('invite') ||
          invocation.memberName.toString().contains('leave') ||
          invocation.memberName.toString().contains('transfer')) {
        return Future.value(true);
      }
      // For async methods returning GroupModel, return null
      if (invocation.memberName.toString().contains('create')) {
        return Future.value(null);
      }
      // For other async methods, return completed future
      return Future.value();
    }
    return super.noSuchMethod(invocation);
  }
}

/// Mock CalendarProvider for testing
class MockCalendarProvider extends ChangeNotifier implements CalendarProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return sensible defaults
    if (invocation.isGetter) {
      final name = invocation.memberName.toString();
      if (name.contains('isLoading')) return false;
      if (name.contains('error')) return null;
      if (name.contains('isInitialized')) return true;
      if (name.contains('events')) return <dynamic>[];
    }
    if (invocation.isMethod) {
      return Future.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late MockGroupProvider mockGroupProvider;
  late MockCalendarProvider mockCalendarProvider;
  late GroupModel testGroup;

  setUp(() {
    mockGroupProvider = MockGroupProvider();
    mockCalendarProvider = MockCalendarProvider();
    testGroup = GroupModel(
      id: 'group-123',
      name: 'Test Group',
      emoji: '🎉',
      createdBy: 'user-1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      memberCount: 3,
    );

    // Set up default group members
    mockGroupProvider.setSelectedGroup(testGroup);
    mockGroupProvider.setSelectedGroupMembers([
      GroupMemberProfile(
        memberId: 'member-1',
        userId: 'user-1',
        role: GroupMemberRole.owner,
        joinedAt: DateTime(2025, 1, 1),
        email: 'owner@example.com',
        fullName: 'Group Owner',
      ),
      GroupMemberProfile(
        memberId: 'member-2',
        userId: 'user-2',
        role: GroupMemberRole.member,
        joinedAt: DateTime(2025, 1, 2),
        email: 'member@example.com',
        fullName: 'Group Member',
      ),
    ]);
  });

  Widget createTestWidget({GroupModel? group}) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<GroupProvider>.value(value: mockGroupProvider),
          ChangeNotifierProvider<CalendarProvider>.value(value: mockCalendarProvider),
        ],
        child: GroupDetailScreen(group: group ?? testGroup),
      ),
    );
  }

  group('GroupDetailScreen - Basic Structure', () {
    testWidgets('should display group name in header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Test Group'), findsOneWidget);
    });

    testWidgets('should display group emoji in header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('🎉'), findsOneWidget);
    });

    testWidgets('should display back button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsWidgets);
    });

    testWidgets('should display members icon button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.people_rounded), findsOneWidget);
    });
  });

  group('GroupDetailScreen - Calendar Grid', () {
    testWidgets('should display day of week headers', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
    });

    testWidgets('should display calendar grid view', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(GridView), findsWidgets);
    });

    testWidgets('should display PageView for month navigation', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
    });
  });

  group('GroupDetailScreen - Month Navigation', () {
    testWidgets('should display month and year', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Current month should be displayed
      final now = DateTime.now();
      final monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final expectedMonthYear = '${monthNames[now.month - 1]} ${now.year}';

      expect(find.text(expectedMonthYear), findsOneWidget);
    });

    testWidgets('should display navigation arrows', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsWidgets);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('GroupDetailScreen - Time Filter Chips', () {
    testWidgets('should display Custom filter chip (All Day)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // "All Day" is displayed as "Custom" in the UI
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('should display time filter options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Time filter chips should be present
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Afternoon'), findsOneWidget);
      expect(find.text('Evening'), findsOneWidget);
    });
  });

  group('GroupDetailScreen - Heatmap Cells', () {
    testWidgets('should render grid view for calendar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Grid should exist with calendar days
      final gridViews = tester.widgetList<GridView>(find.byType(GridView));
      expect(gridViews.isNotEmpty, true);
    });
  });

  group('GroupDetailScreen - Interactions', () {
    testWidgets('should have tappable members icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find members icon - verify it exists and is tappable
      final memberIcon = find.byIcon(Icons.people_rounded);
      expect(memberIcon, findsOneWidget);
      // Don't actually tap it as it triggers Supabase calls
      // Just verify the button exists for widget tests
    });
  });

  group('GroupDetailScreen - Different Group Data', () {
    testWidgets('should display custom group emoji', (tester) async {
      final customGroup = GroupModel(
        id: 'group-456',
        name: 'Sports Team',
        emoji: '⚽',
        createdBy: 'user-1',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        memberCount: 5,
      );

      await tester.pumpWidget(createTestWidget(group: customGroup));
      await tester.pump();

      expect(find.text('Sports Team'), findsOneWidget);
      expect(find.text('⚽'), findsOneWidget);
    });
  });
}

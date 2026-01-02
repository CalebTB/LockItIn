import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/widgets/friend_list_tile.dart';
import 'package:lockitin_app/data/models/friendship_model.dart';

void main() {
  FriendProfile createTestFriend({
    String id = 'friend-1',
    String? fullName = 'John Doe',
    required String email,
    String? avatarUrl,
    DateTime? friendshipSince,
  }) {
    return FriendProfile(
      id: id,
      fullName: fullName,
      email: email,
      avatarUrl: avatarUrl,
      friendshipSince: friendshipSince,
    );
  }

  group('FriendListTile Widget', () {
    testWidgets('should display friend name', (tester) async {
      final friend = createTestFriend(
        fullName: 'John Doe',
        email: 'john@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendListTile(friend: friend),
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('should display email when name is null', (tester) async {
      final friend = createTestFriend(
        fullName: null,
        email: 'john@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendListTile(friend: friend),
          ),
        ),
      );

      expect(find.text('john@example.com'), findsOneWidget);
    });

    testWidgets('should display avatar with initials', (tester) async {
      final friend = createTestFriend(
        fullName: 'John Doe',
        email: 'john@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendListTile(friend: friend),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('should be tappable when onTap is provided', (tester) async {
      bool tapped = false;
      final friend = createTestFriend(email: 'john@example.com');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendListTile(
              friend: friend,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, true);
    });

    testWidgets('should show popup menu with options', (tester) async {
      final friend = createTestFriend(email: 'john@example.com');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendListTile(friend: friend),
          ),
        ),
      );

      // Tap the more button
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Menu options should appear
      expect(find.text('View Profile'), findsOneWidget);
      expect(find.text('View Calendar'), findsOneWidget);
      expect(find.text('Remove Friend'), findsOneWidget);
    });

    testWidgets('should call onRemove when Remove Friend is selected', (tester) async {
      bool removed = false;
      final friend = createTestFriend(email: 'john@example.com');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendListTile(
              friend: friend,
              onRemove: () => removed = true,
            ),
          ),
        ),
      );

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Tap Remove Friend
      await tester.tap(find.text('Remove Friend'));
      await tester.pumpAndSettle();

      expect(removed, true);
    });
  });
}

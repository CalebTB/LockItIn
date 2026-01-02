import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/widgets/friend_request_tile.dart';
import 'package:lockitin_app/data/models/friendship_model.dart';

void main() {
  FriendRequest createTestRequest({
    String requestId = 'request-1',
    String requesterId = 'user-1',
    String? fullName = 'John Doe',
    required String email,
    String? avatarUrl,
    DateTime? requestedAt,
  }) {
    return FriendRequest(
      requestId: requestId,
      requesterId: requesterId,
      fullName: fullName,
      email: email,
      avatarUrl: avatarUrl,
      requestedAt: requestedAt ?? DateTime.now(),
    );
  }

  group('FriendRequestTile Widget', () {
    testWidgets('should display requester name', (tester) async {
      final request = createTestRequest(
        fullName: 'Jane Smith',
        email: 'jane@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendRequestTile(request: request),
          ),
        ),
      );

      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('should display email when name is null', (tester) async {
      final request = createTestRequest(
        fullName: null,
        email: 'jane@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendRequestTile(request: request),
          ),
        ),
      );

      expect(find.text('jane@example.com'), findsOneWidget);
    });

    testWidgets('should display avatar with initials', (tester) async {
      final request = createTestRequest(
        fullName: 'Jane Smith',
        email: 'jane@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendRequestTile(request: request),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('JS'), findsOneWidget);
    });

    testWidgets('should display "Just now" for recent request', (tester) async {
      final request = createTestRequest(
        email: 'jane@example.com',
        requestedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendRequestTile(request: request),
          ),
        ),
      );

      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('should display hours ago for older request', (tester) async {
      final request = createTestRequest(
        email: 'jane@example.com',
        requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendRequestTile(request: request),
          ),
        ),
      );

      expect(find.text('2 hours ago'), findsOneWidget);
    });

    testWidgets('should display days ago for older request', (tester) async {
      final request = createTestRequest(
        email: 'jane@example.com',
        requestedAt: DateTime.now().subtract(const Duration(days: 3)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendRequestTile(request: request),
          ),
        ),
      );

      expect(find.text('3 days ago'), findsOneWidget);
    });

    testWidgets('should show accept and decline buttons', (tester) async {
      final request = createTestRequest(email: 'jane@example.com');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendRequestTile(request: request),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('should call onAccept when accept is tapped', (tester) async {
      bool accepted = false;
      final request = createTestRequest(email: 'jane@example.com');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendRequestTile(
              request: request,
              onAccept: () => accepted = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.check_rounded));
      expect(accepted, true);
    });

    testWidgets('should call onDecline when decline is tapped', (tester) async {
      bool declined = false;
      final request = createTestRequest(email: 'jane@example.com');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendRequestTile(
              request: request,
              onDecline: () => declined = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(declined, true);
    });
  });
}

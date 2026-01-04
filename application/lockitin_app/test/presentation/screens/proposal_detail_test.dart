import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/presentation/screens/proposal_detail/widgets/proposal_header.dart';
import 'package:lockitin_app/presentation/screens/proposal_detail/widgets/proposal_status_banner.dart';
import 'package:lockitin_app/presentation/screens/proposal_detail/widgets/time_option_card.dart';
import 'package:lockitin_app/data/models/proposal_model.dart';
import 'package:lockitin_app/data/models/proposal_time_option.dart';
import 'package:lockitin_app/data/models/vote_model.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';

void main() {
  group('ProposalHeader Widget Tests', () {
    late ProposalModel testProposal;

    setUp(() {
      testProposal = ProposalModel(
        id: 'test-id',
        groupId: 'group-id',
        createdBy: 'user-id',
        title: 'Team Dinner',
        description: 'Monthly team dinner',
        location: 'Downtown Restaurant',
        votingDeadline: DateTime.now().add(const Duration(days: 2)),
        status: ProposalStatus.voting,
        createdAt: DateTime.now(),
        creatorName: 'John Doe',
      );
    });

    testWidgets('displays proposal title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProposalHeader(proposal: testProposal),
          ),
        ),
      );

      expect(find.text('Team Dinner'), findsOneWidget);
    });

    testWidgets('displays creator name when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProposalHeader(proposal: testProposal),
          ),
        ),
      );

      expect(find.textContaining('John Doe'), findsOneWidget);
    });

    testWidgets('displays active status badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProposalHeader(proposal: testProposal),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('displays closed status badge for confirmed proposals', (WidgetTester tester) async {
      final confirmedProposal = testProposal.copyWith(
        status: ProposalStatus.confirmed,
        votingDeadline: DateTime.now().add(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProposalHeader(proposal: confirmedProposal),
          ),
        ),
      );

      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('displays deadline information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProposalHeader(proposal: testProposal),
          ),
        ),
      );

      // Should show "Voting closes in" text
      expect(find.textContaining('Voting closes in'), findsOneWidget);
    });
  });

  group('ProposalStatusBanner Widget Tests', () {
    testWidgets('does not show for active voting proposals', (WidgetTester tester) async {
      final votingProposal = ProposalModel(
        id: 'test-id',
        groupId: 'group-id',
        createdBy: 'user-id',
        title: 'Test Proposal',
        votingDeadline: DateTime.now().add(const Duration(days: 1)),
        status: ProposalStatus.voting,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProposalStatusBanner(proposal: votingProposal),
          ),
        ),
      );

      // Should not show banner
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('shows confirmed banner for confirmed proposals', (WidgetTester tester) async {
      final confirmedProposal = ProposalModel(
        id: 'test-id',
        groupId: 'group-id',
        createdBy: 'user-id',
        title: 'Test Proposal',
        votingDeadline: DateTime.now().subtract(const Duration(days: 1)),
        status: ProposalStatus.confirmed,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProposalStatusBanner(proposal: confirmedProposal),
          ),
        ),
      );

      expect(find.text('Event Created'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows cancelled banner for cancelled proposals', (WidgetTester tester) async {
      final cancelledProposal = ProposalModel(
        id: 'test-id',
        groupId: 'group-id',
        createdBy: 'user-id',
        title: 'Test Proposal',
        votingDeadline: DateTime.now().subtract(const Duration(days: 1)),
        status: ProposalStatus.cancelled,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProposalStatusBanner(proposal: cancelledProposal),
          ),
        ),
      );

      expect(find.text('Proposal Cancelled'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('shows expired banner for expired proposals', (WidgetTester tester) async {
      final expiredProposal = ProposalModel(
        id: 'test-id',
        groupId: 'group-id',
        createdBy: 'user-id',
        title: 'Test Proposal',
        votingDeadline: DateTime.now().subtract(const Duration(days: 1)),
        status: ProposalStatus.expired,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProposalStatusBanner(proposal: expiredProposal),
          ),
        ),
      );

      expect(find.text('Voting Closed'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });
  });

  group('TimeOptionCard Widget Tests', () {
    late ProposalTimeOption testOption;
    late ProposalModel testProposal;
    bool voteCallbackCalled = false;
    VoteType? votedType;
    bool showBreakdownCalled = false;

    setUp(() {
      voteCallbackCalled = false;
      votedType = null;
      showBreakdownCalled = false;

      testOption = ProposalTimeOption(
        id: 'option-id',
        proposalId: 'proposal-id',
        startTime: DateTime(2026, 1, 15, 14, 0), // 2:00 PM
        endTime: DateTime(2026, 1, 15, 16, 0),   // 4:00 PM
        yesCount: 5,
        maybeCount: 2,
        noCount: 1,
      );

      testProposal = ProposalModel(
        id: 'proposal-id',
        groupId: 'group-id',
        createdBy: 'user-id',
        title: 'Test Proposal',
        votingDeadline: DateTime.now().add(const Duration(days: 1)),
        status: ProposalStatus.voting,
        createdAt: DateTime.now(),
      );
    });

    testWidgets('displays date and time', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TimeOptionCard(
              option: testOption,
              proposal: testProposal,
              onVote: (type) {
                voteCallbackCalled = true;
                votedType = type;
              },
              onShowBreakdown: () {
                showBreakdownCalled = true;
              },
            ),
          ),
        ),
      );

      // Should show formatted date
      expect(find.textContaining('Jan'), findsWidgets);
      // Should show time range
      expect(find.textContaining('PM'), findsWidgets);
    });

    testWidgets('displays vote counts', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TimeOptionCard(
              option: testOption,
              proposal: testProposal,
              onVote: (type) {
                voteCallbackCalled = true;
                votedType = type;
              },
              onShowBreakdown: () {
                showBreakdownCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget); // Yes count
      expect(find.text('2'), findsOneWidget); // Maybe count
      expect(find.text('1'), findsOneWidget); // No count
    });

    testWidgets('shows voting buttons when voting is open', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TimeOptionCard(
              option: testOption,
              proposal: testProposal,
              onVote: (type) {
                voteCallbackCalled = true;
                votedType = type;
              },
              onShowBreakdown: () {
                showBreakdownCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('Maybe'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('calls onVote callback when vote button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TimeOptionCard(
              option: testOption,
              proposal: testProposal,
              onVote: (type) {
                voteCallbackCalled = true;
                votedType = type;
              },
              onShowBreakdown: () {
                showBreakdownCalled = true;
              },
            ),
          ),
        ),
      );

      // Tap the Yes button
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(voteCallbackCalled, isTrue);
      expect(votedType, equals(VoteType.yes));
    });

    testWidgets('shows user vote badge when user has voted', (WidgetTester tester) async {
      final optionWithUserVote = testOption.copyWith(userVote: VoteType.yes);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TimeOptionCard(
              option: optionWithUserVote,
              proposal: testProposal,
              onVote: (type) {},
              onShowBreakdown: () {},
            ),
          ),
        ),
      );

      expect(find.text('YES'), findsOneWidget);
    });

    testWidgets('disables voting when proposal is expired', (WidgetTester tester) async {
      final expiredProposal = testProposal.copyWith(
        votingDeadline: DateTime.now().subtract(const Duration(days: 1)),
        status: ProposalStatus.expired,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TimeOptionCard(
              option: testOption,
              proposal: expiredProposal,
              onVote: (type) {
                voteCallbackCalled = true;
              },
              onShowBreakdown: () {},
            ),
          ),
        ),
      );

      // Should show "Voting has closed" message
      expect(find.text('Voting has closed'), findsOneWidget);
      // Voting buttons should not be present
      expect(find.text('Yes'), findsNothing);
    });

    testWidgets('calls onShowBreakdown when card is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TimeOptionCard(
              option: testOption,
              proposal: testProposal,
              onVote: (type) {},
              onShowBreakdown: () {
                showBreakdownCalled = true;
              },
            ),
          ),
        ),
      );

      // Tap the card (not on a button)
      await tester.tap(find.byType(TimeOptionCard));
      await tester.pumpAndSettle();

      expect(showBreakdownCalled, isTrue);
    });

    testWidgets('shows progress bar with correct proportions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TimeOptionCard(
              option: testOption,
              proposal: testProposal,
              onVote: (type) {},
              onShowBreakdown: () {},
            ),
          ),
        ),
      );

      // Progress bar should be visible
      expect(find.byType(ClipRRect), findsWidgets);
    });
  });
}

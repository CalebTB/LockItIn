import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/data/models/proposal_model.dart';
import 'package:lockitin_app/data/models/proposal_time_option.dart';

void main() {
  group('ProposalStatus Enum', () {
    test('should have all expected values', () {
      expect(ProposalStatus.values.length, 4);
      expect(ProposalStatus.values.contains(ProposalStatus.voting), true);
      expect(ProposalStatus.values.contains(ProposalStatus.confirmed), true);
      expect(ProposalStatus.values.contains(ProposalStatus.cancelled), true);
      expect(ProposalStatus.values.contains(ProposalStatus.expired), true);
    });

    group('fromString', () {
      test('should parse valid status values', () {
        expect(ProposalStatus.fromString('voting'), ProposalStatus.voting);
        expect(ProposalStatus.fromString('confirmed'), ProposalStatus.confirmed);
        expect(ProposalStatus.fromString('cancelled'), ProposalStatus.cancelled);
        expect(ProposalStatus.fromString('expired'), ProposalStatus.expired);
      });

      test('should return voting for unknown values', () {
        expect(ProposalStatus.fromString('unknown'), ProposalStatus.voting);
        expect(ProposalStatus.fromString('invalid'), ProposalStatus.voting);
      });
    });
  });

  group('ProposalModel', () {
    final now = DateTime.now();
    final futureDeadline = now.add(const Duration(days: 7));
    final pastDeadline = now.subtract(const Duration(days: 1));

    ProposalModel createTestProposal({
      String id = 'proposal-123',
      String groupId = 'group-456',
      String createdBy = 'user-789',
      String title = 'Test Proposal',
      String? description,
      String? location,
      DateTime? votingDeadline,
      int minVotesRequired = 1,
      bool autoConfirm = true,
      ProposalStatus status = ProposalStatus.voting,
      String? confirmedTimeOptionId,
      String? confirmedEventId,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? creatorName,
      List<ProposalTimeOption>? timeOptions,
      int? totalVoters,
      bool? userHasVoted,
    }) {
      return ProposalModel(
        id: id,
        groupId: groupId,
        createdBy: createdBy,
        title: title,
        description: description,
        location: location,
        votingDeadline: votingDeadline ?? futureDeadline,
        minVotesRequired: minVotesRequired,
        autoConfirm: autoConfirm,
        status: status,
        confirmedTimeOptionId: confirmedTimeOptionId,
        confirmedEventId: confirmedEventId,
        createdAt: createdAt ?? now,
        updatedAt: updatedAt,
        creatorName: creatorName,
        timeOptions: timeOptions,
        totalVoters: totalVoters,
        userHasVoted: userHasVoted,
      );
    }

    group('Constructor', () {
      test('should create ProposalModel with required fields', () {
        final proposal = createTestProposal();

        expect(proposal.id, 'proposal-123');
        expect(proposal.groupId, 'group-456');
        expect(proposal.createdBy, 'user-789');
        expect(proposal.title, 'Test Proposal');
        expect(proposal.votingDeadline, futureDeadline);
      });

      test('should have default values for optional fields', () {
        final proposal = createTestProposal();

        expect(proposal.description, isNull);
        expect(proposal.location, isNull);
        expect(proposal.minVotesRequired, 1);
        expect(proposal.autoConfirm, true);
        expect(proposal.status, ProposalStatus.voting);
        expect(proposal.confirmedTimeOptionId, isNull);
        expect(proposal.confirmedEventId, isNull);
        expect(proposal.updatedAt, isNull);
        expect(proposal.creatorName, isNull);
        expect(proposal.timeOptions, isNull);
        expect(proposal.totalVoters, isNull);
        expect(proposal.userHasVoted, isNull);
      });

      test('should accept all optional fields', () {
        final timeOptions = [
          ProposalTimeOption(
            startTime: now,
            endTime: now.add(const Duration(hours: 1)),
          ),
        ];

        final proposal = createTestProposal(
          description: 'Test description',
          location: 'Test location',
          minVotesRequired: 5,
          autoConfirm: false,
          status: ProposalStatus.confirmed,
          confirmedTimeOptionId: 'option-123',
          confirmedEventId: 'event-123',
          updatedAt: now,
          creatorName: 'John Doe',
          timeOptions: timeOptions,
          totalVoters: 10,
          userHasVoted: true,
        );

        expect(proposal.description, 'Test description');
        expect(proposal.location, 'Test location');
        expect(proposal.minVotesRequired, 5);
        expect(proposal.autoConfirm, false);
        expect(proposal.status, ProposalStatus.confirmed);
        expect(proposal.confirmedTimeOptionId, 'option-123');
        expect(proposal.confirmedEventId, 'event-123');
        expect(proposal.updatedAt, now);
        expect(proposal.creatorName, 'John Doe');
        expect(proposal.timeOptions, timeOptions);
        expect(proposal.totalVoters, 10);
        expect(proposal.userHasVoted, true);
      });
    });

    group('Computed Properties', () {
      test('isVotingOpen should be true when status is voting and deadline not passed', () {
        final proposal = createTestProposal(
          status: ProposalStatus.voting,
          votingDeadline: futureDeadline,
        );
        expect(proposal.isVotingOpen, true);
      });

      test('isVotingOpen should be false when status is not voting', () {
        final confirmedProposal = createTestProposal(status: ProposalStatus.confirmed);
        final cancelledProposal = createTestProposal(status: ProposalStatus.cancelled);

        expect(confirmedProposal.isVotingOpen, false);
        expect(cancelledProposal.isVotingOpen, false);
      });

      test('isVotingOpen should be false when deadline passed', () {
        final proposal = createTestProposal(
          status: ProposalStatus.voting,
          votingDeadline: pastDeadline,
        );
        expect(proposal.isVotingOpen, false);
      });

      test('isExpired should be true when deadline passed', () {
        final expiredProposal = createTestProposal(votingDeadline: pastDeadline);
        final activeProposal = createTestProposal(votingDeadline: futureDeadline);

        expect(expiredProposal.isExpired, true);
        expect(activeProposal.isExpired, false);
      });

      test('timeRemaining should return duration until deadline', () {
        final proposal = createTestProposal(votingDeadline: futureDeadline);
        final remaining = proposal.timeRemaining;

        // Should be approximately 7 days
        expect(remaining.inDays, greaterThanOrEqualTo(6));
        expect(remaining.inDays, lessThanOrEqualTo(7));
      });
    });

    group('fromJson', () {
      test('should parse complete JSON correctly', () {
        final json = {
          'id': 'proposal-123',
          'group_id': 'group-456',
          'created_by': 'user-789',
          'title': 'Team Lunch',
          'description': 'Weekly team lunch',
          'location': 'Cafe ABC',
          'voting_deadline': '2025-06-22T12:00:00.000Z',
          'min_votes_required': 3,
          'auto_confirm': false,
          'status': 'voting',
          'confirmed_time_option_id': null,
          'confirmed_event_id': null,
          'created_at': '2025-06-15T09:00:00.000Z',
          'updated_at': '2025-06-15T10:00:00.000Z',
          'creator_name': 'John Doe',
          'total_votes': 5,
          'user_has_voted': true,
        };

        final proposal = ProposalModel.fromJson(json);

        expect(proposal.id, 'proposal-123');
        expect(proposal.groupId, 'group-456');
        expect(proposal.createdBy, 'user-789');
        expect(proposal.title, 'Team Lunch');
        expect(proposal.description, 'Weekly team lunch');
        expect(proposal.location, 'Cafe ABC');
        expect(proposal.minVotesRequired, 3);
        expect(proposal.autoConfirm, false);
        expect(proposal.status, ProposalStatus.voting);
        expect(proposal.creatorName, 'John Doe');
        expect(proposal.totalVoters, 5);
        expect(proposal.userHasVoted, true);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'p1',
          'group_id': 'g1',
          'created_by': 'u1',
          'title': 'T',
          'voting_deadline': '2025-06-22T12:00:00.000Z',
          'created_at': '2025-06-15T09:00:00.000Z',
          'description': null,
          'location': null,
          'min_votes_required': null,
          'auto_confirm': null,
          'status': null,
          'updated_at': null,
        };

        final proposal = ProposalModel.fromJson(json);

        expect(proposal.description, isNull);
        expect(proposal.location, isNull);
        expect(proposal.minVotesRequired, 1);
        expect(proposal.autoConfirm, true);
        expect(proposal.status, ProposalStatus.voting);
        expect(proposal.updatedAt, isNull);
      });

      test('should parse time options when present', () {
        final json = {
          'id': 'p1',
          'group_id': 'g1',
          'created_by': 'u1',
          'title': 'T',
          'voting_deadline': '2025-06-22T12:00:00.000Z',
          'created_at': '2025-06-15T09:00:00.000Z',
          'time_options': [
            {
              'id': 'opt-1',
              'start_time': '2025-06-20T14:00:00.000Z',
              'end_time': '2025-06-20T15:00:00.000Z',
            },
            {
              'id': 'opt-2',
              'start_time': '2025-06-21T14:00:00.000Z',
              'end_time': '2025-06-21T15:00:00.000Z',
            },
          ],
        };

        final proposal = ProposalModel.fromJson(json);

        expect(proposal.timeOptions, isNotNull);
        expect(proposal.timeOptions!.length, 2);
        expect(proposal.timeOptions![0].id, 'opt-1');
        expect(proposal.timeOptions![1].id, 'opt-2');
      });

      test('should parse all status values', () {
        final statuses = ['voting', 'confirmed', 'cancelled', 'expired'];

        for (final status in statuses) {
          final json = {
            'id': 'p1',
            'group_id': 'g1',
            'created_by': 'u1',
            'title': 'T',
            'voting_deadline': '2025-06-22T12:00:00.000Z',
            'created_at': '2025-06-15T09:00:00.000Z',
            'status': status,
          };

          final proposal = ProposalModel.fromJson(json);
          expect(proposal.status, ProposalStatus.fromString(status));
        }
      });
    });

    group('toJson', () {
      test('should serialize required fields correctly', () {
        final proposal = createTestProposal();
        final json = proposal.toJson();

        expect(json['group_id'], 'group-456');
        expect(json['created_by'], 'user-789');
        expect(json['title'], 'Test Proposal');
        expect(json['voting_deadline'], futureDeadline.toIso8601String());
        expect(json['min_votes_required'], 1);
        expect(json['auto_confirm'], true);
        expect(json['status'], 'voting');
      });

      test('should include optional fields when set', () {
        final proposal = createTestProposal(
          description: 'Desc',
          location: 'Loc',
        );
        final json = proposal.toJson();

        expect(json['description'], 'Desc');
        expect(json['location'], 'Loc');
      });

      test('should exclude null optional fields', () {
        final proposal = createTestProposal();
        final json = proposal.toJson();

        expect(json.containsKey('description'), false);
        expect(json.containsKey('location'), false);
      });

      test('should not include id in output', () {
        final proposal = createTestProposal();
        final json = proposal.toJson();

        // toJson is for insert/update, so id might not be included
        // depending on implementation
        expect(json.containsKey('id'), false);
      });
    });

    group('copyWith', () {
      test('should create copy with updated title', () {
        final original = createTestProposal();
        final copy = original.copyWith(title: 'New Title');

        expect(copy.title, 'New Title');
        expect(copy.id, original.id);
        expect(copy.groupId, original.groupId);
      });

      test('should create copy with updated status', () {
        final original = createTestProposal(status: ProposalStatus.voting);
        final copy = original.copyWith(status: ProposalStatus.confirmed);

        expect(copy.status, ProposalStatus.confirmed);
        expect(original.status, ProposalStatus.voting);
      });

      test('should preserve all fields when no changes specified', () {
        final original = createTestProposal(
          description: 'Desc',
          location: 'Loc',
          minVotesRequired: 5,
          creatorName: 'John',
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.description, original.description);
        expect(copy.location, original.location);
        expect(copy.minVotesRequired, original.minVotesRequired);
        expect(copy.creatorName, original.creatorName);
      });
    });

    group('Equality', () {
      test('two proposals with same id should be equal', () {
        final prop1 = createTestProposal(id: 'prop-1');
        final prop2 = createTestProposal(id: 'prop-1', title: 'Different');

        expect(prop1, equals(prop2));
      });

      test('two proposals with different ids should not be equal', () {
        final prop1 = createTestProposal(id: 'prop-1');
        final prop2 = createTestProposal(id: 'prop-2');

        expect(prop1, isNot(equals(prop2)));
      });

      test('hashCode should be based on id', () {
        final prop1 = createTestProposal(id: 'prop-1');
        final prop2 = createTestProposal(id: 'prop-1');

        expect(prop1.hashCode, equals(prop2.hashCode));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final proposal = createTestProposal();
        final str = proposal.toString();

        expect(str, contains('ProposalModel'));
        expect(str, contains('proposal-123'));
        expect(str, contains('Test Proposal'));
        expect(str, contains('voting'));
      });
    });
  });
}

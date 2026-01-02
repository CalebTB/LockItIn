import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/data/models/vote_model.dart';

void main() {
  group('VoteType Enum', () {
    test('should have all expected values', () {
      expect(VoteType.values.length, 3);
      expect(VoteType.values.contains(VoteType.yes), true);
      expect(VoteType.values.contains(VoteType.no), true);
      expect(VoteType.values.contains(VoteType.maybe), true);
    });

    group('fromString', () {
      test('should parse valid vote type values', () {
        expect(VoteType.fromString('yes'), VoteType.yes);
        expect(VoteType.fromString('no'), VoteType.no);
        expect(VoteType.fromString('maybe'), VoteType.maybe);
      });

      test('should return maybe for unknown values', () {
        expect(VoteType.fromString('unknown'), VoteType.maybe);
        expect(VoteType.fromString('invalid'), VoteType.maybe);
      });
    });

    group('label', () {
      test('should return human-readable labels', () {
        expect(VoteType.yes.label, 'Available');
        expect(VoteType.no.label, 'Unavailable');
        expect(VoteType.maybe.label, 'If needed');
      });
    });

    group('iconName', () {
      test('should return correct icon names', () {
        expect(VoteType.yes.iconName, 'check_circle');
        expect(VoteType.no.iconName, 'cancel');
        expect(VoteType.maybe.iconName, 'help');
      });
    });
  });

  group('VoteModel', () {
    final testDate = DateTime(2025, 6, 15, 10, 0);

    VoteModel createTestVote({
      String id = 'vote-123',
      String proposalId = 'proposal-456',
      String timeOptionId = 'option-789',
      String userId = 'user-abc',
      VoteType vote = VoteType.yes,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? userFullName,
      String? userAvatarUrl,
    }) {
      return VoteModel(
        id: id,
        proposalId: proposalId,
        timeOptionId: timeOptionId,
        userId: userId,
        vote: vote,
        createdAt: createdAt ?? testDate,
        updatedAt: updatedAt,
        userFullName: userFullName,
        userAvatarUrl: userAvatarUrl,
      );
    }

    group('Constructor', () {
      test('should create VoteModel with required fields', () {
        final voteModel = createTestVote();

        expect(voteModel.id, 'vote-123');
        expect(voteModel.proposalId, 'proposal-456');
        expect(voteModel.timeOptionId, 'option-789');
        expect(voteModel.userId, 'user-abc');
        expect(voteModel.vote, VoteType.yes);
        expect(voteModel.createdAt, testDate);
      });

      test('should have null optional fields by default', () {
        final voteModel = createTestVote();

        expect(voteModel.updatedAt, isNull);
        expect(voteModel.userFullName, isNull);
        expect(voteModel.userAvatarUrl, isNull);
      });

      test('should accept all optional fields', () {
        final voteModel = createTestVote(
          updatedAt: testDate,
          userFullName: 'John Doe',
          userAvatarUrl: 'https://example.com/avatar.jpg',
        );

        expect(voteModel.updatedAt, testDate);
        expect(voteModel.userFullName, 'John Doe');
        expect(voteModel.userAvatarUrl, 'https://example.com/avatar.jpg');
      });
    });

    group('fromJson', () {
      test('should parse complete JSON correctly', () {
        final json = {
          'id': 'vote-123',
          'proposal_id': 'proposal-456',
          'time_option_id': 'option-789',
          'user_id': 'user-abc',
          'vote': 'yes',
          'created_at': '2025-06-15T10:00:00.000Z',
          'updated_at': '2025-06-15T11:00:00.000Z',
          'full_name': 'John Doe',
          'avatar_url': 'https://example.com/avatar.jpg',
        };

        final voteModel = VoteModel.fromJson(json);

        expect(voteModel.id, 'vote-123');
        expect(voteModel.proposalId, 'proposal-456');
        expect(voteModel.timeOptionId, 'option-789');
        expect(voteModel.userId, 'user-abc');
        expect(voteModel.vote, VoteType.yes);
        expect(voteModel.userFullName, 'John Doe');
        expect(voteModel.userAvatarUrl, 'https://example.com/avatar.jpg');
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'v1',
          'proposal_id': 'p1',
          'time_option_id': 'o1',
          'user_id': 'u1',
          'vote': 'no',
          'created_at': '2025-06-15T10:00:00.000Z',
          'updated_at': null,
          'full_name': null,
          'avatar_url': null,
        };

        final voteModel = VoteModel.fromJson(json);

        expect(voteModel.updatedAt, isNull);
        expect(voteModel.userFullName, isNull);
        expect(voteModel.userAvatarUrl, isNull);
      });

      test('should parse all vote types', () {
        final voteTypes = ['yes', 'no', 'maybe'];

        for (final voteStr in voteTypes) {
          final json = {
            'id': 'v1',
            'proposal_id': 'p1',
            'time_option_id': 'o1',
            'user_id': 'u1',
            'vote': voteStr,
            'created_at': '2025-06-15T10:00:00.000Z',
          };

          final voteModel = VoteModel.fromJson(json);
          expect(voteModel.vote, VoteType.fromString(voteStr));
        }
      });
    });

    group('fromRpcJson', () {
      test('should parse RPC response correctly', () {
        final json = {
          'user_id': 'user-abc',
          'vote': 'yes',
          'voted_at': '2025-06-15T10:00:00.000Z',
          'full_name': 'John Doe',
          'avatar_url': 'https://example.com/avatar.jpg',
        };

        final voteModel = VoteModel.fromRpcJson(json, 'prop-123', 'opt-456');

        expect(voteModel.id, ''); // RPC doesn't return ID
        expect(voteModel.proposalId, 'prop-123');
        expect(voteModel.timeOptionId, 'opt-456');
        expect(voteModel.userId, 'user-abc');
        expect(voteModel.vote, VoteType.yes);
        expect(voteModel.userFullName, 'John Doe');
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        final voteModel = createTestVote();
        final json = voteModel.toJson();

        expect(json['proposal_id'], 'proposal-456');
        expect(json['time_option_id'], 'option-789');
        expect(json['user_id'], 'user-abc');
        expect(json['vote'], 'yes');
      });

      test('should serialize all vote types correctly', () {
        final yesVote = createTestVote(vote: VoteType.yes);
        final noVote = createTestVote(vote: VoteType.no);
        final maybeVote = createTestVote(vote: VoteType.maybe);

        expect(yesVote.toJson()['vote'], 'yes');
        expect(noVote.toJson()['vote'], 'no');
        expect(maybeVote.toJson()['vote'], 'maybe');
      });
    });

    group('copyWith', () {
      test('should create copy with updated vote', () {
        final original = createTestVote(vote: VoteType.yes);
        final copy = original.copyWith(vote: VoteType.no);

        expect(copy.vote, VoteType.no);
        expect(copy.id, original.id);
        expect(copy.userId, original.userId);
      });

      test('should preserve all fields when no changes specified', () {
        final original = createTestVote(
          userFullName: 'John',
          userAvatarUrl: 'https://example.com/avatar.jpg',
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.proposalId, original.proposalId);
        expect(copy.vote, original.vote);
        expect(copy.userFullName, original.userFullName);
        expect(copy.userAvatarUrl, original.userAvatarUrl);
      });
    });

    group('Equality', () {
      test('two votes with same composite key should be equal', () {
        final vote1 = createTestVote(
          id: 'v1',
          proposalId: 'p1',
          timeOptionId: 'o1',
          userId: 'u1',
        );
        final vote2 = createTestVote(
          id: 'v2', // Different ID
          proposalId: 'p1',
          timeOptionId: 'o1',
          userId: 'u1',
        );

        expect(vote1, equals(vote2));
      });

      test('two votes with different composite keys should not be equal', () {
        final vote1 = createTestVote(userId: 'u1');
        final vote2 = createTestVote(userId: 'u2');

        expect(vote1, isNot(equals(vote2)));
      });

      test('hashCode should be based on composite key', () {
        final vote1 = createTestVote(
          proposalId: 'p1',
          timeOptionId: 'o1',
          userId: 'u1',
        );
        final vote2 = createTestVote(
          proposalId: 'p1',
          timeOptionId: 'o1',
          userId: 'u1',
        );

        expect(vote1.hashCode, equals(vote2.hashCode));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final voteModel = createTestVote();
        final str = voteModel.toString();

        expect(str, contains('VoteModel'));
        expect(str, contains('user-abc'));
        expect(str, contains('yes'));
        expect(str, contains('option-789'));
      });
    });
  });

  group('VoteSummary', () {
    final testStartTime = DateTime(2025, 6, 15, 14, 0);
    final testEndTime = DateTime(2025, 6, 15, 15, 0);

    VoteSummary createTestSummary({
      String timeOptionId = 'option-123',
      DateTime? startTime,
      DateTime? endTime,
      int yesCount = 0,
      int maybeCount = 0,
      int noCount = 0,
      int totalVotes = 0,
    }) {
      return VoteSummary(
        timeOptionId: timeOptionId,
        startTime: startTime ?? testStartTime,
        endTime: endTime ?? testEndTime,
        yesCount: yesCount,
        maybeCount: maybeCount,
        noCount: noCount,
        totalVotes: totalVotes,
      );
    }

    group('Constructor', () {
      test('should create VoteSummary with required fields', () {
        final summary = createTestSummary();

        expect(summary.timeOptionId, 'option-123');
        expect(summary.startTime, testStartTime);
        expect(summary.endTime, testEndTime);
      });

      test('should have zero defaults for counts', () {
        final summary = createTestSummary();

        expect(summary.yesCount, 0);
        expect(summary.maybeCount, 0);
        expect(summary.noCount, 0);
        expect(summary.totalVotes, 0);
      });
    });

    group('fromJson', () {
      test('should parse JSON correctly', () {
        final json = {
          'time_option_id': 'option-123',
          'start_time': '2025-06-15T14:00:00.000Z',
          'end_time': '2025-06-15T15:00:00.000Z',
          'yes_count': 5,
          'maybe_count': 2,
          'no_count': 1,
          'total_votes': 8,
        };

        final summary = VoteSummary.fromJson(json);

        expect(summary.timeOptionId, 'option-123');
        expect(summary.yesCount, 5);
        expect(summary.maybeCount, 2);
        expect(summary.noCount, 1);
        expect(summary.totalVotes, 8);
      });

      test('should handle null counts', () {
        final json = {
          'time_option_id': 'o1',
          'start_time': '2025-06-15T14:00:00.000Z',
          'end_time': '2025-06-15T15:00:00.000Z',
          'yes_count': null,
          'maybe_count': null,
          'no_count': null,
          'total_votes': null,
        };

        final summary = VoteSummary.fromJson(json);

        expect(summary.yesCount, 0);
        expect(summary.maybeCount, 0);
        expect(summary.noCount, 0);
        expect(summary.totalVotes, 0);
      });
    });

    group('Computed Properties', () {
      test('score should calculate weighted value (yes=2, maybe=1, no=0)', () {
        final summary = createTestSummary(
          yesCount: 5,
          maybeCount: 3,
          noCount: 2,
        );

        expect(summary.score, 13); // (5*2) + 3 = 13
      });

      test('yesPercentage should calculate correctly', () {
        final summary = createTestSummary(yesCount: 5, totalVotes: 10);
        expect(summary.yesPercentage, 50.0);
      });

      test('maybePercentage should calculate correctly', () {
        final summary = createTestSummary(maybeCount: 3, totalVotes: 10);
        expect(summary.maybePercentage, 30.0);
      });

      test('noPercentage should calculate correctly', () {
        final summary = createTestSummary(noCount: 2, totalVotes: 10);
        expect(summary.noPercentage, 20.0);
      });

      test('percentages should return 0 when totalVotes is 0', () {
        final summary = createTestSummary(totalVotes: 0);

        expect(summary.yesPercentage, 0.0);
        expect(summary.maybePercentage, 0.0);
        expect(summary.noPercentage, 0.0);
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final summary = createTestSummary(
          yesCount: 5,
          maybeCount: 2,
          noCount: 1,
        );
        final str = summary.toString();

        expect(str, contains('VoteSummary'));
        expect(str, contains('option-123'));
        expect(str, contains('yes: 5'));
        expect(str, contains('maybe: 2'));
        expect(str, contains('no: 1'));
      });
    });
  });
}

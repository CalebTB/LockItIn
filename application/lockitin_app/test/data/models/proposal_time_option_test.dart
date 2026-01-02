import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/data/models/proposal_time_option.dart';
import 'package:lockitin_app/data/models/vote_model.dart';

void main() {
  group('ProposalTimeOption', () {
    final testStartTime = DateTime(2025, 6, 15, 14, 0);
    final testEndTime = DateTime(2025, 6, 15, 15, 0);

    ProposalTimeOption createTestOption({
      String? id,
      String? proposalId,
      DateTime? startTime,
      DateTime? endTime,
      int optionOrder = 1,
      int yesCount = 0,
      int maybeCount = 0,
      int noCount = 0,
      bool isSelected = false,
      VoteType? userVote,
    }) {
      return ProposalTimeOption(
        id: id,
        proposalId: proposalId,
        startTime: startTime ?? testStartTime,
        endTime: endTime ?? testEndTime,
        optionOrder: optionOrder,
        yesCount: yesCount,
        maybeCount: maybeCount,
        noCount: noCount,
        isSelected: isSelected,
        userVote: userVote,
      );
    }

    group('Constructor', () {
      test('should create ProposalTimeOption with required fields', () {
        final option = createTestOption();

        expect(option.startTime, testStartTime);
        expect(option.endTime, testEndTime);
      });

      test('should have default values for optional fields', () {
        final option = createTestOption();

        expect(option.id, isNull);
        expect(option.proposalId, isNull);
        expect(option.optionOrder, 1);
        expect(option.yesCount, 0);
        expect(option.maybeCount, 0);
        expect(option.noCount, 0);
        expect(option.isSelected, false);
        expect(option.userVote, isNull);
      });

      test('should accept all optional fields', () {
        final option = createTestOption(
          id: 'opt-123',
          proposalId: 'prop-456',
          optionOrder: 2,
          yesCount: 5,
          maybeCount: 3,
          noCount: 1,
          isSelected: true,
          userVote: VoteType.yes,
        );

        expect(option.id, 'opt-123');
        expect(option.proposalId, 'prop-456');
        expect(option.optionOrder, 2);
        expect(option.yesCount, 5);
        expect(option.maybeCount, 3);
        expect(option.noCount, 1);
        expect(option.isSelected, true);
        expect(option.userVote, VoteType.yes);
      });
    });

    group('Computed Properties', () {
      test('totalVotes should sum all vote counts', () {
        final option = createTestOption(
          yesCount: 5,
          maybeCount: 3,
          noCount: 2,
        );

        expect(option.totalVotes, 10);
      });

      test('voteCount should return yesCount for backward compatibility', () {
        final option = createTestOption(yesCount: 7);
        expect(option.voteCount, 7);
      });

      test('score should calculate weighted value (yes=2, maybe=1)', () {
        final option = createTestOption(
          yesCount: 5,
          maybeCount: 3,
          noCount: 2,
        );

        expect(option.score, 13); // (5*2) + 3 = 13
      });

      test('duration should return difference between end and start', () {
        final option = createTestOption(
          startTime: DateTime(2025, 6, 15, 14, 0),
          endTime: DateTime(2025, 6, 15, 16, 30),
        );

        expect(option.duration, const Duration(hours: 2, minutes: 30));
      });
    });

    group('overlapsWith', () {
      test('should return true for overlapping options', () {
        final option1 = createTestOption(
          startTime: DateTime(2025, 6, 15, 14, 0),
          endTime: DateTime(2025, 6, 15, 16, 0),
        );
        final option2 = createTestOption(
          startTime: DateTime(2025, 6, 15, 15, 0),
          endTime: DateTime(2025, 6, 15, 17, 0),
        );

        expect(option1.overlapsWith(option2), true);
        expect(option2.overlapsWith(option1), true);
      });

      test('should return true for fully contained options', () {
        final outer = createTestOption(
          startTime: DateTime(2025, 6, 15, 14, 0),
          endTime: DateTime(2025, 6, 15, 18, 0),
        );
        final inner = createTestOption(
          startTime: DateTime(2025, 6, 15, 15, 0),
          endTime: DateTime(2025, 6, 15, 17, 0),
        );

        expect(outer.overlapsWith(inner), true);
        expect(inner.overlapsWith(outer), true);
      });

      test('should return false for non-overlapping options', () {
        final option1 = createTestOption(
          startTime: DateTime(2025, 6, 15, 14, 0),
          endTime: DateTime(2025, 6, 15, 15, 0),
        );
        final option2 = createTestOption(
          startTime: DateTime(2025, 6, 15, 16, 0),
          endTime: DateTime(2025, 6, 15, 17, 0),
        );

        expect(option1.overlapsWith(option2), false);
        expect(option2.overlapsWith(option1), false);
      });

      test('should return false for adjacent options (end = start)', () {
        final option1 = createTestOption(
          startTime: DateTime(2025, 6, 15, 14, 0),
          endTime: DateTime(2025, 6, 15, 15, 0),
        );
        final option2 = createTestOption(
          startTime: DateTime(2025, 6, 15, 15, 0),
          endTime: DateTime(2025, 6, 15, 16, 0),
        );

        expect(option1.overlapsWith(option2), false);
      });
    });

    group('fromJson', () {
      test('should parse complete JSON correctly', () {
        final json = {
          'id': 'opt-123',
          'proposal_id': 'prop-456',
          'start_time': '2025-06-15T14:00:00.000Z',
          'end_time': '2025-06-15T15:00:00.000Z',
          'option_order': 2,
          'yes_count': 5,
          'maybe_count': 3,
          'no_count': 1,
          'user_vote': 'yes',
        };

        final option = ProposalTimeOption.fromJson(json);

        expect(option.id, 'opt-123');
        expect(option.proposalId, 'prop-456');
        expect(option.optionOrder, 2);
        expect(option.yesCount, 5);
        expect(option.maybeCount, 3);
        expect(option.noCount, 1);
        expect(option.userVote, VoteType.yes);
      });

      test('should handle null optional fields', () {
        final json = {
          'start_time': '2025-06-15T14:00:00.000Z',
          'end_time': '2025-06-15T15:00:00.000Z',
          'id': null,
          'proposal_id': null,
          'option_order': null,
          'yes_count': null,
          'maybe_count': null,
          'no_count': null,
          'user_vote': null,
        };

        final option = ProposalTimeOption.fromJson(json);

        expect(option.id, isNull);
        expect(option.proposalId, isNull);
        expect(option.optionOrder, 1);
        expect(option.yesCount, 0);
        expect(option.maybeCount, 0);
        expect(option.noCount, 0);
        expect(option.userVote, isNull);
      });

      test('should parse all user vote types', () {
        final voteTypes = ['yes', 'no', 'maybe'];

        for (final voteStr in voteTypes) {
          final json = {
            'start_time': '2025-06-15T14:00:00.000Z',
            'end_time': '2025-06-15T15:00:00.000Z',
            'user_vote': voteStr,
          };

          final option = ProposalTimeOption.fromJson(json);
          expect(option.userVote, VoteType.fromString(voteStr));
        }
      });
    });

    group('fromVoteSummary', () {
      test('should parse vote summary JSON correctly', () {
        final json = {
          'time_option_id': 'opt-123',
          'start_time': '2025-06-15T14:00:00.000Z',
          'end_time': '2025-06-15T15:00:00.000Z',
          'yes_count': 5,
          'maybe_count': 3,
          'no_count': 1,
        };

        final option = ProposalTimeOption.fromVoteSummary(json);

        expect(option.id, 'opt-123');
        expect(option.yesCount, 5);
        expect(option.maybeCount, 3);
        expect(option.noCount, 1);
      });

      test('should handle null counts in vote summary', () {
        final json = {
          'time_option_id': 'opt-123',
          'start_time': '2025-06-15T14:00:00.000Z',
          'end_time': '2025-06-15T15:00:00.000Z',
          'yes_count': null,
          'maybe_count': null,
          'no_count': null,
        };

        final option = ProposalTimeOption.fromVoteSummary(json);

        expect(option.yesCount, 0);
        expect(option.maybeCount, 0);
        expect(option.noCount, 0);
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        final option = createTestOption(
          id: 'opt-123',
          proposalId: 'prop-456',
          optionOrder: 2,
        );

        final json = option.toJson();

        expect(json['id'], 'opt-123');
        expect(json['proposal_id'], 'prop-456');
        expect(json['start_time'], testStartTime.toIso8601String());
        expect(json['end_time'], testEndTime.toIso8601String());
        expect(json['option_order'], 2);
      });

      test('should exclude null id and proposalId', () {
        final option = createTestOption();
        final json = option.toJson();

        expect(json.containsKey('id'), false);
        expect(json.containsKey('proposal_id'), false);
      });
    });

    group('toCreateJson', () {
      test('should return minimal JSON for creating proposals', () {
        final option = createTestOption(
          id: 'opt-123',
          proposalId: 'prop-456',
          optionOrder: 2,
          yesCount: 5,
        );

        final json = option.toCreateJson();

        expect(json.keys.length, 2);
        expect(json['start_time'], testStartTime.toIso8601String());
        expect(json['end_time'], testEndTime.toIso8601String());
        expect(json.containsKey('id'), false);
        expect(json.containsKey('proposal_id'), false);
        expect(json.containsKey('option_order'), false);
      });
    });

    group('copyWith', () {
      test('should create copy with updated times', () {
        final original = createTestOption();
        final newStart = DateTime(2025, 6, 20, 10, 0);
        final newEnd = DateTime(2025, 6, 20, 11, 0);

        final copy = original.copyWith(startTime: newStart, endTime: newEnd);

        expect(copy.startTime, newStart);
        expect(copy.endTime, newEnd);
      });

      test('should create copy with updated vote counts', () {
        final original = createTestOption();
        final copy = original.copyWith(yesCount: 10, maybeCount: 5, noCount: 2);

        expect(copy.yesCount, 10);
        expect(copy.maybeCount, 5);
        expect(copy.noCount, 2);
      });

      test('should create copy with updated selection state', () {
        final original = createTestOption(isSelected: false);
        final copy = original.copyWith(isSelected: true);

        expect(copy.isSelected, true);
        expect(original.isSelected, false);
      });

      test('should create copy with updated user vote', () {
        final original = createTestOption();
        final copy = original.copyWith(userVote: VoteType.no);

        expect(copy.userVote, VoteType.no);
        expect(original.userVote, isNull);
      });

      test('should preserve all fields when no changes specified', () {
        final original = createTestOption(
          id: 'opt-123',
          proposalId: 'prop-456',
          optionOrder: 2,
          yesCount: 5,
          maybeCount: 3,
          noCount: 1,
          isSelected: true,
          userVote: VoteType.yes,
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.proposalId, original.proposalId);
        expect(copy.startTime, original.startTime);
        expect(copy.endTime, original.endTime);
        expect(copy.optionOrder, original.optionOrder);
        expect(copy.yesCount, original.yesCount);
        expect(copy.maybeCount, original.maybeCount);
        expect(copy.noCount, original.noCount);
        expect(copy.isSelected, original.isSelected);
        expect(copy.userVote, original.userVote);
      });
    });

    group('Equality', () {
      test('two options with same id and times should be equal', () {
        final opt1 = createTestOption(id: 'opt-1');
        final opt2 = createTestOption(id: 'opt-1');

        expect(opt1, equals(opt2));
      });

      test('two options with different ids should not be equal', () {
        final opt1 = createTestOption(id: 'opt-1');
        final opt2 = createTestOption(id: 'opt-2');

        expect(opt1, isNot(equals(opt2)));
      });

      test('two options with different times should not be equal', () {
        final opt1 = createTestOption(
          startTime: DateTime(2025, 6, 15, 14, 0),
        );
        final opt2 = createTestOption(
          startTime: DateTime(2025, 6, 15, 15, 0),
        );

        expect(opt1, isNot(equals(opt2)));
      });

      test('hashCode should be based on id and times', () {
        final opt1 = createTestOption(id: 'opt-1');
        final opt2 = createTestOption(id: 'opt-1');

        expect(opt1.hashCode, equals(opt2.hashCode));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final option = createTestOption(
          yesCount: 5,
          maybeCount: 3,
          noCount: 1,
        );
        final str = option.toString();

        expect(str, contains('ProposalTimeOption'));
        expect(str, contains('yes: 5'));
        expect(str, contains('maybe: 3'));
        expect(str, contains('no: 1'));
      });
    });

    group('JSON Round Trip', () {
      test('should survive JSON serialization and deserialization', () {
        final original = createTestOption(
          id: 'opt-123',
          proposalId: 'prop-456',
          optionOrder: 2,
          yesCount: 5,
          maybeCount: 3,
          noCount: 1,
          userVote: VoteType.yes,
        );

        final json = original.toJson();
        // Add vote data for round trip
        json['yes_count'] = original.yesCount;
        json['maybe_count'] = original.maybeCount;
        json['no_count'] = original.noCount;
        json['user_vote'] = original.userVote?.name;

        final restored = ProposalTimeOption.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.proposalId, original.proposalId);
        expect(restored.optionOrder, original.optionOrder);
        expect(restored.yesCount, original.yesCount);
        expect(restored.maybeCount, original.maybeCount);
        expect(restored.noCount, original.noCount);
        expect(restored.userVote, original.userVote);
      });
    });
  });
}

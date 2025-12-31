import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    group('App Information', () {
      test('appName should be LockItIn', () {
        expect(AppConstants.appName, 'LockItIn');
      });

      test('appVersion should follow semver format', () {
        expect(AppConstants.appVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
      });
    });

    group('Privacy Settings', () {
      test('privacyPrivate should be private', () {
        expect(AppConstants.privacyPrivate, 'private');
      });

      test('privacySharedWithName should be shared_with_name', () {
        expect(AppConstants.privacySharedWithName, 'shared_with_name');
      });

      test('privacyBusyOnly should be busy_only', () {
        expect(AppConstants.privacyBusyOnly, 'busy_only');
      });

      test('all privacy constants should be unique', () {
        final values = {
          AppConstants.privacyPrivate,
          AppConstants.privacySharedWithName,
          AppConstants.privacyBusyOnly,
        };
        expect(values.length, 3);
      });
    });

    group('Supabase Table Names', () {
      test('usersTable should be users', () {
        expect(AppConstants.usersTable, 'users');
      });

      test('eventsTable should be events', () {
        expect(AppConstants.eventsTable, 'events');
      });

      test('groupsTable should be groups', () {
        expect(AppConstants.groupsTable, 'groups');
      });

      test('groupMembersTable should be group_members', () {
        expect(AppConstants.groupMembersTable, 'group_members');
      });

      test('friendshipsTable should be friendships', () {
        expect(AppConstants.friendshipsTable, 'friendships');
      });

      test('eventProposalsTable should be event_proposals', () {
        expect(AppConstants.eventProposalsTable, 'event_proposals');
      });

      test('proposalOptionsTable should be proposal_time_options', () {
        expect(AppConstants.proposalOptionsTable, 'proposal_time_options');
      });

      test('proposalVotesTable should be proposal_votes', () {
        expect(AppConstants.proposalVotesTable, 'proposal_votes');
      });

      test('shadowCalendarTable should be shadow_calendar', () {
        expect(AppConstants.shadowCalendarTable, 'shadow_calendar');
      });

      test('notificationsTable should be notifications', () {
        expect(AppConstants.notificationsTable, 'notifications');
      });

      test('all table names should use snake_case', () {
        final tables = [
          AppConstants.usersTable,
          AppConstants.eventsTable,
          AppConstants.groupsTable,
          AppConstants.groupMembersTable,
          AppConstants.friendshipsTable,
          AppConstants.eventProposalsTable,
          AppConstants.proposalOptionsTable,
          AppConstants.proposalVotesTable,
          AppConstants.shadowCalendarTable,
          AppConstants.notificationsTable,
        ];

        for (final table in tables) {
          expect(table, matches(RegExp(r'^[a-z_]+$')),
              reason: '$table should be snake_case');
        }
      });
    });

    group('Calendar Sync', () {
      test('calendarSyncIntervalMinutes should be 15', () {
        expect(AppConstants.calendarSyncIntervalMinutes, 15);
      });

      test('calendarLookbackDays should be 30', () {
        expect(AppConstants.calendarLookbackDays, 30);
      });

      test('calendarLookaheadDays should be 60', () {
        expect(AppConstants.calendarLookaheadDays, 60);
      });

      test('lookahead should be greater than lookback', () {
        expect(
          AppConstants.calendarLookaheadDays,
          greaterThan(AppConstants.calendarLookbackDays),
        );
      });
    });

    group('UI Constants', () {
      test('maxGroupNameLength should be 50', () {
        expect(AppConstants.maxGroupNameLength, 50);
      });

      test('maxEventTitleLength should be 100', () {
        expect(AppConstants.maxEventTitleLength, 100);
      });

      test('maxGroupMembers should be 50', () {
        expect(AppConstants.maxGroupMembers, 50);
      });

      test('max lengths should be positive', () {
        expect(AppConstants.maxGroupNameLength, greaterThan(0));
        expect(AppConstants.maxEventTitleLength, greaterThan(0));
        expect(AppConstants.maxGroupMembers, greaterThan(0));
      });
    });

    group('Error Messages', () {
      test('errorGeneric should be non-empty', () {
        expect(AppConstants.errorGeneric, isNotEmpty);
      });

      test('errorNetwork should be non-empty', () {
        expect(AppConstants.errorNetwork, isNotEmpty);
      });

      test('errorAuth should be non-empty', () {
        expect(AppConstants.errorAuth, isNotEmpty);
      });

      test('errorPermission should be non-empty', () {
        expect(AppConstants.errorPermission, isNotEmpty);
      });

      test('all error messages should be unique', () {
        final messages = {
          AppConstants.errorGeneric,
          AppConstants.errorNetwork,
          AppConstants.errorAuth,
          AppConstants.errorPermission,
        };
        expect(messages.length, 4);
      });
    });
  });
}

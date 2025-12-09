/// Application-wide constants

class AppConstants {
  // App Information
  static const String appName = 'LockItIn';
  static const String appVersion = '0.1.0';

  // Privacy Settings
  static const String privacyPrivate = 'private';
  static const String privacySharedWithName = 'shared_with_name';
  static const String privacyBusyOnly = 'busy_only';

  // Supabase Table Names
  static const String usersTable = 'users';
  static const String eventsTable = 'events';
  static const String groupsTable = 'groups';
  static const String groupMembersTable = 'group_members';
  static const String friendshipsTable = 'friendships';
  static const String eventProposalsTable = 'event_proposals';
  static const String proposalOptionsTable = 'proposal_time_options';
  static const String proposalVotesTable = 'proposal_votes';
  static const String shadowCalendarTable = 'shadow_calendar';
  static const String notificationsTable = 'notifications';

  // Calendar Sync
  static const int calendarSyncIntervalMinutes = 15;
  static const int calendarLookbackDays = 30;
  static const int calendarLookaheadDays = 60;

  // UI Constants
  static const int maxGroupNameLength = 50;
  static const int maxEventTitleLength = 100;
  static const int maxGroupMembers = 50;

  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Check your connection.';
  static const String errorAuth = 'Authentication failed. Please log in again.';
  static const String errorPermission = 'Permission denied.';
}

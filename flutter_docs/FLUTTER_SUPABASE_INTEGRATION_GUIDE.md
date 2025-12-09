# Flutter + Supabase Integration Guide for LockItIn

**Complete Production-Ready Integration Patterns for Calendar App Development**

**Last Updated:** December 8, 2025
**Target Platform:** Flutter (iOS/Android)
**Backend:** Supabase (PostgreSQL + Auth + Realtime + Storage)
**Project:** LockItIn - Privacy-First Group Event Planning Calendar

---

## Table of Contents

1. [Introduction](#introduction)
2. [Project Setup](#project-setup)
3. [Authentication Flows](#authentication-flows)
4. [Database Operations](#database-operations)
5. [Row Level Security (RLS) Patterns](#row-level-security-rls-patterns)
6. [Real-Time Subscriptions](#real-time-subscriptions)
7. [Offline-First Patterns](#offline-first-patterns)
8. [Platform Channels for Native Calendar Access](#platform-channels-for-native-calendar-access)
9. [Push Notifications](#push-notifications)
10. [File Storage](#file-storage)
11. [Error Handling](#error-handling)
12. [Performance Optimization](#performance-optimization)
13. [Testing Strategies](#testing-strategies)
14. [Security Best Practices](#security-best-practices)
15. [LockItIn-Specific Examples](#lockitin-specific-examples)

---

## Introduction

### Why Flutter + Supabase for LockItIn?

**Flutter Advantages:**
- Cross-platform (iOS/Android) from single codebase
- Native performance and UI
- Hot reload for rapid development
- Strong type safety with Dart
- Rich ecosystem of packages

**Supabase Advantages:**
- PostgreSQL with powerful relational queries
- Built-in authentication (JWT-based)
- Real-time WebSocket subscriptions
- Row Level Security (RLS) for privacy enforcement
- Managed infrastructure (no DevOps overhead)
- Open-source and self-hostable

**LockItIn Requirements Met:**
- Shadow Calendar privacy system → RLS policies
- Real-time voting updates → Realtime subscriptions
- Group coordination → Multi-tenant data isolation
- Native calendar sync → Platform channels
- Push notifications → Edge Functions + FCM/APNs

---

## Project Setup

### 1. Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Supabase
  supabase_flutter: ^2.5.0

  # Secure storage for tokens
  flutter_secure_storage: ^9.0.0

  # State management
  riverpod: ^2.5.0
  flutter_riverpod: ^2.5.0

  # Local database for offline support
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Native calendar access
  device_calendar: ^4.5.0

  # Push notifications
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0

  # Networking & HTTP
  http: ^1.2.0

  # Utilities
  connectivity_plus: ^5.0.2
  uuid: ^4.3.3

dev_dependencies:
  build_runner: ^2.4.8
  hive_generator: ^2.0.1
  mockito: ^5.4.4
```

### 2. Initialize Supabase

**`lib/main.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // More secure for mobile
      autoRefreshToken: true,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10, // Rate limiting for real-time events
    ),
  );

  runApp(
    const ProviderScope(
      child: LockItInApp(),
    ),
  );
}

// Global Supabase client accessor
final supabase = Supabase.instance.client;
```

### 3. Environment Configuration

**`.env` file (DO NOT commit to git):**

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

**Load environment variables:**

```dart
// Use flutter_dotenv package
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
}
```

---

## Authentication Flows

### 1. Email/Password Authentication

**`lib/services/auth_service.dart`:**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.user == null) {
        throw Exception('Sign up failed - no user returned');
      }

      return response;
    } on AuthException catch (e) {
      // Handle specific auth errors
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // Handle auth exceptions
  String _handleAuthException(AuthException error) {
    switch (error.statusCode) {
      case '400':
        return 'Invalid email or password';
      case '422':
        return 'Email already registered';
      case '429':
        return 'Too many requests. Please try again later.';
      default:
        return error.message;
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.lockitin.app://reset-callback',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
}
```

### 2. OAuth Authentication (Google/Apple Sign-In)

**Google Sign-In:**

```dart
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: 'YOUR_GOOGLE_CLIENT_ID',
    serverClientId: 'YOUR_WEB_CLIENT_ID', // For backend verification
  );

  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Sign in to Supabase with Google credentials
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      return response;
    } catch (e) {
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }
}
```

**Apple Sign-In:**

```dart
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  Future<AuthResponse> signInWithApple() async {
    try {
      // Trigger Apple Sign-In flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Sign in to Supabase with Apple credentials
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        nonce: credential.nonce,
      );

      return response;
    } catch (e) {
      throw Exception('Apple sign-in failed: ${e.toString()}');
    }
  }
}
```

### 3. Secure Token Storage

**Store session tokens securely:**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Store auth token
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Retrieve auth token
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Delete token (on logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Delete all stored data
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
```

### 4. Auth State Management with Riverpod

**`lib/providers/auth_provider.dart`:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Auth state provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
```

**Usage in UI:**

```dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        if (state.session != null) {
          // User is authenticated - navigate to home
          return HomeScreen();
        } else {
          // Show login form
          return LoginForm();
        }
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error: error),
    );
  }
}
```

---

## Database Operations

### 1. Type-Safe Dart Models

**`lib/models/event.dart`:**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'event.g.dart'; // Generated file

@JsonSerializable()
class Event {
  final String id;
  final String userId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final String? location;
  final EventVisibility visibility;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.userId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.location,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON serialization
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
  Map<String, dynamic> toJson() => _$EventToJson(this);
}

enum EventVisibility {
  @JsonValue('private')
  private,

  @JsonValue('shared_with_name')
  sharedWithName,

  @JsonValue('busy_only')
  busyOnly,
}
```

**Generate serialization code:**

```bash
flutter pub run build_runner build
```

### 2. CRUD Operations with Error Handling

**`lib/repositories/event_repository.dart`:**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class EventRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // CREATE: Insert new event
  Future<Event> createEvent(Event event) async {
    try {
      final response = await _supabase
          .from('events')
          .insert(event.toJson())
          .select()
          .single();

      return Event.fromJson(response);
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e);
    } catch (e) {
      throw Exception('Failed to create event: ${e.toString()}');
    }
  }

  // READ: Get user's events
  Future<List<Event>> getUserEvents(String userId) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('user_id', userId)
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => Event.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e);
    }
  }

  // READ: Get events in date range
  Future<List<Event>> getEventsInRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('user_id', userId)
          .gte('start_time', start.toIso8601String())
          .lte('end_time', end.toIso8601String())
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => Event.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e);
    }
  }

  // UPDATE: Modify existing event
  Future<Event> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('events')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', eventId)
          .select()
          .single();

      return Event.fromJson(response);
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e);
    }
  }

  // DELETE: Remove event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _supabase
          .from('events')
          .delete()
          .eq('id', eventId);
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e);
    }
  }

  // Handle Postgrest exceptions
  String _handlePostgrestException(PostgrestException error) {
    switch (error.code) {
      case 'PGRST116':
        return 'No data found';
      case '23505':
        return 'Duplicate entry';
      case '23503':
        return 'Referenced record does not exist';
      default:
        return error.message;
    }
  }
}
```

### 3. Complex Queries

**Join queries with filters:**

```dart
// Get events with group information
Future<List<Map<String, dynamic>>> getGroupEvents(String groupId) async {
  final response = await _supabase
      .from('events')
      .select('''
        *,
        groups!inner(
          id,
          name,
          group_members!inner(user_id)
        )
      ''')
      .eq('groups.id', groupId)
      .gte('start_time', DateTime.now().toIso8601String())
      .order('start_time', ascending: true);

  return response as List<Map<String, dynamic>>;
}
```

**Count queries:**

```dart
// Count user's events
Future<int> getEventCount(String userId) async {
  final response = await _supabase
      .from('events')
      .select('id', const FetchOptions(count: CountOption.exact))
      .eq('user_id', userId);

  return response.count ?? 0;
}
```

### 4. Batch Operations

**Bulk insert:**

```dart
Future<List<Event>> createMultipleEvents(List<Event> events) async {
  try {
    final response = await _supabase
        .from('events')
        .insert(events.map((e) => e.toJson()).toList())
        .select();

    return (response as List)
        .map((json) => Event.fromJson(json))
        .toList();
  } on PostgrestException catch (e) {
    throw _handlePostgrestException(e);
  }
}
```

**Bulk update:**

```dart
// Update multiple events by IDs
Future<void> updateMultipleEvents(List<String> eventIds, Map<String, dynamic> updates) async {
  await _supabase
      .from('events')
      .update(updates)
      .in_('id', eventIds);
}
```

**Bulk delete:**

```dart
// Delete events by criteria
Future<void> deleteEventsByGroup(String groupId) async {
  await _supabase
      .from('events')
      .delete()
      .eq('group_id', groupId);
}
```

### 5. Pagination

**Offset-based pagination (simple datasets):**

```dart
Future<List<Event>> getEventsPaginated({
  required int page,
  required int itemsPerPage,
}) async {
  final from = page * itemsPerPage;
  final to = from + itemsPerPage - 1;

  final response = await _supabase
      .from('events')
      .select()
      .range(from, to)
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => Event.fromJson(json))
      .toList();
}
```

**Cursor-based pagination (large datasets):**

```dart
Future<List<Event>> getEventsWithCursor({
  String? lastEventId,
  int limit = 20,
}) async {
  var query = _supabase
      .from('events')
      .select()
      .order('created_at', ascending: false)
      .limit(limit);

  if (lastEventId != null) {
    // Get events created before the last event
    final lastEvent = await _supabase
        .from('events')
        .select('created_at')
        .eq('id', lastEventId)
        .single();

    query = query.lt('created_at', lastEvent['created_at']);
  }

  final response = await query;

  return (response as List)
      .map((json) => Event.fromJson(json))
      .toList();
}
```

---

## Row Level Security (RLS) Patterns

### Overview

Row Level Security (RLS) is **critical** for LockItIn's Shadow Calendar privacy system. RLS policies enforce privacy rules at the **database level**, ensuring users can only access data they're authorized to see.

### 1. Shadow Calendar Privacy Implementation

**SQL Policies for `events` table:**

```sql
-- Enable RLS on events table
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can see their own events (all visibility levels)
CREATE POLICY "Users can view own events"
ON events FOR SELECT
USING (auth.uid() = user_id);

-- Policy 2: Users can insert their own events
CREATE POLICY "Users can insert own events"
ON events FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy 3: Users can update their own events
CREATE POLICY "Users can update own events"
ON events FOR UPDATE
USING (auth.uid() = user_id);

-- Policy 4: Users can delete their own events
CREATE POLICY "Users can delete own events"
ON events FOR DELETE
USING (auth.uid() = user_id);

-- Policy 5: Group members can see SHARED events
CREATE POLICY "Group members can view shared events"
ON events FOR SELECT
USING (
  visibility = 'shared_with_name' AND
  EXISTS (
    SELECT 1 FROM group_members gm
    JOIN calendar_sharing cs ON cs.group_id = gm.group_id
    WHERE gm.user_id = auth.uid()
      AND cs.user_id = events.user_id
      AND cs.group_id = gm.group_id
      AND cs.is_enabled = true
  )
);

-- Policy 6: Group members can see BUSY-ONLY status (aggregate only)
-- This is handled at the application layer by querying availability
-- rather than full event details
```

### 2. Multi-Tenant Data Isolation (Groups)

**SQL Policies for `groups` and `group_members` tables:**

```sql
-- Enable RLS on groups
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

-- Users can only see groups they're members of
CREATE POLICY "Users can view their groups"
ON groups FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = groups.id
      AND user_id = auth.uid()
  )
);

-- Only group owners can update group settings
CREATE POLICY "Group owners can update groups"
ON groups FOR UPDATE
USING (owner_id = auth.uid());

-- Group members with admin role can invite others
CREATE POLICY "Admins can insert group members"
ON group_members FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = group_members.group_id
      AND user_id = auth.uid()
      AND role IN ('owner', 'admin')
  )
);
```

### 3. Event Proposals and Voting Privacy

**SQL Policies for `event_proposals` and `proposal_votes`:**

```sql
-- Enable RLS on event proposals
ALTER TABLE event_proposals ENABLE ROW LEVEL SECURITY;

-- Group members can see proposals in their groups
CREATE POLICY "Group members can view proposals"
ON event_proposals FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = event_proposals.group_id
      AND user_id = auth.uid()
  )
);

-- Group members can create proposals
CREATE POLICY "Group members can create proposals"
ON event_proposals FOR INSERT
WITH CHECK (
  auth.uid() = organizer_id AND
  EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = event_proposals.group_id
      AND user_id = auth.uid()
  )
);

-- Enable RLS on proposal votes
ALTER TABLE proposal_votes ENABLE ROW LEVEL SECURITY;

-- Group members can see votes on proposals in their groups
CREATE POLICY "Group members can view votes"
ON proposal_votes FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM event_proposals ep
    JOIN group_members gm ON gm.group_id = ep.group_id
    WHERE ep.id = proposal_votes.proposal_id
      AND gm.user_id = auth.uid()
  )
);

-- Users can only insert/update their own votes
CREATE POLICY "Users can manage own votes"
ON proposal_votes FOR ALL
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
```

### 4. Testing RLS Policies from Flutter

**Verify RLS enforcement:**

```dart
class RLSTestService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Test 1: Verify user can only see own private events
  Future<void> testPrivateEventAccess() async {
    try {
      // Attempt to query all events
      final response = await _supabase
          .from('events')
          .select()
          .eq('visibility', 'private');

      final events = (response as List).map((e) => Event.fromJson(e)).toList();

      // Verify all returned events belong to current user
      final currentUserId = _supabase.auth.currentUser!.id;
      final hasOtherUsersEvents = events.any((e) => e.userId != currentUserId);

      if (hasOtherUsersEvents) {
        throw Exception('RLS VIOLATION: User can see other users private events!');
      }

      print('✅ RLS Test Passed: Private events isolated');
    } catch (e) {
      print('❌ RLS Test Failed: ${e.toString()}');
    }
  }

  // Test 2: Verify group member can see shared events
  Future<void> testGroupSharedEventAccess(String groupId) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('visibility', 'shared_with_name');

      print('✅ RLS Test Passed: Group shared events visible');
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        print('✅ RLS Test Passed: No shared events or not in group');
      } else {
        print('❌ RLS Test Failed: ${e.message}');
      }
    }
  }
}
```

### 5. Performance Considerations for RLS

**Optimize RLS policies with indexes:**

```sql
-- Index on user_id for faster RLS checks
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_group_members_user_id ON group_members(user_id);
CREATE INDEX idx_group_members_group_id ON group_members(group_id);

-- Composite index for calendar sharing lookups
CREATE INDEX idx_calendar_sharing_user_group ON calendar_sharing(user_id, group_id);
```

**Cache RLS checks with functions:**

```sql
-- Wrap auth.uid() in select to cache result per query
CREATE FUNCTION get_current_user_id()
RETURNS uuid AS $$
  SELECT auth.uid();
$$ LANGUAGE sql STABLE;

-- Use in policies
CREATE POLICY "Users can view own events"
ON events FOR SELECT
USING (user_id = get_current_user_id());
```

---

## Real-Time Subscriptions

### Overview

Supabase Realtime uses PostgreSQL's replication functionality to broadcast database changes over WebSockets. Perfect for LockItIn's real-time voting feature.

### 1. Enable Realtime on Tables

**In Supabase Dashboard:**
1. Navigate to Database → Replication
2. Select tables: `event_proposals`, `proposal_votes`, `proposal_time_options`
3. Enable replication for INSERT, UPDATE, DELETE events

### 2. Basic Real-Time Subscription

**`lib/services/realtime_service.dart`:**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class RealtimeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  // Subscribe to proposal votes for live updates
  Stream<List<ProposalVote>> subscribeToProposalVotes(String proposalId) {
    final controller = StreamController<List<ProposalVote>>();

    // Initial data fetch
    _loadInitialVotes(proposalId).then((votes) {
      controller.add(votes);
    });

    // Setup realtime subscription
    _channel = _supabase
        .channel('proposal_votes:$proposalId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'proposal_votes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'proposal_id',
            value: proposalId,
          ),
          callback: (payload) async {
            // Reload votes when any change occurs
            final updatedVotes = await _loadInitialVotes(proposalId);
            controller.add(updatedVotes);
          },
        )
        .subscribe();

    return controller.stream;
  }

  // Load initial votes
  Future<List<ProposalVote>> _loadInitialVotes(String proposalId) async {
    final response = await _supabase
        .from('proposal_votes')
        .select()
        .eq('proposal_id', proposalId);

    return (response as List)
        .map((json) => ProposalVote.fromJson(json))
        .toList();
  }

  // Unsubscribe (call in dispose)
  void dispose() {
    _channel?.unsubscribe();
  }
}
```

### 3. Real-Time with StreamBuilder

**Usage in UI:**

```dart
class VotingScreen extends StatefulWidget {
  final String proposalId;

  const VotingScreen({required this.proposalId});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  late RealtimeService _realtimeService;
  late Stream<List<ProposalVote>> _votesStream;

  @override
  void initState() {
    super.initState();
    _realtimeService = RealtimeService();
    _votesStream = _realtimeService.subscribeToProposalVotes(widget.proposalId);
  }

  @override
  void dispose() {
    _realtimeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProposalVote>>(
      stream: _votesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final votes = snapshot.data ?? [];

        return ListView.builder(
          itemCount: votes.length,
          itemBuilder: (context, index) {
            return VoteCard(vote: votes[index]);
          },
        );
      },
    );
  }
}
```

### 4. Optimistic UI Updates

**Update UI immediately, rollback on error:**

```dart
class VotingViewModel extends ChangeNotifier {
  final VoteRepository _voteRepository;
  List<ProposalVote> _votes = [];

  VotingViewModel(this._voteRepository);

  Future<void> castVote({
    required String proposalId,
    required String timeOptionId,
    required VoteStatus status,
  }) async {
    // Create optimistic vote
    final optimisticVote = ProposalVote(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      proposalId: proposalId,
      timeOptionId: timeOptionId,
      userId: _currentUserId,
      status: status,
      createdAt: DateTime.now(),
    );

    // Add to local state immediately
    _votes.add(optimisticVote);
    notifyListeners();

    try {
      // Persist to backend
      final savedVote = await _voteRepository.createVote(optimisticVote);

      // Replace optimistic vote with real one
      final index = _votes.indexWhere((v) => v.id == optimisticVote.id);
      _votes[index] = savedVote;
      notifyListeners();
    } catch (e) {
      // Rollback on error
      _votes.removeWhere((v) => v.id == optimisticVote.id);
      notifyListeners();

      throw Exception('Failed to cast vote: ${e.toString()}');
    }
  }
}
```

### 5. Presence Tracking (Who's Online)

**Track which group members are viewing a proposal:**

```dart
class PresenceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _presenceChannel;

  Stream<Map<String, dynamic>> trackPresence({
    required String proposalId,
    required String userId,
    required String userName,
  }) {
    final controller = StreamController<Map<String, dynamic>>();

    _presenceChannel = _supabase.channel('proposal_presence:$proposalId');

    // Track presence
    _presenceChannel!
        .onPresenceSync(() {
          final state = _presenceChannel!.presenceState();
          controller.add(state);
        })
        .onPresenceJoin((payload) {
          print('User joined: ${payload.newPresences}');
        })
        .onPresenceLeave((payload) {
          print('User left: ${payload.leftPresences}');
        })
        .subscribe(
          (status, error) async {
            if (status == RealtimeSubscribeStatus.subscribed) {
              // Track this user
              await _presenceChannel!.track({
                'user_id': userId,
                'user_name': userName,
                'online_at': DateTime.now().toIso8601String(),
              });
            }
          },
        );

    return controller.stream;
  }

  void stopTracking() {
    _presenceChannel?.untrack();
    _presenceChannel?.unsubscribe();
  }
}
```

### 6. Performance Best Practices

**Debounce high-frequency updates:**

```dart
import 'dart:async';

class DebouncedRealtimeService {
  Timer? _debounceTimer;
  List<ProposalVote> _pendingVotes = [];

  Stream<List<ProposalVote>> subscribeWithDebounce(
    String proposalId, {
    Duration debounce = const Duration(milliseconds: 300),
  }) {
    final controller = StreamController<List<ProposalVote>>();

    _supabase
        .channel('proposal_votes:$proposalId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'proposal_votes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'proposal_id',
            value: proposalId,
          ),
          callback: (payload) {
            // Cancel previous timer
            _debounceTimer?.cancel();

            // Start new timer
            _debounceTimer = Timer(debounce, () async {
              final votes = await _loadVotes(proposalId);
              controller.add(votes);
            });
          },
        )
        .subscribe();

    return controller.stream;
  }
}
```

**Rate limiting:**

```dart
// In Supabase initialization
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
  realtimeClientOptions: const RealtimeClientOptions(
    eventsPerSecond: 10, // Max 10 events per second
  ),
);
```

---

## Offline-First Patterns

### Overview

Mobile apps must work offline. LockItIn needs to:
- Cache calendar events locally
- Queue mutations (create/update/delete) when offline
- Sync when connection is restored
- Handle conflicts gracefully

### 1. Local Database with Hive

**Setup Hive:**

```dart
import 'package:hive_flutter/hive_flutter.dart';

Future<void> initHive() async {
  await Hive.initFlutter();

  // Register adapters for custom types
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(ProposalAdapter());

  // Open boxes
  await Hive.openBox<Event>('events');
  await Hive.openBox<Map>('offline_queue');
}
```

**Hive Model:**

```dart
import 'package:hive/hive.dart';

part 'event.g.dart'; // Generated file

@HiveType(typeId: 0)
class Event extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String title;

  @HiveField(3)
  DateTime startTime;

  @HiveField(4)
  DateTime endTime;

  @HiveField(5)
  String visibility;

  Event({
    required this.id,
    required this.userId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.visibility,
  });
}
```

### 2. Cache Strategy

**`lib/services/cache_service.dart`:**

```dart
import 'package:hive/hive.dart';

class CacheService {
  final Box<Event> _eventsBox = Hive.box<Event>('events');

  // Cache events
  Future<void> cacheEvents(List<Event> events) async {
    for (final event in events) {
      await _eventsBox.put(event.id, event);
    }
  }

  // Get cached events
  List<Event> getCachedEvents() {
    return _eventsBox.values.toList();
  }

  // Get cached events in date range
  List<Event> getCachedEventsInRange(DateTime start, DateTime end) {
    return _eventsBox.values
        .where((event) =>
            event.startTime.isAfter(start) &&
            event.endTime.isBefore(end))
        .toList();
  }

  // Clear cache
  Future<void> clearCache() async {
    await _eventsBox.clear();
  }

  // Cache single event
  Future<void> cacheEvent(Event event) async {
    await _eventsBox.put(event.id, event);
  }

  // Remove cached event
  Future<void> removeCachedEvent(String eventId) async {
    await _eventsBox.delete(eventId);
  }
}
```

### 3. Offline Queue for Mutations

**Queue pending operations:**

```dart
class OfflineQueueService {
  final Box<Map> _queueBox = Hive.box<Map>('offline_queue');

  // Queue operation
  Future<void> queueOperation({
    required String type, // 'create', 'update', 'delete'
    required String table,
    required Map<String, dynamic> data,
  }) async {
    final operation = {
      'id': Uuid().v4(),
      'type': type,
      'table': table,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _queueBox.add(operation);
  }

  // Process queue when online
  Future<void> processQueue() async {
    final operations = _queueBox.values.toList();

    for (final operation in operations) {
      try {
        await _executeOperation(operation);

        // Remove from queue on success
        final key = _queueBox.keys.firstWhere(
          (key) => _queueBox.get(key)!['id'] == operation['id'],
        );
        await _queueBox.delete(key);
      } catch (e) {
        print('Failed to process operation: ${e.toString()}');
        // Keep in queue to retry later
      }
    }
  }

  Future<void> _executeOperation(Map operation) async {
    final type = operation['type'];
    final table = operation['table'];
    final data = operation['data'];

    switch (type) {
      case 'create':
        await _supabase.from(table).insert(data);
        break;
      case 'update':
        await _supabase.from(table).update(data).eq('id', data['id']);
        break;
      case 'delete':
        await _supabase.from(table).delete().eq('id', data['id']);
        break;
    }
  }

  // Get pending operations count
  int getPendingCount() => _queueBox.length;
}
```

### 4. Connectivity Monitoring

**Auto-sync on connection restored:**

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final OfflineQueueService _queueService;

  ConnectivityService(this._queueService) {
    _init();
  }

  void _init() {
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      if (_isConnected(result)) {
        _onConnected();
      } else {
        _onDisconnected();
      }
    });
  }

  bool _isConnected(List<ConnectivityResult> result) {
    return result.contains(ConnectivityResult.mobile) ||
           result.contains(ConnectivityResult.wifi);
  }

  Future<void> _onConnected() async {
    print('Connection restored - syncing...');

    try {
      // Process offline queue
      await _queueService.processQueue();

      // Refresh data from server
      await _refreshData();

      print('Sync completed successfully');
    } catch (e) {
      print('Sync failed: ${e.toString()}');
    }
  }

  void _onDisconnected() {
    print('Connection lost - offline mode');
  }

  Future<void> _refreshData() async {
    // Implement data refresh logic
  }
}
```

### 5. Repository Pattern with Offline Support

**`lib/repositories/offline_first_repository.dart`:**

```dart
class OfflineFirstEventRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CacheService _cache;
  final OfflineQueueService _queue;
  final Connectivity _connectivity = Connectivity();

  OfflineFirstEventRepository(this._cache, this._queue);

  // Get events (cache-first)
  Future<List<Event>> getEvents() async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        // Fetch from server
        final response = await _supabase
            .from('events')
            .select()
            .order('start_time');

        final events = (response as List)
            .map((json) => Event.fromJson(json))
            .toList();

        // Update cache
        await _cache.cacheEvents(events);

        return events;
      } catch (e) {
        print('Server fetch failed, using cache: ${e.toString()}');
        return _cache.getCachedEvents();
      }
    } else {
      // Return cached data when offline
      return _cache.getCachedEvents();
    }
  }

  // Create event (offline-first)
  Future<Event> createEvent(Event event) async {
    final isOnline = await _isOnline();

    // Add to cache immediately
    await _cache.cacheEvent(event);

    if (isOnline) {
      try {
        // Persist to server
        final response = await _supabase
            .from('events')
            .insert(event.toJson())
            .select()
            .single();

        final savedEvent = Event.fromJson(response);

        // Update cache with server version
        await _cache.cacheEvent(savedEvent);

        return savedEvent;
      } catch (e) {
        // Queue for later sync
        await _queue.queueOperation(
          type: 'create',
          table: 'events',
          data: event.toJson(),
        );

        return event;
      }
    } else {
      // Queue for later sync
      await _queue.queueOperation(
        type: 'create',
        table: 'events',
        data: event.toJson(),
      );

      return event;
    }
  }

  Future<bool> _isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
           result.contains(ConnectivityResult.wifi);
  }
}
```

### 6. Conflict Resolution

**Last-write-wins strategy:**

```dart
class ConflictResolver {
  // Resolve conflicts based on timestamps
  Event resolveConflict(Event local, Event remote) {
    // Compare updated_at timestamps
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      print('Local version is newer, keeping local');
      return local;
    } else {
      print('Remote version is newer, keeping remote');
      return remote;
    }
  }

  // Merge non-conflicting fields
  Event mergeEvents(Event local, Event remote) {
    return Event(
      id: remote.id,
      userId: remote.userId,
      title: local.updatedAt.isAfter(remote.updatedAt)
          ? local.title
          : remote.title,
      startTime: local.updatedAt.isAfter(remote.updatedAt)
          ? local.startTime
          : remote.startTime,
      endTime: local.updatedAt.isAfter(remote.updatedAt)
          ? local.endTime
          : remote.endTime,
      visibility: local.visibility,
      createdAt: remote.createdAt,
      updatedAt: local.updatedAt.isAfter(remote.updatedAt)
          ? local.updatedAt
          : remote.updatedAt,
    );
  }
}
```

### 7. Alternative: PowerSync for Production

**For production apps, consider PowerSync (paid service):**

```yaml
dependencies:
  powersync: ^1.0.0
```

**PowerSync provides:**
- Automatic conflict resolution
- Real-time bidirectional sync
- Query-based sync rules
- Built-in retry logic
- Offline queue management

---

## Platform Channels for Native Calendar Access

### Overview

Flutter needs platform channels to access iOS EventKit and Android CalendarContract APIs for native calendar integration.

### 1. Using `device_calendar` Package

**Add dependency:**

```yaml
dependencies:
  device_calendar: ^4.5.0
```

**Request permissions:**

```dart
import 'package:device_calendar/device_calendar.dart';

class CalendarService {
  final DeviceCalendarPlugin _deviceCalendar = DeviceCalendarPlugin();

  // Request calendar permissions
  Future<bool> requestPermissions() async {
    try {
      final permissionsGranted = await _deviceCalendar.hasPermissions();

      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        final permissionsResult = await _deviceCalendar.requestPermissions();
        return permissionsResult.isSuccess && permissionsResult.data!;
      }

      return permissionsGranted.data!;
    } catch (e) {
      print('Permission request failed: ${e.toString()}');
      return false;
    }
  }
}
```

### 2. Read Calendar Events

**Fetch events from native calendar:**

```dart
class CalendarService {
  // Get all calendars
  Future<List<Calendar>> getCalendars() async {
    final calendarsResult = await _deviceCalendar.retrieveCalendars();

    if (calendarsResult.isSuccess) {
      return calendarsResult.data ?? [];
    }

    throw Exception('Failed to retrieve calendars');
  }

  // Get events in date range
  Future<List<Event>> getEventsInRange({
    required String calendarId,
    required DateTime start,
    required DateTime end,
  }) async {
    final eventsResult = await _deviceCalendar.retrieveEvents(
      calendarId,
      RetrieveEventsParams(
        startDate: start,
        endDate: end,
      ),
    );

    if (eventsResult.isSuccess) {
      return eventsResult.data ?? [];
    }

    throw Exception('Failed to retrieve events');
  }

  // Get all user events from all calendars
  Future<List<Event>> getAllUserEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    final calendars = await getCalendars();
    final allEvents = <Event>[];

    for (final calendar in calendars) {
      final events = await getEventsInRange(
        calendarId: calendar.id!,
        start: start,
        end: end,
      );
      allEvents.addAll(events);
    }

    return allEvents;
  }
}
```

### 3. Create Calendar Events

**Add event to native calendar:**

```dart
class CalendarService {
  Future<String?> createEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
  }) async {
    final event = Event(
      calendarId,
      title: title,
      start: TZDateTime.from(start, local),
      end: TZDateTime.from(end, local),
      description: description,
      location: location,
    );

    final result = await _deviceCalendar.createOrUpdateEvent(event);

    if (result?.isSuccess == true) {
      return result!.data; // Returns event ID
    }

    throw Exception('Failed to create event');
  }
}
```

### 4. Bidirectional Sync with Supabase

**Sync native calendar events to Supabase:**

```dart
class CalendarSyncService {
  final CalendarService _calendarService;
  final EventRepository _eventRepository;

  CalendarSyncService(this._calendarService, this._eventRepository);

  // Sync native calendar to Supabase
  Future<void> syncFromNativeCalendar() async {
    // Get last sync timestamp
    final lastSync = await _getLastSyncTime();

    // Fetch native events since last sync
    final nativeEvents = await _calendarService.getAllUserEvents(
      start: lastSync,
      end: DateTime.now().add(Duration(days: 365)),
    );

    // Convert and upload to Supabase
    for (final nativeEvent in nativeEvents) {
      final lockItInEvent = _convertToLockItInEvent(nativeEvent);

      try {
        // Check if event already exists in Supabase
        final existing = await _eventRepository.getEventByNativeId(
          nativeEvent.eventId!,
        );

        if (existing != null) {
          // Update existing
          await _eventRepository.updateEvent(
            existing.id,
            lockItInEvent.toJson(),
          );
        } else {
          // Create new
          await _eventRepository.createEvent(lockItInEvent);
        }
      } catch (e) {
        print('Failed to sync event: ${e.toString()}');
      }
    }

    // Update last sync timestamp
    await _saveLastSyncTime(DateTime.now());
  }

  // Sync Supabase events to native calendar
  Future<void> syncToNativeCalendar() async {
    final calendars = await _calendarService.getCalendars();

    // Find or create LockItIn calendar
    final lockItInCalendar = calendars.firstWhere(
      (cal) => cal.name == 'LockItIn',
      orElse: () => throw Exception('LockItIn calendar not found'),
    );

    // Get events from Supabase
    final supabaseEvents = await _eventRepository.getUserEvents(
      _currentUserId,
    );

    for (final event in supabaseEvents) {
      // Only sync shared events to native calendar
      if (event.visibility == EventVisibility.sharedWithName) {
        try {
          await _calendarService.createEvent(
            calendarId: lockItInCalendar.id!,
            title: event.title,
            start: event.startTime,
            end: event.endTime,
            description: event.description,
            location: event.location,
          );
        } catch (e) {
          print('Failed to create native event: ${e.toString()}');
        }
      }
    }
  }

  Event _convertToLockItInEvent(Event nativeEvent) {
    return Event(
      id: Uuid().v4(),
      userId: _currentUserId,
      nativeCalendarId: nativeEvent.eventId,
      title: nativeEvent.title ?? 'Untitled Event',
      startTime: nativeEvent.start!,
      endTime: nativeEvent.end!,
      description: nativeEvent.description,
      location: nativeEvent.location,
      visibility: EventVisibility.busyOnly, // Default to busy-only
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<DateTime> _getLastSyncTime() async {
    // Implement using SharedPreferences or Hive
    return DateTime.now().subtract(Duration(days: 30));
  }

  Future<void> _saveLastSyncTime(DateTime time) async {
    // Implement using SharedPreferences or Hive
  }
}
```

### 5. Background Sync

**Periodic sync with WorkManager:**

```yaml
dependencies:
  workmanager: ^0.5.2
```

**Setup background sync:**

```dart
import 'package:workmanager/workmanager.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'calendar_sync':
        // Initialize services
        final syncService = CalendarSyncService();

        // Perform bidirectional sync
        await syncService.syncFromNativeCalendar();
        await syncService.syncToNativeCalendar();

        return true;
    }

    return false;
  });
}

void setupBackgroundSync() {
  Workmanager().initialize(callbackDispatcher);

  // Register periodic sync task (every 15 minutes)
  Workmanager().registerPeriodicTask(
    'calendar_sync_task',
    'calendar_sync',
    frequency: Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
}
```

---

## Push Notifications

### Overview

LockItIn needs push notifications for:
- New event proposals
- Vote updates
- Event confirmations
- Group invitations
- Reminder notifications

### 1. Firebase Cloud Messaging Setup

**iOS Configuration:**

1. **Upload APNs Key to Firebase Console:**
   - Go to Firebase Console → Project Settings → Cloud Messaging
   - Upload .p8 APNs auth key
   - Enter Key ID and Team ID

2. **Enable capabilities in Xcode:**
   - Push Notifications
   - Background Modes → Remote notifications

**Android Configuration:**

1. Add `google-services.json` to `android/app/`
2. Update `android/build.gradle`:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

3. Update `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'
```

### 2. Initialize FCM in Flutter

**`lib/services/push_notification_service.dart`:**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.messageId}');
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // Request permission (iOS)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
      return;
    }

    // Get FCM token
    final token = await _fcm.getToken();
    print('FCM Token: $token');

    // Save token to Supabase
    await _saveTokenToSupabase(token!);

    // Listen for token refresh
    _fcm.onTokenRefresh.listen(_saveTokenToSupabase);

    // Setup local notifications
    await _setupLocalNotifications();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app opened from terminated state via notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        _handleLocalNotificationTap(details.payload);
      },
    );
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return;

    await Supabase.instance.client
        .from('user_devices')
        .upsert({
          'user_id': userId,
          'fcm_token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');

    // Show local notification when app is in foreground
    _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'lockitin_channel',
      'LockItIn Notifications',
      channelDescription: 'Notifications for LockItIn events and proposals',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: message.data['route'],
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'];
    final proposalId = message.data['proposal_id'];

    // Navigate to appropriate screen
    if (route == 'proposal_detail' && proposalId != null) {
      // Navigate to proposal detail screen
      navigatorKey.currentState?.pushNamed(
        '/proposal/$proposalId',
      );
    }
  }

  void _handleLocalNotificationTap(String? payload) {
    if (payload != null) {
      navigatorKey.currentState?.pushNamed(payload);
    }
  }
}
```

### 3. Trigger Notifications with Supabase Edge Functions

**Supabase Edge Function for sending notifications:**

**`supabase/functions/send-notification/index.ts`:**

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { userId, title, body, data } = await req.json()

    // Create Supabase client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get user's FCM tokens
    const { data: devices, error } = await supabaseAdmin
      .from('user_devices')
      .select('fcm_token, platform')
      .eq('user_id', userId)

    if (error) throw error

    // Send notification to each device
    for (const device of devices) {
      await sendFCMNotification(device.fcm_token, {
        title,
        body,
        data,
      })
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

async function sendFCMNotification(token: string, payload: any) {
  const FCM_API_KEY = Deno.env.get('FCM_SERVER_KEY')

  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `key=${FCM_API_KEY}`,
    },
    body: JSON.stringify({
      to: token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data,
    }),
  })

  return response.json()
}
```

### 4. Database Trigger for Notifications

**PostgreSQL trigger to call Edge Function:**

```sql
-- Create function to send notification
CREATE OR REPLACE FUNCTION notify_new_proposal()
RETURNS TRIGGER AS $$
DECLARE
  member_id uuid;
BEGIN
  -- Loop through group members
  FOR member_id IN
    SELECT user_id FROM group_members
    WHERE group_id = NEW.group_id
      AND user_id != NEW.organizer_id
  LOOP
    -- Call Edge Function to send notification
    PERFORM
      net.http_post(
        url := 'https://your-project.supabase.co/functions/v1/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('request.jwt.claim.access_token', true)
        ),
        body := jsonb_build_object(
          'userId', member_id,
          'title', 'New Event Proposal',
          'body', NEW.title || ' - Vote now!',
          'data', jsonb_build_object(
            'route', 'proposal_detail',
            'proposal_id', NEW.id
          )
        )
      );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER on_proposal_created
  AFTER INSERT ON event_proposals
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_proposal();
```

### 5. Deep Linking

**Handle deep links from notifications:**

```dart
class DeepLinkService {
  void handleDeepLink(String route, Map<String, dynamic> params) {
    switch (route) {
      case 'proposal_detail':
        final proposalId = params['proposal_id'];
        if (proposalId != null) {
          navigatorKey.currentState?.pushNamed(
            '/proposals/$proposalId',
          );
        }
        break;

      case 'group_detail':
        final groupId = params['group_id'];
        if (groupId != null) {
          navigatorKey.currentState?.pushNamed(
            '/groups/$groupId',
          );
        }
        break;

      case 'inbox':
        navigatorKey.currentState?.pushNamed('/inbox');
        break;
    }
  }
}
```

---

## File Storage

### Overview

LockItIn needs file storage for:
- User profile pictures
- Group avatars
- Event attachments (optional)

### 1. Upload Files

**`lib/services/storage_service.dart`:**

```dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Upload profile picture
  Future<String> uploadProfilePicture(File imageFile, String userId) async {
    try {
      final extension = imageFile.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$extension';
      final filePath = 'profile_pictures/$fileName';

      await _supabase.storage
          .from('avatars')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: ${e.toString()}');
    }
  }

  // Pick and upload image
  Future<String?> pickAndUploadImage({
    required String bucket,
    required String folder,
    required String userId,
  }) async {
    final ImagePicker picker = ImagePicker();

    // Pick image from gallery
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return null;

    final imageFile = File(image.path);

    // Upload
    return await uploadProfilePicture(imageFile, userId);
  }

  // Download file
  Future<Uint8List> downloadFile(String bucket, String filePath) async {
    try {
      final response = await _supabase.storage
          .from(bucket)
          .download(filePath);

      return response;
    } catch (e) {
      throw Exception('Failed to download file: ${e.toString()}');
    }
  }

  // Get signed URL for private files
  Future<String> getSignedUrl({
    required String bucket,
    required String filePath,
    int expiresIn = 3600, // 1 hour
  }) async {
    try {
      final signedUrl = await _supabase.storage
          .from(bucket)
          .createSignedUrl(filePath, expiresIn);

      return signedUrl;
    } catch (e) {
      throw Exception('Failed to create signed URL: ${e.toString()}');
    }
  }

  // Delete file
  Future<void> deleteFile(String bucket, String filePath) async {
    try {
      await _supabase.storage
          .from(bucket)
          .remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  // List files in folder
  Future<List<FileObject>> listFiles(String bucket, String folder) async {
    try {
      final files = await _supabase.storage
          .from(bucket)
          .list(path: folder);

      return files;
    } catch (e) {
      throw Exception('Failed to list files: ${e.toString()}');
    }
  }
}
```

### 2. Create Storage Buckets

**In Supabase Dashboard or SQL:**

```sql
-- Create avatars bucket (public)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true);

-- Create event_attachments bucket (private)
INSERT INTO storage.buckets (id, name, public)
VALUES ('event_attachments', 'event_attachments', false);
```

### 3. Storage RLS Policies

**Secure file access:**

```sql
-- Users can upload their own profile pictures
CREATE POLICY "Users can upload own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can update their own profile pictures
CREATE POLICY "Users can update own avatar"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Anyone can view public avatars
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Users can delete their own avatars
CREATE POLICY "Users can delete own avatar"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

---

## Error Handling

### 1. Structured Error Handling

**`lib/utils/error_handler.dart`:**

```dart
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message, code: 'NETWORK_ERROR');
}

class AuthException extends AppException {
  AuthException(String message) : super(message, code: 'AUTH_ERROR');
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message, code: 'VALIDATION_ERROR');
}

class ServerException extends AppException {
  ServerException(String message) : super(message, code: 'SERVER_ERROR');
}
```

### 2. Centralized Error Handler

**Handle all errors consistently:**

```dart
class ErrorHandler {
  static String handleError(dynamic error) {
    if (error is AuthException) {
      return _handleAuthException(error);
    } else if (error is PostgrestException) {
      return _handlePostgrestException(error);
    } else if (error is StorageException) {
      return _handleStorageException(error);
    } else if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  static String _handleAuthException(AuthException error) {
    switch (error.statusCode) {
      case '400':
        return 'Invalid email or password';
      case '422':
        return 'Email already registered';
      case '429':
        return 'Too many requests. Please try again later.';
      default:
        return error.message;
    }
  }

  static String _handlePostgrestException(PostgrestException error) {
    switch (error.code) {
      case 'PGRST116':
        return 'No data found';
      case '23505':
        return 'Duplicate entry';
      case '23503':
        return 'Referenced record does not exist';
      case '42501':
        return 'Permission denied';
      default:
        return error.message;
    }
  }

  static String _handleStorageException(StorageException error) {
    if (error.statusCode == '404') {
      return 'File not found';
    } else if (error.statusCode == '413') {
      return 'File too large';
    }
    return error.message;
  }

  // Log errors to analytics
  static void logError(dynamic error, StackTrace? stackTrace) {
    print('Error: $error');
    print('StackTrace: $stackTrace');

    // Send to error tracking service (Sentry, Crashlytics, etc.)
  }
}
```

### 3. User-Friendly Error Display

**Show errors in UI:**

```dart
class ErrorSnackbar {
  static void show(BuildContext context, dynamic error) {
    final message = ErrorHandler.handleError(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
```

### 4. Retry Logic

**Automatic retry with exponential backoff:**

```dart
class RetryHandler {
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        if (attempt >= maxAttempts) {
          rethrow;
        }

        print('Attempt $attempt failed, retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);

        // Exponential backoff
        delay *= 2;
      }
    }

    throw Exception('Max retry attempts reached');
  }
}

// Usage
final events = await RetryHandler.retry(
  operation: () => eventRepository.getEvents(),
  maxAttempts: 3,
);
```

---

## Performance Optimization

### 1. Database Query Optimization

**Add indexes:**

```sql
-- Index on frequently queried columns
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_start_time ON events(start_time);
CREATE INDEX idx_group_members_user_id ON group_members(user_id);
CREATE INDEX idx_group_members_group_id ON group_members(group_id);

-- Composite indexes for common query patterns
CREATE INDEX idx_events_user_start ON events(user_id, start_time);
CREATE INDEX idx_proposal_votes_proposal_user ON proposal_votes(proposal_id, user_id);
```

**Use select() to fetch only needed columns:**

```dart
// Bad - fetches all columns
final response = await _supabase.from('events').select();

// Good - only fetch needed columns
final response = await _supabase
    .from('events')
    .select('id, title, start_time, end_time');
```

### 2. Caching Strategy

**In-memory cache with TTL:**

```dart
class CacheManager {
  final Map<String, CacheEntry> _cache = {};

  T? get<T>(String key) {
    final entry = _cache[key];

    if (entry == null) return null;

    // Check if expired
    if (entry.expiresAt.isBefore(DateTime.now())) {
      _cache.remove(key);
      return null;
    }

    return entry.value as T;
  }

  void set<T>(String key, T value, {Duration ttl = const Duration(minutes: 5)}) {
    _cache[key] = CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  void clear() {
    _cache.clear();
  }
}

class CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  CacheEntry({required this.value, required this.expiresAt});
}
```

**Usage in repository:**

```dart
class CachedEventRepository {
  final EventRepository _repository;
  final CacheManager _cache;

  Future<List<Event>> getEvents() async {
    final cacheKey = 'events_${_currentUserId}';

    // Check cache first
    final cached = _cache.get<List<Event>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    // Fetch from database
    final events = await _repository.getEvents();

    // Cache result
    _cache.set(cacheKey, events, ttl: Duration(minutes: 5));

    return events;
  }
}
```

### 3. Lazy Loading & Pagination

**Infinite scroll with pagination:**

```dart
class EventListViewModel extends ChangeNotifier {
  List<Event> _events = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 20;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newEvents = await _repository.getEventsPaginated(
        page: _currentPage,
        itemsPerPage: _pageSize,
      );

      if (newEvents.length < _pageSize) {
        _hasMore = false;
      }

      _events.addAll(newEvents);
      _currentPage++;
    } catch (e) {
      print('Failed to load events: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

**Usage in UI:**

```dart
class EventListView extends StatefulWidget {
  @override
  State<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<EventListView> {
  final ScrollController _scrollController = ScrollController();
  late EventListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EventListViewModel();
    _viewModel.loadMore();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _viewModel.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _viewModel.events.length + (_viewModel.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _viewModel.events.length) {
          return Center(child: CircularProgressIndicator());
        }

        return EventCard(event: _viewModel.events[index]);
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

### 4. Image Optimization

**Compress and cache images:**

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageHelper {
  // Display cached image
  static Widget cachedImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      placeholder: (context, url) => CircularProgressIndicator(),
      errorWidget: (context, url, error) => Icon(Icons.error),
      memCacheWidth: 300, // Limit memory usage
      maxHeightDiskCache: 600,
      maxWidthDiskCache: 600,
    );
  }

  // Compress image before upload
  static Future<File> compressImage(File file) async {
    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '${file.parent.path}/compressed_${file.path.split('/').last}',
      quality: 85,
      minWidth: 1024,
      minHeight: 1024,
    );

    return File(compressed!.path);
  }
}
```

---

## Testing Strategies

### 1. Unit Testing

**Test repository logic:**

```dart
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('EventRepository', () {
    late MockSupabaseClient mockSupabase;
    late EventRepository repository;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      repository = EventRepository(mockSupabase);
    });

    test('getUserEvents returns list of events', () async {
      // Arrange
      final mockResponse = [
        {'id': '1', 'title': 'Event 1', 'user_id': 'user1'},
        {'id': '2', 'title': 'Event 2', 'user_id': 'user1'},
      ];

      when(mockSupabase.from('events').select())
          .thenAnswer((_) async => mockResponse);

      // Act
      final events = await repository.getUserEvents('user1');

      // Assert
      expect(events.length, 2);
      expect(events[0].title, 'Event 1');
    });

    test('createEvent throws exception on error', () async {
      // Arrange
      when(mockSupabase.from('events').insert(any))
          .thenThrow(PostgrestException(message: 'Insert failed'));

      // Act & Assert
      expect(
        () => repository.createEvent(testEvent),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

### 2. Widget Testing

**Test UI components:**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VoteButton displays correctly', (tester) async {
    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoteButton(
            status: VoteStatus.available,
            onTap: () {},
          ),
        ),
      ),
    );

    // Verify
    expect(find.text('Available'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('VoteButton triggers callback on tap', (tester) async {
    bool wasTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoteButton(
            status: VoteStatus.available,
            onTap: () => wasTapped = true,
          ),
        ),
      ),
    );

    // Tap button
    await tester.tap(find.byType(VoteButton));
    await tester.pump();

    // Verify callback was triggered
    expect(wasTapped, true);
  });
}
```

### 3. Integration Testing

**Test full user flows:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Event Proposal Flow', () {
    testWidgets('User can create and vote on proposal', (tester) async {
      // Launch app
      await tester.pumpWidget(LockItInApp());
      await tester.pumpAndSettle();

      // Navigate to create proposal screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill in proposal details
      await tester.enterText(
        find.byKey(Key('proposal_title')),
        'Game Night',
      );

      // Select time options
      await tester.tap(find.text('Friday 7 PM'));
      await tester.tap(find.text('Saturday 8 PM'));

      // Create proposal
      await tester.tap(find.text('Create Proposal'));
      await tester.pumpAndSettle();

      // Verify proposal appears
      expect(find.text('Game Night'), findsOneWidget);

      // Vote on proposal
      await tester.tap(find.text('Friday 7 PM'));
      await tester.tap(find.text('Available'));
      await tester.pumpAndSettle();

      // Verify vote was cast
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
```

### 4. Mocking Supabase for Tests

**Create mock Supabase client:**

```dart
class MockSupabaseRepository implements EventRepository {
  final List<Event> _events = [];

  @override
  Future<Event> createEvent(Event event) async {
    await Future.delayed(Duration(milliseconds: 100)); // Simulate network
    _events.add(event);
    return event;
  }

  @override
  Future<List<Event>> getUserEvents(String userId) async {
    await Future.delayed(Duration(milliseconds: 100));
    return _events.where((e) => e.userId == userId).toList();
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    await Future.delayed(Duration(milliseconds: 100));
    _events.removeWhere((e) => e.id == eventId);
  }
}
```

---

## Security Best Practices

### 1. Never Expose Service Role Key

**DO NOT embed service role key in mobile app:**

```dart
// ❌ WRONG - Never do this
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: SUPABASE_SERVICE_ROLE_KEY, // ❌ DANGEROUS
);

// ✅ CORRECT - Use anon key only
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: SUPABASE_ANON_KEY, // ✅ Safe for client
);
```

### 2. Validate Input Client-Side

**Prevent malicious data:**

```dart
class Validator {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }

    return null;
  }

  static String? validateEventTitle(String? title) {
    if (title == null || title.isEmpty) {
      return 'Title is required';
    }

    if (title.length > 100) {
      return 'Title must be less than 100 characters';
    }

    // Prevent SQL injection attempts
    if (title.contains(RegExp(r'[;<>]'))) {
      return 'Title contains invalid characters';
    }

    return null;
  }
}
```

### 3. Secure Token Storage

**Use flutter_secure_storage:**

```dart
// Store tokens securely
final storage = FlutterSecureStorage();
await storage.write(key: 'auth_token', value: token);

// Never store in SharedPreferences (unencrypted)
// ❌ WRONG
SharedPreferences prefs = await SharedPreferences.getInstance();
prefs.setString('auth_token', token); // Stored in plaintext
```

### 4. Rate Limiting

**Implement client-side rate limiting:**

```dart
class RateLimiter {
  final Map<String, DateTime> _lastCalls = {};
  final Duration _minInterval;

  RateLimiter({required Duration minInterval}) : _minInterval = minInterval;

  Future<T> throttle<T>(String key, Future<T> Function() operation) async {
    final lastCall = _lastCalls[key];

    if (lastCall != null) {
      final elapsed = DateTime.now().difference(lastCall);

      if (elapsed < _minInterval) {
        final remaining = _minInterval - elapsed;
        throw Exception('Too many requests. Wait ${remaining.inSeconds}s');
      }
    }

    _lastCalls[key] = DateTime.now();
    return await operation();
  }
}

// Usage
final rateLimiter = RateLimiter(minInterval: Duration(seconds: 2));

await rateLimiter.throttle('create_event', () async {
  return await eventRepository.createEvent(event);
});
```

### 5. Sanitize User Input

**Prevent XSS and injection attacks:**

```dart
class Sanitizer {
  static String sanitize(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('&', '&amp;');
  }
}
```

---

## LockItIn-Specific Examples

### 1. Shadow Calendar Privacy Implementation

**Get group availability (respecting privacy):**

```dart
class AvailabilityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get availability heatmap for group
  Future<Map<DateTime, GroupAvailability>> getGroupAvailability({
    required String groupId,
    required DateTime start,
    required DateTime end,
  }) async {
    // Fetch all group members
    final membersResponse = await _supabase
        .from('group_members')
        .select('user_id, users(full_name)')
        .eq('group_id', groupId);

    final members = (membersResponse as List)
        .map((m) => GroupMember.fromJson(m))
        .toList();

    final availabilityMap = <DateTime, GroupAvailability>{};

    // For each hour in range
    DateTime current = start;
    while (current.isBefore(end)) {
      final hourStart = current;
      final hourEnd = current.add(Duration(hours: 1));

      int busyCount = 0;
      int freeCount = 0;
      List<String> freeMembers = [];

      for (final member in members) {
        // Check if user has events during this hour
        final events = await _supabase
            .from('events')
            .select('id, visibility')
            .eq('user_id', member.userId)
            .lte('start_time', hourEnd.toIso8601String())
            .gte('end_time', hourStart.toIso8601String());

        if (events.isEmpty) {
          freeCount++;
          freeMembers.add(member.fullName);
        } else {
          busyCount++;
          // Don't expose who's busy or why (privacy!)
        }
      }

      availabilityMap[hourStart] = GroupAvailability(
        totalMembers: members.length,
        busyCount: busyCount,
        freeCount: freeCount,
        freeMembers: freeMembers, // Only show who's free
      );

      current = current.add(Duration(hours: 1));
    }

    return availabilityMap;
  }
}

class GroupAvailability {
  final int totalMembers;
  final int busyCount;
  final int freeCount;
  final List<String> freeMembers;

  GroupAvailability({
    required this.totalMembers,
    required this.busyCount,
    required this.freeCount,
    required this.freeMembers,
  });

  // Percentage of members free
  double get availabilityScore => freeCount / totalMembers;
}
```

### 2. Real-Time Voting Implementation

**Live vote updates:**

```dart
class VotingViewModel extends ChangeNotifier {
  final String proposalId;
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, ProposalVote> _votes = {};
  RealtimeChannel? _channel;

  VotingViewModel(this.proposalId) {
    _init();
  }

  Future<void> _init() async {
    // Load initial votes
    await _loadVotes();

    // Subscribe to real-time updates
    _channel = _supabase
        .channel('proposal_votes:$proposalId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'proposal_votes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'proposal_id',
            value: proposalId,
          ),
          callback: (payload) {
            _handleVoteChange(payload);
          },
        )
        .subscribe();
  }

  Future<void> _loadVotes() async {
    final response = await _supabase
        .from('proposal_votes')
        .select('*, users(full_name, avatar_url)')
        .eq('proposal_id', proposalId);

    _votes = Map.fromEntries(
      (response as List).map((json) {
        final vote = ProposalVote.fromJson(json);
        return MapEntry(vote.userId, vote);
      }),
    );

    notifyListeners();
  }

  void _handleVoteChange(PostgresChangePayload payload) {
    final eventType = payload.eventType;
    final voteData = payload.newRecord;

    switch (eventType) {
      case PostgresChangeEvent.insert:
      case PostgresChangeEvent.update:
        final vote = ProposalVote.fromJson(voteData);
        _votes[vote.userId] = vote;
        break;

      case PostgresChangeEvent.delete:
        final userId = voteData['user_id'];
        _votes.remove(userId);
        break;
    }

    notifyListeners();
  }

  // Cast vote with optimistic update
  Future<void> castVote({
    required String timeOptionId,
    required VoteStatus status,
  }) async {
    final currentUserId = _supabase.auth.currentUser!.id;

    // Optimistic update
    final optimisticVote = ProposalVote(
      id: 'temp',
      proposalId: proposalId,
      timeOptionId: timeOptionId,
      userId: currentUserId,
      status: status,
      createdAt: DateTime.now(),
    );

    _votes[currentUserId] = optimisticVote;
    notifyListeners();

    try {
      // Persist to backend
      await _supabase.from('proposal_votes').upsert({
        'proposal_id': proposalId,
        'time_option_id': timeOptionId,
        'user_id': currentUserId,
        'status': status.toString(),
      });

      // Real-time subscription will update with actual vote
    } catch (e) {
      // Rollback on error
      _votes.remove(currentUserId);
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
```

### 3. Event Auto-Creation After Voting

**Database trigger:**

```sql
CREATE OR REPLACE FUNCTION check_proposal_after_vote()
RETURNS TRIGGER AS $$
DECLARE
  total_members INT;
  votes_count INT;
  winning_option_id UUID;
  winning_votes INT;
BEGIN
  -- Count total group members
  SELECT COUNT(*) INTO total_members
  FROM group_members
  WHERE group_id = (
    SELECT group_id FROM event_proposals WHERE id = NEW.proposal_id
  );

  -- Count votes for this proposal
  SELECT COUNT(DISTINCT user_id) INTO votes_count
  FROM proposal_votes
  WHERE proposal_id = NEW.proposal_id;

  -- Check if all members voted
  IF votes_count >= total_members THEN
    -- Find time option with most "available" votes
    SELECT time_option_id, COUNT(*) as vote_count INTO winning_option_id, winning_votes
    FROM proposal_votes
    WHERE proposal_id = NEW.proposal_id
      AND status = 'available'
    GROUP BY time_option_id
    ORDER BY vote_count DESC
    LIMIT 1;

    -- Create event if we have a winner
    IF winning_option_id IS NOT NULL AND winning_votes >= (total_members * 0.5) THEN
      -- Mark proposal as confirmed
      UPDATE event_proposals
      SET status = 'confirmed',
          selected_time_option_id = winning_option_id,
          updated_at = NOW()
      WHERE id = NEW.proposal_id;

      -- Create confirmed event
      INSERT INTO events (
        id,
        group_id,
        title,
        start_time,
        end_time,
        location,
        visibility,
        created_from_proposal_id,
        created_at,
        updated_at
      )
      SELECT
        gen_random_uuid(),
        ep.group_id,
        ep.title,
        pto.start_time,
        pto.end_time,
        ep.location,
        'shared_with_name',
        ep.id,
        NOW(),
        NOW()
      FROM event_proposals ep
      JOIN proposal_time_options pto ON pto.id = winning_option_id
      WHERE ep.id = NEW.proposal_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_vote_cast
  AFTER INSERT OR UPDATE ON proposal_votes
  FOR EACH ROW
  EXECUTE FUNCTION check_proposal_after_vote();
```

---

## Additional Resources

### Official Documentation

- [Supabase Flutter Quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Supabase Flutter SDK Reference](https://supabase.com/docs/reference/dart)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Cloud Messaging for Flutter](https://firebase.flutter.dev/docs/messaging/overview)

### Community Resources

- [Supabase Discord Community](https://discord.supabase.com/)
- [Flutter Discord Community](https://discord.gg/flutter)
- [r/FlutterDev on Reddit](https://reddit.com/r/FlutterDev)

### Tutorials & Guides

- [Building Offline-First Flutter Apps with Supabase](https://supabase.com/blog/offline-first-flutter-apps)
- [Real-Time Flutter Dashboards with Supabase](https://vibe-studio.ai/insights/real-time-flutter-dashboards-with-supabase-and-streams)
- [Flutter Authorization with RLS](https://supabase.com/blog/flutter-authorization-with-rls)

### Tools

- [Supabase CLI](https://supabase.com/docs/guides/cli)
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools/overview)
- [Postman for API Testing](https://www.postman.com/)

---

## Conclusion

This guide provides production-ready Flutter + Supabase integration patterns specifically designed for LockItIn's privacy-first calendar app. Key takeaways:

1. **Authentication**: Use Supabase Auth with secure token storage
2. **Privacy**: Enforce Shadow Calendar with RLS policies at database level
3. **Real-Time**: Leverage WebSocket subscriptions for live voting updates
4. **Offline-First**: Cache locally, queue mutations, sync on reconnect
5. **Native Integration**: Use platform channels for iOS/Android calendar access
6. **Security**: Never expose service role key, validate inputs, rate limit
7. **Performance**: Index queries, cache aggressively, paginate large datasets

Remember to:
- Test RLS policies thoroughly
- Handle errors gracefully
- Provide offline support
- Optimize for mobile constraints (battery, network, storage)
- Follow platform-specific guidelines (Apple HIG, Material Design)

Happy coding!

---

**Document Version:** 1.0
**Last Updated:** December 8, 2025
**Maintained By:** LockItIn Development Team

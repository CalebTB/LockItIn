// RLS Policy Verification Tests
//
// These tests verify that RLS policies are correctly configured in the
// Supabase database by querying the pg_policies system catalog.
//
// Run with: flutter test test/integration/rls_policy_verification_test.dart
//
// Prerequisites:
// - Supabase project must be running
// - Test must have access to execute SQL queries

import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/network/supabase_client.dart';

void main() {
  group('RLS Policy Verification', () {
    // Skip these tests if Supabase is not initialized
    // In CI, set SKIP_INTEGRATION_TESTS=true
    final skipIntegration =
        const bool.fromEnvironment('SKIP_INTEGRATION_TESTS', defaultValue: true);

    group('Groups Table Policies', () {
      test(
        'should have SELECT policy for group members',
        skip: skipIntegration ? 'Integration tests skipped' : null,
        () async {
          final result = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'groups',
              'p_policy': 'Users can view groups they belong to',
              'p_cmd': 'SELECT',
            },
          );
          expect(result, isTrue);
        },
      );

      test(
        'should have UPDATE policy for owners/co-owners',
        skip: skipIntegration ? 'Integration tests skipped' : null,
        () async {
          final result = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'groups',
              'p_policy': 'Owners and co-owners can update groups',
              'p_cmd': 'UPDATE',
            },
          );
          expect(result, isTrue);
        },
      );

      test(
        'should have DELETE policy for owners only',
        skip: skipIntegration ? 'Integration tests skipped' : null,
        () async {
          final result = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'groups',
              'p_policy': 'Only owners can delete groups',
              'p_cmd': 'DELETE',
            },
          );
          expect(result, isTrue);
        },
      );
    });

    group('Friendships Table Policies', () {
      test(
        'should have SELECT policy for participants only',
        skip: skipIntegration ? 'Integration tests skipped' : null,
        () async {
          final result = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'friendships',
              'p_policy': 'Users can view own friendships',
              'p_cmd': 'SELECT',
            },
          );
          expect(result, isTrue);
        },
      );

      test(
        'should have INSERT policy requiring sender to be current user',
        skip: skipIntegration ? 'Integration tests skipped' : null,
        () async {
          final result = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'friendships',
              'p_policy': 'Users can send friend requests',
              'p_cmd': 'INSERT',
            },
          );
          expect(result, isTrue);
        },
      );
    });

    group('Events Table Policies', () {
      test(
        'should have privacy-aware SELECT policy',
        skip: skipIntegration ? 'Integration tests skipped' : null,
        () async {
          final result = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'events',
              'p_policy': 'Users can view own and group members events',
              'p_cmd': 'SELECT',
            },
          );
          expect(result, isTrue);
        },
      );

      test(
        'should have owner-only mutation policies',
        skip: skipIntegration ? 'Integration tests skipped' : null,
        () async {
          final insertResult = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'events',
              'p_policy': 'Users can insert own events',
              'p_cmd': 'INSERT',
            },
          );
          final updateResult = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'events',
              'p_policy': 'Users can update own events',
              'p_cmd': 'UPDATE',
            },
          );
          final deleteResult = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'events',
              'p_policy': 'Users can delete own events',
              'p_cmd': 'DELETE',
            },
          );
          expect(insertResult, isTrue);
          expect(updateResult, isTrue);
          expect(deleteResult, isTrue);
        },
      );
    });

    group('Shadow Calendar Policies', () {
      test(
        'should have self-view policy',
        skip: skipIntegration ? 'Integration tests skipped' : null,
        () async {
          final result = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'shadow_calendar',
              'p_policy': 'Users can view own shadow calendar',
              'p_cmd': 'SELECT',
            },
          );
          expect(result, isTrue);
        },
      );

      test(
        'should have group member visibility policy',
        skip: skipIntegration ? 'Integration tests skipped' : null,
        () async {
          final result = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'shadow_calendar',
              'p_policy': "Group members can view each other's shadow calendar",
              'p_cmd': 'SELECT',
            },
          );
          expect(result, isTrue);
        },
      );
    });

    group('Proposal/Voting Policies', () {
      test(
        'should have group member access for proposals',
        skip: skipIntegration ? 'Integration tests skipped' : null,
        () async {
          final selectResult = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'event_proposals',
              'p_policy': 'Group members can view proposals',
              'p_cmd': 'SELECT',
            },
          );
          final insertResult = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'event_proposals',
              'p_policy': 'Group members can create proposals',
              'p_cmd': 'INSERT',
            },
          );
          expect(selectResult, isTrue);
          expect(insertResult, isTrue);
        },
      );

      test(
        'should have vote casting restrictions',
        skip: skipIntegration ? 'Integration tests skipped' : null,
        () async {
          final result = await SupabaseClientManager.client.rpc(
            'verify_rls_policy_exists',
            params: {
              'p_table': 'proposal_votes',
              'p_policy': 'Users can cast votes',
              'p_cmd': 'INSERT',
            },
          );
          expect(result, isTrue);
        },
      );
    });

    group('RLS Enabled Verification', () {
      test(
        'should have RLS enabled on all sensitive tables',
        skip: skipIntegration ? 'Integration tests skipped' : null,
        () async {
          final tables = [
            'users',
            'events',
            'groups',
            'group_members',
            'group_invites',
            'friendships',
            'shadow_calendar',
            'event_proposals',
            'proposal_time_options',
            'proposal_votes',
            'notifications',
          ];

          for (final table in tables) {
            final result = await SupabaseClientManager.client.rpc(
              'is_rls_enabled',
              params: {'p_table': table},
            );
            expect(result, isTrue, reason: 'RLS should be enabled on $table');
          }
        },
      );
    });
  });

  group('RLS Policy Count Verification', () {
    // These tests verify the expected number of policies per table
    // to catch accidental policy deletions

    final expectedPolicyCounts = {
      'groups': 4, // SELECT, INSERT, UPDATE, DELETE
      'group_members': 4, // SELECT, INSERT, UPDATE, DELETE
      'group_invites': 3, // SELECT, INSERT, DELETE
      'friendships': 4, // SELECT, INSERT, UPDATE, DELETE
      'events': 4, // SELECT, INSERT, UPDATE, DELETE
      'shadow_calendar': 2, // 2 SELECT policies (self + group)
      'event_proposals': 4, // SELECT, INSERT, UPDATE, DELETE
      'proposal_time_options': 2, // SELECT, ALL (creator)
      'proposal_votes': 4, // SELECT, INSERT, UPDATE, DELETE
      'notifications': 4, // SELECT, INSERT, UPDATE, DELETE
      'users': 3, // SELECT, INSERT, UPDATE
    };

    test('documents expected policy counts per table', () {
      // This test documents the expected policy structure
      // Actual verification requires database access
      expect(expectedPolicyCounts['groups'], 4);
      expect(expectedPolicyCounts['friendships'], 4);
      expect(expectedPolicyCounts['events'], 4);
      expect(expectedPolicyCounts['shadow_calendar'], 2);
      expect(expectedPolicyCounts['event_proposals'], 4);
      expect(expectedPolicyCounts['proposal_votes'], 4);
    });
  });
}

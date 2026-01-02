import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/group_model.dart';
import '../../providers/friend_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/friend_request_tile.dart';

/// Inbox tab showing notifications, friend requests, and group invites
/// Features:
/// - Sections: Friend Requests, Group Invites, Activity
/// - Badge counts for unread items
/// - Pull to refresh
class InboxTab extends StatefulWidget {
  const InboxTab({super.key});

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab> {
  @override
  void initState() {
    super.initState();
    // Initialize providers if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().initialize();
      context.read<GroupProvider>().initialize();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<FriendProvider>().loadPendingRequests(),
      context.read<GroupProvider>().loadPendingInvites(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final friendProvider = context.watch<FriendProvider>();
    final groupProvider = context.watch<GroupProvider>();

    final pendingFriendRequests = friendProvider.pendingRequests;
    final pendingGroupInvites = groupProvider.pendingInvites;
    final totalPending = pendingFriendRequests.length + pendingGroupInvites.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, colorScheme, appColors, totalPending),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: totalPending == 0
                    ? _buildEmptyState(context, colorScheme, appColors)
                    : _buildInboxContent(
                        context,
                        colorScheme,
                        appColors,
                        pendingFriendRequests,
                        pendingGroupInvites,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
    int totalPending,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inbox_rounded,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inbox',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                totalPending > 0
                    ? '$totalPending pending'
                    : 'All caught up',
                style: TextStyle(
                  fontSize: 13,
                  color: totalPending > 0
                      ? colorScheme.primary
                      : appColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: EmptyState(
            type: EmptyStateType.inboxEmpty,
          ),
        ),
      ],
    );
  }

  Widget _buildInboxContent(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
    List<dynamic> friendRequests,
    List<GroupInvite> groupInvites,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Friend Requests Section
        if (friendRequests.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            colorScheme,
            appColors,
            'Friend Requests',
            friendRequests.length,
            Icons.person_add_outlined,
          ),
          ...friendRequests.map((request) => FriendRequestTile(
                request: request,
                onAccept: () async {
                  await context.read<FriendProvider>().acceptFriendRequest(request);
                },
                onDecline: () async {
                  await context.read<FriendProvider>().declineFriendRequest(request);
                },
              )),
          const SizedBox(height: 16),
        ],

        // Group Invites Section
        if (groupInvites.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            colorScheme,
            appColors,
            'Group Invites',
            groupInvites.length,
            Icons.group_add_outlined,
          ),
          ...groupInvites.map((invite) => _buildGroupInviteTile(
                context,
                colorScheme,
                appColors,
                invite,
              )),
          const SizedBox(height: 16),
        ],

        // Activity Section (placeholder for future)
        _buildSectionHeader(
          context,
          colorScheme,
          appColors,
          'Recent Activity',
          0,
          Icons.history_rounded,
        ),
        _buildActivityPlaceholder(context, colorScheme, appColors),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
    String title,
    int count,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: appColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: appColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupInviteTile(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
    GroupInvite invite,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.cardBorder),
      ),
      child: Row(
        children: [
          // Group emoji
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              invite.groupEmoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          // Group info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.groupName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Invited by ${invite.inviterName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: appColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () async {
                  await context.read<GroupProvider>().declineInvite(invite.id);
                },
                icon: Icon(
                  Icons.close_rounded,
                  color: appColors.textMuted,
                ),
                tooltip: 'Decline',
              ),
              IconButton(
                onPressed: () async {
                  await context.read<GroupProvider>().acceptInvite(invite.id);
                },
                icon: Icon(
                  Icons.check_rounded,
                  color: appColors.success,
                ),
                tooltip: 'Accept',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPlaceholder(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 32,
            color: appColors.textDisabled,
          ),
          const SizedBox(height: 8),
          Text(
            'No recent activity',
            style: TextStyle(
              fontSize: 14,
              color: appColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

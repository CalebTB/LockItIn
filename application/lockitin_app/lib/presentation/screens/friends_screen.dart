import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/friendship_model.dart';
import '../../data/models/group_model.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../widgets/friend_search_delegate.dart';
import '../widgets/friend_list_tile.dart';
import '../widgets/friend_request_tile.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/animated_friend_request_list.dart';

/// Main screen for managing friends and friend requests
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize friend provider data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showSearch(context),
            tooltip: 'Add Friend',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_rounded, size: 20),
                  const SizedBox(width: 8),
                  const Text('Friends'),
                ],
              ),
            ),
            Tab(
              child: Consumer<FriendProvider>(
                builder: (context, provider, _) {
                  final count = provider.pendingRequestCount;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mail_rounded, size: 20),
                      const SizedBox(width: 8),
                      const Text('Requests'),
                      if (count > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              color: colorScheme.onError,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FriendsListTab(),
          _RequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSearch(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Friend'),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: FriendSearchDelegate(),
    );
  }
}

/// Tab showing list of accepted friends
class _FriendsListTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingFriends) {
          return const FriendListSkeleton();
        }

        if (provider.friendsError != null) {
          return _ErrorView(
            message: provider.friendsError!,
            onRetry: () => provider.loadFriends(),
          );
        }

        if (!provider.hasFriends) {
          return _EmptyFriendsView();
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadFriends(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.friends.length,
            itemBuilder: (context, index) {
              final friend = provider.friends[index];
              return FriendListTile(
                friend: friend,
                onTap: () => _showFriendProfile(context, friend),
                onRemove: () => _confirmRemoveFriend(context, friend, provider),
              );
            },
          ),
        );
      },
    );
  }

  void _showFriendProfile(BuildContext context, FriendProfile friend) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FriendProfileSheet(friend: friend),
    );
  }

  void _confirmRemoveFriend(
    BuildContext context,
    FriendProfile friend,
    FriendProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text(
          'Are you sure you want to remove ${friend.displayName} from your friends?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (friend.friendshipId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unable to remove friend - missing friendship ID'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              final success = await provider.removeFriend(friend, friend.friendshipId!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Removed ${friend.displayName} from friends'
                          : 'Failed to remove friend',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

/// Tab showing pending friend requests
class _RequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingRequests) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.requestsError != null) {
          return _ErrorView(
            message: provider.requestsError!,
            onRetry: () => provider.loadPendingRequests(),
          );
        }

        final hasIncoming = provider.pendingRequests.isNotEmpty;
        final hasOutgoing = provider.sentRequests.isNotEmpty;

        if (!hasIncoming && !hasOutgoing) {
          return _EmptyRequestsView();
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadPendingRequests(),
          child: CustomScrollView(
            slivers: [
              if (hasIncoming) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Incoming Requests',
                    count: provider.pendingRequests.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: provider.pendingRequests.length * 80.0,
                    child: AnimatedFriendRequestList(
                      requests: provider.pendingRequests,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, request, animation) {
                        return FriendRequestTile(
                          request: request,
                          onAccept: () => _acceptRequest(context, request, provider),
                          onDecline: () => _declineRequest(context, request, provider),
                        );
                      },
                    ),
                  ),
                ),
              ],
              if (hasOutgoing) ...[
                if (hasIncoming)
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Sent Requests',
                    count: provider.sentRequests.length,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final request = provider.sentRequests[index];
                      return _SentRequestTile(
                        request: request,
                        onCancel: () => _cancelRequest(context, request, provider),
                      );
                    },
                    childCount: provider.sentRequests.length,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _acceptRequest(
    BuildContext context,
    FriendRequest request,
    FriendProvider provider,
  ) async {
    final success = await provider.acceptFriendRequest(request);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'You are now friends with ${request.displayName}!'
                : 'Failed to accept request',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _declineRequest(
    BuildContext context,
    FriendRequest request,
    FriendProvider provider,
  ) async {
    final success = await provider.declineFriendRequest(request);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Request declined' : 'Failed to decline request',
          ),
        ),
      );
    }
  }

  Future<void> _cancelRequest(
    BuildContext context,
    SentRequest request,
    FriendProvider provider,
  ) async {
    final success = await provider.cancelFriendRequest(request);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Request canceled' : 'Failed to cancel request',
          ),
        ),
      );
    }
  }
}

/// Section header with title and count badge
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile for sent (outgoing) friend requests
class _SentRequestTile extends StatelessWidget {
  final SentRequest request;
  final VoidCallback onCancel;

  const _SentRequestTile({required this.request, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            request.initials,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          request.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Pending since ${_formatDate(request.sentAt)}',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        trailing: TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

/// Empty state when user has no friends
class _EmptyFriendsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Friends Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends to start planning events together!',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: FriendSearchDelegate(),
                );
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Find Friends'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state when user has no pending requests
class _EmptyRequestsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mail_outline_rounded,
                size: 64,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Pending Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Friend requests you receive will appear here.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error view with retry button
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Friend profile bottom sheet with enhanced details
/// Shows friend information, mutual groups, and action buttons
class _FriendProfileSheet extends StatelessWidget {
  final FriendProfile friend;

  const _FriendProfileSheet({required this.friend});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Consumer<GroupProvider>(
      builder: (context, groupProvider, _) {
        // Find mutual groups (groups where both current user and friend are members)
        final mutualGroups = _getMutualGroups(groupProvider);

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Avatar
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: colorScheme.primaryContainer,
                      child: friend.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                friend.avatarUrl!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Text(
                                  friend.initials,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              friend.initials,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      friend.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Email
                    const SizedBox(height: 4),
                    Text(
                      friend.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: appColors.textSecondary,
                      ),
                    ),

                    // Friends since badge
                    if (friend.friendshipSince != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Friends since ${_formatDate(friend.friendshipSince!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Mutual Groups Section
                    if (mutualGroups.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildMutualGroupsSection(context, mutualGroups, colorScheme, appColors),
                    ],

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Shared calendar coming soon!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.calendar_today_rounded),
                            label: const Text('View Calendar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Event planning coming soon!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.event_rounded),
                            label: const Text('Plan Event'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Remove Friend Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmRemoveFriend(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                        ),
                        icon: const Icon(Icons.person_remove_rounded),
                        label: const Text('Remove Friend'),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Build the mutual groups section
  Widget _buildMutualGroupsSection(
    BuildContext context,
    List<GroupModel> groups,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.groups_rounded,
              size: 18,
              color: appColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Mutual Groups (${groups.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: appColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: groups.map((group) => _buildGroupChip(context, group, colorScheme)).toList(),
        ),
      ],
    );
  }

  /// Build a chip for a mutual group
  Widget _buildGroupChip(BuildContext context, GroupModel group, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Group emoji or icon
          Text(
            group.emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            group.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Get groups that the friend is also a member of
  List<GroupModel> _getMutualGroups(GroupProvider groupProvider) {
    // Get all user's groups and find ones where friend is a member
    // This would require loading member lists for each group
    // For now, return all groups as a starting point
    // TODO: Enhance to only show groups where friend is confirmed member
    return groupProvider.groups;
  }

  /// Confirm removal of friend
  void _confirmRemoveFriend(BuildContext context) {
    final friendProvider = context.read<FriendProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text(
          'Are you sure you want to remove ${friend.displayName} from your friends?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              Navigator.pop(context); // Close the profile sheet

              if (friend.friendshipId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unable to remove friend - missing friendship ID'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              HapticFeedback.mediumImpact();
              final success = await friendProvider.removeFriend(friend, friend.friendshipId!);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Removed ${friend.displayName} from friends'
                          : 'Failed to remove friend',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

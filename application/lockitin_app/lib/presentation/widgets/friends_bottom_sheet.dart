import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import '../../data/models/friendship_model.dart';
import 'friend_search_delegate.dart';

/// Bottom sheet displaying user's friends with status indicators
/// Shows list of friends with availability status and mutual groups
/// Styled with Sunset Coral Dark theme
class FriendsBottomSheet extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onAddFriend;

  const FriendsBottomSheet({
    super.key,
    required this.onClose,
    this.onAddFriend,
  });

  @override
  State<FriendsBottomSheet> createState() => _FriendsBottomSheetState();
}

class _FriendsBottomSheetState extends State<FriendsBottomSheet> {
  // Sunset Coral Dark Theme Colors
  static const Color _rose950 = Color(0xFF4C0519);
  static const Color _rose900 = Color(0xFF881337);
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose400 = Color(0xFFFB7185);
  static const Color _rose300 = Color(0xFFFDA4AF);
  static const Color _rose200 = Color(0xFFFECDD3);
  static const Color _rose100 = Color(0xFFFFE4E6);
  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _orange400 = Color(0xFFFB923C);
  static const Color _orange200 = Color(0xFFFED7AA);
  static const Color _emerald400 = Color(0xFF34D399);
  static const Color _emerald500 = Color(0xFF10B981);
  static const Color _emerald300 = Color(0xFF6EE7B7);
  static const Color _slate950 = Color(0xFF020617);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = Friends, 1 = Pending, 2 = Sent

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_rose950, _rose950, _slate950],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: Color(0x33F43F5E), width: 1), // rose-500/20
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
        minHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: _rose500.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_rose200, _orange200],
                  ).createShader(bounds),
                  child: const Text(
                    'Friends',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: _rose300),
                ),
              ],
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Consumer<FriendProvider>(
              builder: (context, provider, _) {
                return Row(
                  children: [
                    _buildTab(0, 'Friends', provider.friends.length),
                    const SizedBox(width: 8),
                    _buildTab(1, 'Pending', provider.pendingRequests.length),
                    const SizedBox(width: 8),
                    _buildTab(2, 'Sent', provider.sentRequests.length),
                  ],
                );
              },
            ),
          ),

          // Search field (only show for Friends tab)
          if (_selectedTab == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: _rose100, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search friends...',
                  hintStyle: TextStyle(color: _rose300.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: _rose900.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _rose500.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _rose500.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _rose400.withValues(alpha: 0.5), width: 1),
                  ),
                  prefixIcon: Icon(Icons.search, color: _rose300.withValues(alpha: 0.4)),
                ),
              ),
            ),

          if (_selectedTab == 0) const SizedBox(height: 16),

          // Content based on selected tab
          Flexible(
            child: Consumer<FriendProvider>(
              builder: (context, friendProvider, child) {
                if (friendProvider.isLoadingFriends || friendProvider.isLoadingRequests) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: _rose400,
                      ),
                    ),
                  );
                }

                switch (_selectedTab) {
                  case 0:
                    return _buildFriendsTab(context, friendProvider);
                  case 1:
                    return _buildPendingTab(context, friendProvider);
                  case 2:
                    return _buildSentTab(context, friendProvider);
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  List<FriendProfile> _filterFriends(List<FriendProfile> friends) {
    if (_searchQuery.isEmpty) return friends;
    final query = _searchQuery.toLowerCase();
    return friends.where((friend) {
      return friend.displayName.toLowerCase().contains(query) ||
          friend.email.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildTab(int index, String label, int count) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? _rose500.withValues(alpha: 0.2)
                : _rose900.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? _rose400.withValues(alpha: 0.5)
                  : _rose500.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? _rose100 : _rose300.withValues(alpha: 0.6),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? _rose400 : _rose500.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _rose200,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsTab(BuildContext context, FriendProvider friendProvider) {
    final friends = _filterFriends(friendProvider.friends);

    if (friends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: _rose300.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty ? 'No friends yet' : 'No friends found',
              style: TextStyle(
                fontSize: 16,
                color: _rose300.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            _buildAddFriendButton(context),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        children: [
          ...friends.map((friend) => _buildFriendTile(context, friend)),
          const SizedBox(height: 12),
          _buildAddFriendButton(context),
        ],
      ),
    );
  }

  Widget _buildPendingTab(BuildContext context, FriendProvider friendProvider) {
    final requests = friendProvider.pendingRequests;

    if (requests.isEmpty) {
      return _buildEmptyTabState(
        Icons.inbox_rounded,
        'No Pending Requests',
        'Friend requests you receive will appear here',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        children: requests.map((request) => _buildPendingRequestTile(context, friendProvider, request)).toList(),
      ),
    );
  }

  Widget _buildSentTab(BuildContext context, FriendProvider friendProvider) {
    final requests = friendProvider.sentRequests;

    if (requests.isEmpty) {
      return _buildEmptyTabState(
        Icons.send_rounded,
        'No Sent Requests',
        'Friend requests you send will appear here',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        children: requests.map((request) => _buildSentRequestTile(context, friendProvider, request)).toList(),
      ),
    );
  }

  Widget _buildEmptyTabState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _rose900.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: _rose300.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _rose200,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: _rose300.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestTile(
    BuildContext context,
    FriendProvider provider,
    FriendRequest request,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _rose900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _rose500.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_rose400, _orange400],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(request.fullName ?? request.email),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.fullName ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _rose50,
                  ),
                ),
                Text(
                  request.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: _rose300.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // Actions
          IconButton(
            onPressed: () => _declineRequest(context, provider, request),
            icon: const Icon(Icons.close_rounded),
            color: _rose400,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _acceptRequest(context, provider, request),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_rose500, _orange400],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentRequestTile(
    BuildContext context,
    FriendProvider provider,
    FriendshipModel request,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _rose900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _rose500.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _rose900.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: _rose500.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person_outline_rounded,
                color: _rose300,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Request sent',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _rose50,
                  ),
                ),
                Text(
                  'Waiting for response...',
                  style: TextStyle(
                    fontSize: 13,
                    color: _rose300.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // Cancel button
          GestureDetector(
            onTap: () => _cancelRequest(context, provider, request),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _rose900.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _rose500.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _rose300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Future<void> _acceptRequest(
    BuildContext context,
    FriendProvider provider,
    FriendRequest request,
  ) async {
    final success = await provider.acceptFriendRequest(request);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'You are now friends with ${request.fullName ?? request.email}'
                : provider.actionError ?? 'Failed to accept request',
          ),
          backgroundColor: success ? _emerald500 : _rose500,
        ),
      );
    }
  }

  Future<void> _declineRequest(
    BuildContext context,
    FriendProvider provider,
    FriendRequest request,
  ) async {
    final success = await provider.declineFriendRequest(request);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Request declined' : provider.actionError ?? 'Failed to decline request',
          ),
          backgroundColor: success ? _rose900 : _rose500,
        ),
      );
    }
  }

  Future<void> _cancelRequest(
    BuildContext context,
    FriendProvider provider,
    FriendshipModel request,
  ) async {
    final success = await provider.cancelFriendRequest(request);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Request cancelled' : provider.actionError ?? 'Failed to cancel request',
          ),
          backgroundColor: success ? _rose900 : _rose500,
        ),
      );
    }
  }

  Widget _buildFriendTile(BuildContext context, FriendProfile friend) {
    // Availability status - placeholder for now
    const status = 'available'; // TODO: Get real availability status

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to friend profile or calendar view
            widget.onClose();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                // Avatar with status indicator
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_rose400, _orange400],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _rose500.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                        image: friend.avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(friend.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: friend.avatarUrl == null
                          ? Center(
                              child: Text(
                                friend.initials,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                    // Status indicator
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                          border: Border.all(color: _rose950, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(status).withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Friend info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _rose50,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        friend.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: _rose300.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBadgeColor(status),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusBorderColor(status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusTextColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddFriendButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          widget.onClose();
          showSearch(
            context: context,
            delegate: FriendSearchDelegate(),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _rose500.withValues(alpha: 0.3),
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add_rounded,
                size: 18,
                color: _rose300.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Add Friend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _rose300.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return _emerald400;
      case 'busy':
        return _rose400;
      default:
        return _rose400.withValues(alpha: 0.4);
    }
  }

  Color _getStatusBadgeColor(String status) {
    switch (status) {
      case 'available':
        return _emerald500.withValues(alpha: 0.2);
      case 'busy':
        return _rose500.withValues(alpha: 0.2);
      default:
        return _rose500.withValues(alpha: 0.1);
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status) {
      case 'available':
        return _emerald500.withValues(alpha: 0.3);
      case 'busy':
        return _rose500.withValues(alpha: 0.3);
      default:
        return _rose500.withValues(alpha: 0.2);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'available':
        return _emerald300;
      case 'busy':
        return _rose300;
      default:
        return _rose300.withValues(alpha: 0.5);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Free';
      case 'busy':
        return 'Busy';
      default:
        return 'Unknown';
    }
  }
}

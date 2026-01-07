import 'package:flutter/material.dart';
import '../../data/models/friendship_model.dart';

/// AnimatedList wrapper for friend requests that handles optimistic updates
///
/// Detects when items are added or removed from the list and triggers
/// smooth slide/fade animations. Works with FriendProvider's optimistic
/// update pattern without requiring provider changes.
class AnimatedFriendRequestList extends StatefulWidget {
  final List<FriendRequest> requests;
  final Widget Function(BuildContext, FriendRequest, Animation<double>) itemBuilder;
  final EdgeInsets? padding;

  const AnimatedFriendRequestList({
    super.key,
    required this.requests,
    required this.itemBuilder,
    this.padding,
  });

  @override
  State<AnimatedFriendRequestList> createState() => _AnimatedFriendRequestListState();
}

class _AnimatedFriendRequestListState extends State<AnimatedFriendRequestList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<FriendRequest> _displayedRequests;

  @override
  void initState() {
    super.initState();
    _displayedRequests = List.from(widget.requests);
  }

  @override
  void didUpdateWidget(AnimatedFriendRequestList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect changes in the requests list
    final newRequests = widget.requests;

    // Find removed items (present in old, absent in new)
    for (int i = _displayedRequests.length - 1; i >= 0; i--) {
      final request = _displayedRequests[i];
      if (!newRequests.any((r) => r.requestId == request.requestId)) {
        // Item was removed - trigger remove animation
        final removedRequest = _displayedRequests.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildRemovedItem(removedRequest, animation),
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    // Find added items (absent in old, present in new)
    for (int i = 0; i < newRequests.length; i++) {
      final request = newRequests[i];
      if (!_displayedRequests.any((r) => r.requestId == request.requestId)) {
        // Item was added - trigger insert animation
        _displayedRequests.insert(i, request);
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      padding: widget.padding,
      initialItemCount: _displayedRequests.length,
      itemBuilder: (context, index, animation) {
        if (index >= _displayedRequests.length) {
          return const SizedBox.shrink();
        }
        final request = _displayedRequests[index];
        return _buildAnimatedItem(request, animation);
      },
    );
  }

  Widget _buildAnimatedItem(FriendRequest request, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      child: FadeTransition(
        opacity: animation,
        child: widget.itemBuilder(context, request, animation),
      ),
    );
  }

  Widget _buildRemovedItem(FriendRequest request, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      child: FadeTransition(
        opacity: animation,
        child: widget.itemBuilder(context, request, animation),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/supabase_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/member_utils.dart';
import '../../data/models/event_model.dart';
import '../providers/group_provider.dart';
import '../widgets/templates/surprise_party_task_list.dart';
import '../widgets/templates/add_task_sheet.dart';

/// Coordinator dashboard screen for surprise party events
///
/// Features:
/// - Progress overview with completion percentage
/// - Quick stats (incomplete/completed tasks)
/// - Full task list with management capabilities
/// - Add new task button
/// - Countdown to reveal time (if set)
/// - RSVP status tracking with real-time updates
///
/// Only visible to coordinators (users "in on it")
class SurprisePartyDashboard extends StatefulWidget {
  final EventModel event;

  const SurprisePartyDashboard({
    super.key,
    required this.event,
  });

  @override
  State<SurprisePartyDashboard> createState() => _SurprisePartyDashboardState();
}

class _SurprisePartyDashboardState extends State<SurprisePartyDashboard> {
  // RSVP state variables
  List<Map<String, dynamic>> _invitations = [];
  bool _isLoading = true;
  String? _errorMessage;
  RealtimeChannel? _rsvpChannel;
  Timer? _updateDebounce;
  final List<PostgresChangePayload> _batchedUpdates = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Fetch initial data FIRST (prevents race with WebSocket)
      await _fetchInvitations();

      // Only subscribe after initial data loaded
      if (!mounted) return;
      _subscribeToRSVPUpdates();

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load RSVP data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchInvitations() async {
    final response = await SupabaseClientManager.client
        .from('event_invitations')
        .select('*, users:user_id(id, full_name, avatar_url)')
        .eq('event_id', widget.event.id);

    if (!mounted) return; // CRITICAL: Guard against disposed widget

    setState(() {
      _invitations = List<Map<String, dynamic>>.from(response as List);
    });
  }

  void _subscribeToRSVPUpdates() {
    _rsvpChannel = SupabaseClientManager.client.channel('rsvps-${widget.event.id}');

    _rsvpChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_invitations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'event_id',
            value: widget.event.id,
          ),
          callback: (payload) {
            if (!mounted) return; // CRITICAL: Guard setState after dispose
            _handleRSVPUpdate(payload);
          },
        )
        .subscribe();
  }

  void _handleRSVPUpdate(PostgresChangePayload payload) {
    // Batch updates to prevent UI jank (debounce 100ms)
    _batchedUpdates.add(payload);

    _updateDebounce?.cancel();
    _updateDebounce = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _applyBatchedUpdates();
    });
  }

  void _applyBatchedUpdates() {
    setState(() {
      for (final payload in _batchedUpdates) {
        final updatedInvitation = payload.newRecord;
        final index = _invitations
            .indexWhere((i) => i['id'] == updatedInvitation['id']);
        if (index != -1) {
          _invitations[index] = updatedInvitation;
        }
      }
      _batchedUpdates.clear();
    });
  }

  @override
  void dispose() {
    _updateDebounce?.cancel();
    _rsvpChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final template = widget.event.surprisePartyTemplate;

    if (template == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Surprise Party'),
        ),
        body: const Center(
          child: Text('No surprise party template found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Party Coordinator Hub'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Consumer<GroupProvider>(
          builder: (context, groupProvider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with target info
                  _buildHeader(context, appColors, colorScheme),

                  const SizedBox(height: AppSpacing.xl),

                  // Progress card
                  _buildProgressCard(appColors, colorScheme),

                  const SizedBox(height: AppSpacing.lg),

                  // Task list
                  SurprisePartyTaskList(
                    event: widget.event,
                    onAddTask: () => _showAddTaskSheet(context),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // RSVP section
                  _buildRSVPSection(context, appColors, colorScheme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppColorsExtension appColors,
    ColorScheme colorScheme,
  ) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, _) {
        final template = widget.event.surprisePartyTemplate!;
        final target = groupProvider.selectedGroupMembers
            .where((m) => m.userId == template.guestOfHonorId)
            .firstOrNull;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'SECRET EVENT',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.event.title,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Text(
                    'For: ',
                    style: TextStyle(
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    target?.displayName ?? 'Unknown',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (template.decoyTitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_off,
                        size: 14,
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'They see: "${template.decoyTitle}"',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (template.revealAt != null) ...[
                const SizedBox(height: AppSpacing.md),
                _buildCountdown(template.revealAt!, colorScheme),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountdown(DateTime revealAt, ColorScheme colorScheme) {
    final now = DateTime.now();
    final difference = revealAt.difference(now);

    if (difference.isNegative) {
      return Row(
        children: [
          Icon(
            Icons.celebration,
            size: 16,
            color: colorScheme.onPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            'Surprise revealed!',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    String countdownText;
    if (days > 0) {
      countdownText = '$days day${days != 1 ? 's' : ''} until reveal';
    } else if (hours > 0) {
      countdownText = '$hours hour${hours != 1 ? 's' : ''} until reveal';
    } else {
      countdownText = '$minutes minute${minutes != 1 ? 's' : ''} until reveal';
    }

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 16,
          color: colorScheme.onPrimary,
        ),
        const SizedBox(width: 4),
        Text(
          countdownText,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(
    AppColorsExtension appColors,
    ColorScheme colorScheme,
  ) {
    final template = widget.event.surprisePartyTemplate!;
    final totalTasks = template.tasks.length;
    final completedTasks = template.tasks.where((t) => t.isCompleted).length;
    final percentage = template.completionPercentage;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Planning Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: appColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Stats row
          Row(
            children: [
              _buildStatChip(
                icon: Icons.pending_actions,
                label: '$completedTasks of $totalTasks completed',
                color: appColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              if (template.incompleteTasks.isNotEmpty)
                _buildStatChip(
                  icon: Icons.warning_amber_rounded,
                  label: '${template.incompleteTasks.length} remaining',
                  color: Colors.orange,
                ),
            ],
          ),

          // Coordinators info
          const SizedBox(height: AppSpacing.lg),
          _buildCoordinatorsSection(appColors, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatorsSection(
    AppColorsExtension appColors,
    ColorScheme colorScheme,
  ) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, _) {
        final template = widget.event.surprisePartyTemplate!;
        final coordinatorIds = template.inOnItUserIds;

        // Get coordinator profiles
        final coordinators = groupProvider.selectedGroupMembers
            .where((m) => coordinatorIds.contains(m.userId))
            .toList();

        if (coordinators.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IN ON IT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: appColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: coordinators.take(8).map((coordinator) {
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: MemberUtils.getColorById(coordinator.userId),
                  child: Text(
                    MemberUtils.getInitials(coordinator.displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (coordinators.length > 8)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${coordinators.length - 8} more',
                  style: TextStyle(
                    fontSize: 11,
                    color: appColors.textSecondary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskSheet(event: widget.event),
    );
  }

  Widget _buildRSVPSection(
    BuildContext context,
    AppColorsExtension appColors,
    ColorScheme colorScheme,
  ) {
    // CRITICAL: Block guest of honor at UI level (defense in depth)
    final template = widget.event.surprisePartyTemplate;
    final currentUserId = SupabaseClientManager.currentUserId;
    if (template?.guestOfHonorId == currentUserId) {
      return const SizedBox.shrink(); // Hide entire section
    }

    // CRITICAL: Only event creator can view
    if (widget.event.userId != currentUserId) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: appColors.textDisabled),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: appColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initialize(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Calculate counts inline (no RSVPStats model)
    final going = _invitations.where((i) => i['rsvp_status'] == 'accepted').length;
    final maybe = _invitations.where((i) => i['rsvp_status'] == 'maybe').length;
    final declined = _invitations.where((i) => i['rsvp_status'] == 'declined').length;
    final pending = _invitations.where((i) => i['rsvp_status'] == 'pending').length;
    final total = _invitations.length;
    final responded = going + maybe + declined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aggregate counts
        Text(
          'WHO\'S COMING',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: appColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Card(
          color: appColors.cardBackground,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$responded/$total Responded',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                CircularProgressIndicator(
                  value: total > 0 ? responded / total : 0,
                  backgroundColor: appColors.divider,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Status groups
        if (going > 0)
          _buildStatusGroup(
            context,
            'Going',
            _invitations.where((i) => i['rsvp_status'] == 'accepted').toList(),
            Icons.check_circle,
            appColors.success,
          ),
        if (maybe > 0)
          _buildStatusGroup(
            context,
            'Maybe',
            _invitations.where((i) => i['rsvp_status'] == 'maybe').toList(),
            Icons.help_outline,
            appColors.warning,
          ),
        if (declined > 0)
          _buildStatusGroup(
            context,
            'Can\'t Go',
            _invitations.where((i) => i['rsvp_status'] == 'declined').toList(),
            Icons.cancel,
            colorScheme.error,
          ),
        if (pending > 0)
          _buildStatusGroup(
            context,
            'Pending',
            _invitations.where((i) => i['rsvp_status'] == 'pending').toList(),
            Icons.schedule,
            appColors.textDisabled,
          ),
      ],
    );
  }

  Widget _buildStatusGroup(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> invitations,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$title (${invitations.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Lazy loading with ListView.builder (handles 100+ members)
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              final user = invitation['users'] as Map<String, dynamic>?;

              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _buildMemberAvatar(
                  context: context,
                  userId: invitation['user_id'],
                  displayName: user?['full_name'] ?? 'Unknown',
                  avatarUrl: user?['avatar_url'],
                  status: invitation['rsvp_status'],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildMemberAvatar({
    required BuildContext context,
    required String userId,
    required String displayName,
    String? avatarUrl,
    required String status,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: MemberUtils.getColorById(userId), // Reuse utility
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
                  MemberUtils.getInitials(displayName), // Reuse utility
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),

        // Status badge overlay
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: _getStatusColor(context, status),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              _getStatusIcon(status),
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    final appColors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'accepted':
        return appColors.success;
      case 'maybe':
        return appColors.warning;
      case 'declined':
        return colorScheme.error;
      case 'pending':
      default:
        return appColors.textDisabled;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check;
      case 'maybe':
        return Icons.question_mark;
      case 'declined':
        return Icons.close;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }
}

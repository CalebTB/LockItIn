import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

/// Floating action button for creating group events
/// Shows a bottom sheet with two options: Quick Event or Proposal
class ProposeFAB extends StatelessWidget {
  final String groupName;
  final VoidCallback onCreateEvent;     // Quick Event (no voting)
  final VoidCallback onProposeTimes;    // Proposal (voting flow)

  const ProposeFAB({
    super.key,
    required this.groupName,
    required this.onCreateEvent,
    required this.onProposeTimes,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Create a new event for $groupName',
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showEventTypeSheet(context);
        },
        tooltip: 'Create a new event',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'New Event',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Show bottom sheet with event creation options
  void _showEventTypeSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Event',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose how to create your event',
                      style: TextStyle(
                        fontSize: 14,
                        color: appColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Quick Event option
              _buildOption(
                context: context,
                icon: Icons.event_rounded,
                title: 'Create Event',
                description: 'Pick a time and invite members',
                color: const Color(0xFF10B981), // Emerald
                onTap: () {
                  Navigator.of(context).pop();
                  onCreateEvent();
                },
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),

              // Proposal option
              _buildOption(
                context: context,
                icon: Icons.how_to_vote_rounded,
                title: 'Propose Times',
                description: 'Let members vote on best time',
                color: colorScheme.primary,
                onTap: () {
                  Navigator.of(context).pop();
                  onProposeTimes();
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// Build option tile
  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: appColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: appColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/timezone_utils.dart';

/// Contextual empty state variants
enum EmptyStateType {
  /// New user, no events ever created
  noEventsNewUser,

  /// Returning user, no events this week
  noEventsThisWeek,

  /// No events on a specific selected day
  nothingOnDay,

  /// All caught up - no upcoming events
  allCaughtUp,

  /// Generic empty state for groups
  noGroups,

  /// No friends yet
  noFriends,

  /// No notifications in inbox
  inboxEmpty,

  /// No proposals in group
  noProposals,
}

/// Contextual empty state widget with icons, messages, and CTAs
/// Follows iOS Human Interface Guidelines for empty states:
/// - 80pt icon, 18pt semibold title, 15pt body
/// - Clear call-to-action buttons
class EmptyState extends StatelessWidget {
  final EmptyStateType type;
  final DateTime? selectedDate;
  final VoidCallback? onCreateEvent;
  final VoidCallback? onImportCalendar;
  final VoidCallback? onViewGroups;
  final VoidCallback? onViewInbox;
  final VoidCallback? onCreateGroup;
  final VoidCallback? onAddFriend;
  final VoidCallback? onCreateProposal;

  const EmptyState({
    super.key,
    required this.type,
    this.selectedDate,
    this.onCreateEvent,
    this.onImportCalendar,
    this.onViewGroups,
    this.onViewInbox,
    this.onCreateGroup,
    this.onAddFriend,
    this.onCreateProposal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final content = _getContent(context, appColors);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              content.icon,
              size: 80,
              color: content.iconColor ?? appColors.textDisabled,
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              content.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            // Body text
            if (content.body != null) ...[
              const SizedBox(height: 8),
              Text(
                content.body!,
                style: TextStyle(
                  fontSize: 15,
                  color: appColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // CTAs
            if (content.primaryCTA != null || content.secondaryCTA != null) ...[
              const SizedBox(height: 32),
              _buildCTAs(context, colorScheme, appColors, content),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCTAs(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
    _EmptyStateContent content,
  ) {
    return Column(
      children: [
        // Primary CTA (full width)
        if (content.primaryCTA != null)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: content.primaryCTA!.onPressed,
              icon: Icon(content.primaryCTA!.icon),
              label: Text(content.primaryCTA!.label),
            ),
          ),

        // Secondary CTA
        if (content.secondaryCTA != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: content.secondaryCTA!.onPressed,
              icon: Icon(content.secondaryCTA!.icon),
              label: Text(content.secondaryCTA!.label),
            ),
          ),
        ],
      ],
    );
  }

  _EmptyStateContent _getContent(BuildContext context, AppColorsExtension appColors) {
    switch (type) {
      case EmptyStateType.noEventsNewUser:
        return _EmptyStateContent(
          icon: Icons.calendar_today_outlined,
          title: 'No events scheduled yet',
          body: 'Create your first event to get started',
          primaryCTA: onCreateEvent != null
              ? _CTAButton(
                  label: 'Create Event',
                  icon: Icons.add_rounded,
                  onPressed: onCreateEvent!,
                )
              : null,
          secondaryCTA: onImportCalendar != null
              ? _CTAButton(
                  label: 'Import from Calendar',
                  icon: Icons.download_rounded,
                  onPressed: onImportCalendar!,
                )
              : null,
        );

      case EmptyStateType.noEventsThisWeek:
        return _EmptyStateContent(
          icon: Icons.event_available_outlined,
          title: 'Nothing scheduled this week',
          body: 'Time to plan something with your groups?',
          primaryCTA: onCreateEvent != null
              ? _CTAButton(
                  label: 'Create Event',
                  icon: Icons.add_rounded,
                  onPressed: onCreateEvent!,
                )
              : null,
          secondaryCTA: onViewGroups != null
              ? _CTAButton(
                  label: 'View Groups',
                  icon: Icons.group_outlined,
                  onPressed: onViewGroups!,
                )
              : null,
        );

      case EmptyStateType.nothingOnDay:
        final dateStr = selectedDate != null
            ? TimezoneUtils.formatLocal(selectedDate!, 'MMMM d')
            : 'this day';
        return _EmptyStateContent(
          icon: Icons.event_outlined,
          title: 'Nothing on $dateStr',
          body: null,
          primaryCTA: onCreateEvent != null
              ? _CTAButton(
                  label: 'Create Event',
                  icon: Icons.add_rounded,
                  onPressed: onCreateEvent!,
                )
              : null,
        );

      case EmptyStateType.allCaughtUp:
        return _EmptyStateContent(
          icon: Icons.check_circle_outline_rounded,
          iconColor: appColors.success,
          title: 'All caught up!',
          body: 'No upcoming events',
          primaryCTA: onCreateEvent != null
              ? _CTAButton(
                  label: 'Create Event',
                  icon: Icons.add_rounded,
                  onPressed: onCreateEvent!,
                )
              : null,
          secondaryCTA: onViewInbox != null
              ? _CTAButton(
                  label: 'View Inbox',
                  icon: Icons.inbox_outlined,
                  onPressed: onViewInbox!,
                )
              : null,
        );

      case EmptyStateType.noGroups:
        return _EmptyStateContent(
          icon: Icons.group_add_outlined,
          title: 'No groups yet',
          body: 'Create a group to start coordinating events with friends',
          primaryCTA: onCreateGroup != null
              ? _CTAButton(
                  label: 'Create Group',
                  icon: Icons.add_rounded,
                  onPressed: onCreateGroup!,
                )
              : null,
        );

      case EmptyStateType.noFriends:
        return _EmptyStateContent(
          icon: Icons.person_add_outlined,
          title: 'No friends added yet',
          body: 'Add friends to create groups and share calendars',
          primaryCTA: onAddFriend != null
              ? _CTAButton(
                  label: 'Add Friend',
                  icon: Icons.person_add_rounded,
                  onPressed: onAddFriend!,
                )
              : null,
        );

      case EmptyStateType.inboxEmpty:
        return _EmptyStateContent(
          icon: Icons.check_circle_outline_rounded,
          iconColor: appColors.success,
          title: 'All caught up!',
          body: 'No pending requests or invites',
        );

      case EmptyStateType.noProposals:
        return _EmptyStateContent(
          icon: Icons.how_to_vote_outlined,
          title: 'No proposals yet',
          body: 'Create a proposal to suggest event times to the group',
          primaryCTA: onCreateProposal != null
              ? _CTAButton(
                  label: 'Create Proposal',
                  icon: Icons.add_rounded,
                  onPressed: onCreateProposal!,
                )
              : null,
        );
    }
  }
}

/// Internal helper class for empty state content
class _EmptyStateContent {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? body;
  final _CTAButton? primaryCTA;
  final _CTAButton? secondaryCTA;

  const _EmptyStateContent({
    required this.icon,
    this.iconColor,
    required this.title,
    this.body,
    this.primaryCTA,
    this.secondaryCTA,
  });
}

/// Internal helper class for CTA buttons
class _CTAButton {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _CTAButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

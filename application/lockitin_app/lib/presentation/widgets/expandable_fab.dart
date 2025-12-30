import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';

/// Expandable floating action button with animated menu options
/// Opens to reveal Groups, Friends, and New Event actions
/// Uses theme-based colors from the Minimal theme design system
class ExpandableFab extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onGroupsPressed;
  final VoidCallback onFriendsPressed;
  final VoidCallback onNewEventPressed;
  final int pendingFriendRequests;

  const ExpandableFab({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.onGroupsPressed,
    required this.onFriendsPressed,
    required this.onNewEventPressed,
    this.pendingFriendRequests = 0,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(ExpandableFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return SizedBox(
      width: 200, // Wide enough for labels + buttons
      height: 220,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // New Event Button (top) - Secondary color (orange)
          _buildExpandingAction(
            context: context,
            index: 2,
            icon: Icons.calendar_today_rounded,
            label: 'New Event',
            color: colorScheme.secondary,
            onTap: widget.onNewEventPressed,
          ),

          // Friends Button (middle) - Primary color (rose)
          _buildExpandingAction(
            context: context,
            index: 1,
            icon: Icons.person_add_rounded,
            label: 'Friends',
            color: colorScheme.primary,
            onTap: widget.onFriendsPressed,
            badgeCount: widget.pendingFriendRequests,
          ),

          // Groups Button (bottom of expanded menu) - Violet
          _buildExpandingAction(
            context: context,
            index: 0,
            icon: Icons.group_rounded,
            label: 'Groups',
            color: AppColors.memberViolet,
            onTap: widget.onGroupsPressed,
          ),

          // Main FAB
          _buildMainFab(context, colorScheme, appColors),
        ],
      ),
    );
  }

  Widget _buildExpandingAction({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final double distance = 56.0 * (index + 1);

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final progress = _expandAnimation.value;
        return Positioned(
          right: 4, // Keep buttons aligned to the right
          bottom: 12 + (distance * progress),
          child: Opacity(
            opacity: progress,
            child: Transform.scale(
              scale: 0.5 + (0.5 * progress),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label (appears on hover/press in web, always visible on mobile)
                  if (progress > 0.5)
                    Opacity(
                      opacity: (progress - 0.5) * 2,
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: appColors.cardBackground,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: appColors.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  // Button with optional badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.isOpen ? onTap : null,
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      // Badge
                      if (badgeCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                badgeCount > 99 ? '99+' : badgeCount.toString(),
                                style: TextStyle(
                                  color: colorScheme.onError,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainFab(BuildContext context, ColorScheme colorScheme, AppColorsExtension appColors) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final isOpen = _expandAnimation.value > 0.5;
        final showBadge = !isOpen && widget.pendingFriendRequests > 0;
        return Positioned(
          right: 0,
          bottom: 0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onToggle,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isOpen
                          ? colorScheme.surfaceContainerHigh
                          : colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isOpen
                              ? colorScheme.surfaceContainerHigh
                              : colorScheme.primary).withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: _expandAnimation.value * math.pi / 4,
                      child: Icon(
                        Icons.add_rounded,
                        color: isOpen
                            ? colorScheme.onSurface
                            : colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              // Badge on main FAB when closed
              if (showBadge)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.pendingFriendRequests > 99
                            ? '99+'
                            : widget.pendingFriendRequests.toString(),
                        style: TextStyle(
                          color: colorScheme.onError,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

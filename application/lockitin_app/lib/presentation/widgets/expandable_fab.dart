import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Expandable floating action button with animated menu options
/// Opens to reveal Groups, Friends, and New Event actions
class ExpandableFab extends StatefulWidget {
  // Sunset Coral Dark Theme Colors
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose400 = Color(0xFFFB7185);
  static const Color _rose800 = Color(0xFF9F1239);
  static const Color _rose900 = Color(0xFF881337);
  static const Color _rose950 = Color(0xFF4C0519);
  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _orange500 = Color(0xFFF97316);
  static const Color _orange600 = Color(0xFFEA580C);
  static const Color _amber400 = Color(0xFFFBBF24);
  static const Color _pink500 = Color(0xFFEC4899);
  static const Color _violet400 = Color(0xFFA78BFA);
  static const Color _purple500 = Color(0xFFA855F7);
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onGroupsPressed;
  final VoidCallback onFriendsPressed;
  final VoidCallback onNewEventPressed;

  const ExpandableFab({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.onGroupsPressed,
    required this.onFriendsPressed,
    required this.onNewEventPressed,
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
    return SizedBox(
      width: 200, // Wide enough for labels + buttons
      height: 220,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // New Event Button (top) - Amber to Orange
          _buildExpandingAction(
            index: 2,
            icon: Icons.calendar_today_rounded,
            label: 'New Event',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ExpandableFab._amber400, ExpandableFab._orange600],
            ),
            shadowColor: ExpandableFab._orange500,
            onTap: widget.onNewEventPressed,
          ),

          // Friends Button (middle) - Rose to Pink
          _buildExpandingAction(
            index: 1,
            icon: Icons.person_add_rounded,
            label: 'Friends',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ExpandableFab._rose400, ExpandableFab._pink500],
            ),
            shadowColor: ExpandableFab._pink500,
            onTap: widget.onFriendsPressed,
          ),

          // Groups Button (bottom of expanded menu) - Violet to Purple
          _buildExpandingAction(
            index: 0,
            icon: Icons.group_rounded,
            label: 'Groups',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ExpandableFab._violet400, ExpandableFab._purple500],
            ),
            shadowColor: ExpandableFab._purple500,
            onTap: widget.onGroupsPressed,
          ),

          // Main FAB
          _buildMainFab(),
        ],
      ),
    );
  }

  Widget _buildExpandingAction({
    required int index,
    required IconData icon,
    required String label,
    required Gradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
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
                          color: ExpandableFab._rose950.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: ExpandableFab._rose500.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: ExpandableFab._rose50,
                          ),
                        ),
                      ),
                    ),
                  // Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.isOpen ? onTap : null,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor.withValues(alpha: 0.4),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainFab() {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final isOpen = _expandAnimation.value > 0.5;
        return Positioned(
          right: 0,
          bottom: 0,
          child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isOpen
                      ? [ExpandableFab._rose800, ExpandableFab._rose900]
                      : [ExpandableFab._rose500, ExpandableFab._orange500],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isOpen ? ExpandableFab._rose800 : ExpandableFab._rose500)
                        .withValues(alpha: 0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: _expandAnimation.value * math.pi / 4,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        );
      },
    );
  }
}

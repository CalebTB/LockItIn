import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Expandable floating action button with animated menu options
/// Opens to reveal Groups, Friends, and New Event actions
class ExpandableFab extends StatefulWidget {
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
          // New Event Button (top)
          _buildExpandingAction(
            index: 2,
            icon: Icons.calendar_today_rounded,
            label: 'New Event',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4ADE80), Color(0xFF10B981)], // green-400 to emerald-500
            ),
            shadowColor: const Color(0xFF10B981),
            onTap: widget.onNewEventPressed,
          ),

          // Friends Button (middle)
          _buildExpandingAction(
            index: 1,
            icon: Icons.person_add_rounded,
            label: 'Friends',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF60A5FA), Color(0xFF2563EB)], // blue-400 to blue-600
            ),
            shadowColor: const Color(0xFF2563EB),
            onTap: widget.onFriendsPressed,
          ),

          // Groups Button (bottom of expanded menu)
          _buildExpandingAction(
            index: 0,
            icon: Icons.group_rounded,
            label: 'Groups',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)], // purple-400 to purple-600
            ),
            shadowColor: const Color(0xFF7C3AED),
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
    final double distance = 52.0 * (index + 1);

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final progress = _expandAnimation.value;
        return Positioned(
          right: 4, // Keep buttons aligned to the right
          bottom: 4 + (distance * progress),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151), // gray-700
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
                      ? [const Color(0xFF4B5563), const Color(0xFF374151)] // gray-600 to gray-700
                      : [const Color(0xFF3B82F6), const Color(0xFF2563EB)], // blue-500 to blue-600
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isOpen ? const Color(0xFF4B5563) : const Color(0xFF3B82F6))
                        .withValues(alpha: 0.4),
                    blurRadius: 12,
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
